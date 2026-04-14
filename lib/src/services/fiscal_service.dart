// Сервис фискализации - абстракция FiscalProvider + реализация HTTP ККМ
// ККМ: http://77.220.204.134:9995
// Команда: POST /fiscal/bills/openAndCloseRec
// Заголовок: RNM = "0000000000023458"
// Документация: https://documenter.getpostman.com/view/8816590/UzXLyxTd

import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/order.dart';
import '../utils/sdk_logger.dart';

// Результат фискализации
class FiscalResult {
  final bool success;
  final String? receiptNumber;
  final String? fiscalSign;
  final String? error;

  FiscalResult({
    required this.success,
    this.receiptNumber,
    this.fiscalSign,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'success': success,
        'receipt_number': receiptNumber,
        'fiscal_sign': fiscalSign,
      };
}

// Абстрактный интерфейс фискального провайдера (для SDK-интеграции)
abstract class FiscalProvider {
  Future<bool> isAvailable();
  Future<FiscalResult> printReceipt({
    required Order order,
    required String paymentType,
  });
}

// Конфигурация ККМ
class KkmConfig {
  final String baseUrl; // http://77.220.204.134:9995
  final String rnm; // РНМ: 0000000000023458
  final String fmNumber; // Номер фискальной памяти
  final double vatRate; // Ставка НДС, %
  final double stRate; // Ставка НсП, %

  KkmConfig({
    required this.baseUrl,
    this.rnm = '0000000000023458',
    this.fmNumber = '0000000002432961',
    this.vatRate = 0.0,
    this.stRate = 0.0,
  });
}

// Реализация через HTTP API ККМ (реальный протокол)
class HttpFiscalProvider implements FiscalProvider {
  final KkmConfig config;
  late final Dio _dio;

  HttpFiscalProvider({required this.config}) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'RNM': config.rnm,
      },
    ));
  }

  @override
  Future<bool> isAvailable() async {
    return config.baseUrl.isNotEmpty;
  }

  @override
  Future<FiscalResult> printReceipt({
    required Order order,
    required String paymentType,
  }) async {
    SdkLogger.info(
      'ККМ: пробитие чека #${order.invoiceNumber}, '
      'сумма ${order.invoiceSum}, тип $paymentType',
    );

    try {
      // Формируем товары в формате ККМ
      // НДС берётся из конфига (применяется ко всем позициям, по решению с клиентом)
      final goods = order.items.map((item) => {
            'count': item.quantity,
            'price': item.price,
            'itemName': item.name,
            'calcType': 0, // 0 = полная оплата
            'article': item.article ?? '',
            'unit': item.unit ?? 'шт.',
            'stRate': config.stRate,
            'vatRate': config.vatRate,
          }).toList();

      // Определяем тип оплаты
      // 0 = наличные, 1 = карта, 2 = электронные (QR)
      int payTypeCode;
      String payTitle;
      switch (paymentType) {
        case 'qr':
          payTypeCode = 2;
          payTitle = 'QR';
          break;
        case 'card':
          payTypeCode = 1;
          payTitle = 'Card';
          break;
        default:
          payTypeCode = 0;
          payTitle = 'Cash';
      }

      final requestBody = {
        'fmNumber': config.fmNumber,
        'recType': 1, // 1 = продажа
        'goods': goods,
        'payItems': [
          {
            'total': order.invoiceSum,
            'payType': payTypeCode,
            'title': payTitle,
          }
        ],
      };

      final endpoint = '${config.baseUrl}/fiscal/bills/openAndCloseRec';
      SdkLogger.debug('ККМ запрос: $requestBody');

      final response = await _dio.post(endpoint, data: requestBody);

      final data = response.data;
      SdkLogger.info('ККМ ответ: $data');

      // Парсим ответ
      if (data is Map<String, dynamic>) {
        // status != 0 означает ошибку ККМ
        final kkmStatus = data['status'];
        if (kkmStatus != null && kkmStatus != 0) {
          final errorMsg = data['errorMessage']?.toString() ?? 'Ошибка ККМ (status: $kkmStatus)';
          return FiscalResult(success: false, error: errorMsg);
        }

        return FiscalResult(
          success: true,
          receiptNumber: data['receiptNumber']?.toString() ??
              data['receipt_number']?.toString(),
          fiscalSign: data['fiscalSign']?.toString() ??
              data['fiscal_sign']?.toString(),
        );
      }

      return FiscalResult(
        success: true,
        receiptNumber: 'OK',
      );
    } on DioException catch (e) {
      final error = _handleError(e);
      SdkLogger.error('ККМ: ошибка - $error');

      return FiscalResult(success: false, error: error);
    } catch (e) {
      SdkLogger.error('ККМ: неизвестная ошибка - $e');
      return FiscalResult(success: false, error: 'Ошибка ККМ: $e');
    }
  }

  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'ККМ не отвечает. Проверьте подключение.';
      case DioExceptionType.connectionError:
        return 'Нет связи с ККМ. Проверьте IP-адрес и порт.';
      case DioExceptionType.badResponse:
        return 'Ошибка ККМ (${e.response?.statusCode}): ${e.response?.data}';
      default:
        return 'Ошибка связи с ККМ: ${e.message}';
    }
  }
}

// Демо-провайдер фискализации (для тестирования без ККМ)
class DemoFiscalProvider implements FiscalProvider {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<FiscalResult> printReceipt({
    required Order order,
    required String paymentType,
  }) async {
    SdkLogger.info('Демо ККМ: чек #${order.invoiceNumber}');
    return FiscalResult(
      success: true,
      receiptNumber: 'DEMO-${DateTime.now().millisecondsSinceEpoch}',
      fiscalSign: 'DEMO-FS',
    );
  }
}
