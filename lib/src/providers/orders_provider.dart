// Провайдер состояния заявок - основной стейт-менеджмент

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../order_selling_sdk.dart';

class OrdersProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  int _currentOrderIndex = 0;
  OrdersApi? _api;
  AppConfig? _appConfig;

  // Фильтр периода заявок (по умолчанию - текущий месяц)
  DateTime _dateFrom = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _dateTo = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentOrderIndex => _currentOrderIndex;
  OrdersApi? get api => _api;
  String? get kkmUrl => _appConfig?.kkmUrl;
  DateTime get dateFrom => _dateFrom;
  DateTime get dateTo => _dateTo;

  // Установить новый период (без автозагрузки - загрузка по кнопке "Обновить")
  void setPeriod(DateTime from, DateTime to) {
    _dateFrom = DateTime(from.year, from.month, from.day);
    _dateTo = DateTime(to.year, to.month, to.day);
    notifyListeners();
  }

  Order? get currentOrder =>
      _orders.isNotEmpty && _currentOrderIndex < _orders.length
          ? _orders[_currentOrderIndex]
          : null;

  int get pendingCount =>
      _orders.where((o) => o.status == OrderStatus.pending ||
          o.status == OrderStatus.inProgress).length;

  // Инициализация с конфигурацией
  void init(AppConfig config) {
    _api = OrdersApi(config: config);
    _appConfig = config;

    // Настраиваем ККМ
    final kkmUrl = config.kkmUrl ?? '';
    SdkLogger.info('ККМ URL из конфига: "$kkmUrl"');
    OrderSellingSDK.setFiscalProvider(HttpFiscalProvider(
      config: KkmConfig(
        baseUrl: kkmUrl,
        rnm: config.kkmRnm,
        fmNumber: config.kkmFmNumber,
        vatRate: config.vatRate,
        stRate: config.stRate,
      ),
    ));
    SdkLogger.info('ККМ настроен: $kkmUrl');

    // Настраиваем GoodooPay
    OrderSellingSDK.setPaymentProvider(GoodooPayProvider(
      config: GoodooPayConfig(
        ls: config.bankAccount.isNotEmpty ? config.bankAccount : '112197',
        bank: config.bankName.isNotEmpty ? config.bankName : 'О! банк',
        qrEnabled: config.payQrEnabled,
        bankEnabled: config.payBankEnabled,
      ),
    ));

    SdkLogger.info('Провайдер инициализирован');
  }

  static const _statusStorageKey = 'expediflow_order_statuses';

  // Сохранить статусы заявок в SharedPreferences
  Future<void> _saveStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, String>{};
    for (final order in _orders) {
      if (order.status != OrderStatus.pending) {
        map[order.id] = order.status.name;
      }
    }
    await prefs.setString(_statusStorageKey, jsonEncode(map));
  }

  // Восстановить статусы заявок из SharedPreferences
  Future<void> _restoreStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statusStorageKey);
    if (raw == null || raw.isEmpty) return;

    final map = (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as String));

    for (final order in _orders) {
      final savedStatus = map[order.id];
      if (savedStatus != null) {
        final status = OrderStatus.values.where((s) => s.name == savedStatus).firstOrNull;
        if (status != null) {
          order.status = status;
        }
      }
    }
  }

  Future<void> fetchOrders() async {
    if (_api == null) {
      _error = 'Не настроено подключение. Проверьте настройки.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Сохраняем текущие статусы перед обновлением
      if (_orders.isNotEmpty) {
        await _saveStatuses();
      }

      _orders = await _api!.fetchOrders(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );
      _currentOrderIndex = 0;

      // Восстанавливаем сохранённые статусы
      await _restoreStatuses();

      SdkLogger.info('Загружено ${_orders.length} заявок за период '
          '${_dateFrom.toIso8601String().substring(0, 10)} - '
          '${_dateTo.toIso8601String().substring(0, 10)}');

      await CallbackQueue.flush(_api!);
    } catch (e) {
      _error = e.toString();
      SdkLogger.error('Ошибка загрузки заявок: $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  void loadMockOrders(List<Order> mockOrders) {
    _orders = mockOrders;
    _currentOrderIndex = 0;
    _error = null;
    notifyListeners();
  }

  void moveToNextOrder() {
    if (_currentOrderIndex < _orders.length - 1) {
      _currentOrderIndex++;
      _orders[_currentOrderIndex].status = OrderStatus.inProgress;
      _saveStatuses();
      notifyListeners();
    }
  }

  void markCurrentAsPaid() {
    if (currentOrder != null) {
      currentOrder!.status = OrderStatus.paid;
      _saveStatuses();
      notifyListeners();
    }
  }

  void markOrderAsPaid(String invoiceNumber) {
    final order = _orders.where((o) => o.invoiceNumber == invoiceNumber).firstOrNull;
    if (order != null) {
      order.status = OrderStatus.paid;
      _saveStatuses();
      notifyListeners();
    }
  }

  void markCurrentAsDelivered() {
    if (currentOrder != null) {
      currentOrder!.status = OrderStatus.delivered;
      _saveStatuses();
      notifyListeners();
    }
  }

  void startMovingToCurrent() {
    if (currentOrder != null) {
      currentOrder!.status = OrderStatus.inProgress;
      _saveStatuses();
      notifyListeners();
    }
  }

  Order? getOrderAt(int index) {
    if (index >= 0 && index < _orders.length) {
      return _orders[index];
    }
    return null;
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _orders.length) {
      _currentOrderIndex = index;
      notifyListeners();
    }
  }
}
