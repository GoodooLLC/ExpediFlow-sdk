// Точка входа SDK - публичный API модуля Order Selling
// Использование:
//   OrderSellingSDK.init(config);
//   OrderSellingSDK.launch(context);

// Реэкспорт всех публичных классов
export 'models/order.dart';
export 'models/app_config.dart';
export 'models/review_data.dart';
export 'services/orders_api.dart';
export 'services/config_service.dart';
export 'services/navigation_service.dart';
export 'services/mock_service.dart';
export 'services/payment_service.dart';
export 'services/fiscal_service.dart';
export 'services/callback_queue.dart';
export 'services/route_service.dart';
export 'providers/orders_provider.dart';
export 'screens/home_screen.dart';
export 'screens/settings/settings_screen.dart';
export 'screens/orders/orders_screen.dart';
export 'screens/order_detail/order_detail_screen.dart';
export 'screens/route_map/route_map_screen.dart';
export 'screens/review/review_screen.dart';
export 'utils/app_theme.dart';
export 'utils/formatters.dart';
export 'utils/sdk_logger.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_config.dart';
import 'providers/orders_provider.dart';
import 'services/payment_service.dart';
import 'services/fiscal_service.dart';
import 'utils/app_theme.dart';
import 'utils/sdk_logger.dart';
import 'screens/home_screen.dart';

// Конфигурация SDK
class SdkConfig {
  final AppConfig appConfig;
  final PaymentProvider? paymentProvider;
  final FiscalProvider? fiscalProvider;
  final LogLevel logLevel;

  SdkConfig({
    required this.appConfig,
    this.paymentProvider,
    this.fiscalProvider,
    this.logLevel = LogLevel.info,
  });
}

// Публичный API SDK
class OrderSellingSDK {
  static SdkConfig? _config;
  static PaymentProvider? _paymentProvider;
  static FiscalProvider? _fiscalProvider;

  // Инициализация SDK с конфигурацией
  static void init(SdkConfig config) {
    _config = config;
    _paymentProvider = config.paymentProvider;
    _fiscalProvider = config.fiscalProvider;
    SdkLogger.setMinLevel(config.logLevel);
    SdkLogger.info('SDK инициализирован');
  }

  // Получить текущий PaymentProvider
  static PaymentProvider? get paymentProvider => _paymentProvider;

  // Получить текущий FiscalProvider
  static FiscalProvider? get fiscalProvider => _fiscalProvider;

  // Получить конфигурацию
  static SdkConfig? get config => _config;

  // Установить кастомный PaymentProvider
  static void setPaymentProvider(PaymentProvider provider) {
    _paymentProvider = provider;
    SdkLogger.info('SDK: установлен кастомный PaymentProvider');
  }

  // Установить кастомный FiscalProvider
  static void setFiscalProvider(FiscalProvider provider) {
    _fiscalProvider = provider;
    SdkLogger.info('SDK: установлен кастомный FiscalProvider');
  }

  // Запустить UI модуля (для интеграции в хост-приложение)
  static Widget buildWidget() {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = OrdersProvider();
        if (_config != null) {
          provider.init(_config!.appConfig);
        }
        return provider;
      },
      child: MaterialApp(
        title: 'ExpediFlow',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }

  // Запустить как отдельный экран (push)
  static void launch(BuildContext context) {
    SdkLogger.info('SDK: запуск UI');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) {
            final provider = OrdersProvider();
            if (_config != null) {
              provider.init(_config!.appConfig);
            }
            return provider;
          },
          child: const HomeScreen(),
        ),
      ),
    );
  }

  // Подписка на логи SDK
  static void setLogListener(void Function(LogEntry entry) listener) {
    SdkLogger.onLog = listener;
  }
}
