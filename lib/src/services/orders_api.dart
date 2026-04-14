// HTTP-клиент для работы с API заявок
// Сервер 1С: POST https://test1c.goodoo.kg/Goodoo/hs/OrderSelling/GetOrders
// Auth: Basic goodoo / rjvfylf ghjatccbjyfkjd

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../models/app_config.dart';
import '../models/order.dart';
import '../utils/sdk_logger.dart';

class OrdersApi {
  late final Dio _dio;
  final AppConfig config;

  OrdersApi({required this.config}) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${config.login}:${config.password}'))}',
        'Content-Type': 'application/json',
      },
    ));
  }

  // Загрузить список заявок (POST с date1, date2, Van).
  // Если даты не переданы - используется широкий диапазон (-1 год / +1 год
  // от сегодня) как дефолт, чтобы захватить все актуальные заявки.
  // UI должен передавать конкретный период, выбранный пользователем.
  Future<List<Order>> fetchOrders({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      // Формат дат: YYYYMMDD
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyyMMdd');
      final from = dateFrom ?? DateTime(now.year - 1, 1, 1);
      final to = dateTo ?? DateTime(now.year + 1, 12, 31);
      final date1 = dateFormat.format(from);
      final date2 = dateFormat.format(to);

      final body = {
        'date1': date1,
        'date2': date2,
        'Van': config.driverId,
      };

      SdkLogger.info('API: POST ${config.ordersUrl} body=$body');

      final response = await _dio.post(
        config.ordersUrl,
        data: body,
      );

      SdkLogger.debug('API ответ: ${response.data}');

      return _parseOrders(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Гибкий парсинг ответа (формат 1С может отличаться)
  List<Order> _parseOrders(dynamic data) {
    List<dynamic> ordersList;

    if (data is List) {
      // Ответ - сразу массив
      ordersList = data;
    } else if (data is Map<String, dynamic>) {
      // Ответ - объект с ключом orders/Orders/data
      ordersList = (data['orders'] ?? data['Orders'] ??
          data['data'] ?? data['Data'] ?? []) as List;
    } else {
      SdkLogger.warning('API: неизвестный формат ответа: ${data.runtimeType}');
      return [];
    }

    SdkLogger.info('API: получено ${ordersList.length} заявок');

    return ordersList
        .map((json) {
          try {
            return Order.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            SdkLogger.warning('API: ошибка парсинга заявки: $e');
            return null;
          }
        })
        .where((o) => o != null)
        .cast<Order>()
        .toList();
  }

  // Отправить callback результата доставки/оплаты в 1С.
  // Формат подтверждён клиентом:
  // POST .../OrderSelling/CallBackAnswer
  // {"n": "00УД-003229", "statusPay": "оплачено", "ststusDoc": "доставлен", "otzyv": "текст"}
  // Примечание: "ststusDoc" — опечатка в 1С, но сохраняем как есть (так ожидает сервер).
  Future<void> sendCallback({
    required String orderNumber,
    required String statusPay,
    required String statusDoc,
    String? review,
  }) async {
    try {
      SdkLogger.info('Callback: $statusPay / $statusDoc для заявки $orderNumber');

      await _dio.post(
        config.callbackUrl,
        data: {
          'n': orderNumber,
          'statusPay': statusPay,
          'ststusDoc': statusDoc, // опечатка в 1С, сохраняем как есть
          if (review != null && review.isNotEmpty) 'otzyv': review,
        },
      );

      SdkLogger.info('Callback: отправлен успешно');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Превышено время ожидания. Проверьте подключение к сети.';
      case DioExceptionType.connectionError:
        return 'Нет подключения к серверу. Проверьте URL и сеть.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return 'Ошибка авторизации. Проверьте логин и пароль.';
        }
        if (statusCode == 502 || statusCode == 504) {
          return 'Сервер 1С не отвечает (код $statusCode). Попробуйте позже.';
        }
        return 'Ошибка сервера ($statusCode): ${e.response?.data}';
      default:
        return 'Ошибка запроса: ${e.message}';
    }
  }
}
