// Офлайн-очередь callback - сохраняет callback при отсутствии сети
// и отправляет при восстановлении подключения

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'orders_api.dart';

// Данные callback в формате 1С:
// {"n": "00УД-003229", "statusPay": "оплачено", "ststusDoc": "доставлен", "otzyv": "текст"}
class CallbackData {
  final String orderNumber; // n (номер накладной)
  final String statusPay; // statusPay: "оплачено" / "не оплачено"
  final String statusDoc; // ststusDoc: "доставлен" / "не доставлен"
  final String? review; // otzyv: текстовый отзыв
  final DateTime timestamp;

  CallbackData({
    required this.orderNumber,
    required this.statusPay,
    required this.statusDoc,
    this.review,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'order_number': orderNumber,
        'status_pay': statusPay,
        'status_doc': statusDoc,
        'review': review,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CallbackData.fromJson(Map<String, dynamic> json) {
    return CallbackData(
      orderNumber: json['order_number'] as String,
      statusPay: json['status_pay'] as String,
      statusDoc: json['status_doc'] as String,
      review: json['review'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class CallbackQueue {
  static const _storageKey = 'newcas_callback_queue';

  // Добавить callback в очередь
  static Future<void> enqueue(CallbackData data) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = _loadQueue(prefs);
    queue.add(data.toJson());
    await prefs.setString(_storageKey, jsonEncode(queue));
  }

  // Попытаться отправить все из очереди
  static Future<int> flush(OrdersApi api) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = _loadQueue(prefs);

    if (queue.isEmpty) return 0;

    final failed = <Map<String, dynamic>>[];
    var sent = 0;

    for (final item in queue) {
      try {
        final data = CallbackData.fromJson(item);
        await api.sendCallback(
          orderNumber: data.orderNumber,
          statusPay: data.statusPay,
          statusDoc: data.statusDoc,
          review: data.review,
        );
        sent++;
      } catch (_) {
        failed.add(item);
      }
    }

    // Сохраняем только те, что не удалось отправить
    await prefs.setString(_storageKey, jsonEncode(failed));
    return sent;
  }

  // Количество в очереди
  static Future<int> pendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadQueue(prefs).length;
  }

  static List<Map<String, dynamic>> _loadQueue(SharedPreferences prefs) {
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }
}
