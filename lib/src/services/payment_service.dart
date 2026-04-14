// Сервис оплаты - абстракция PaymentProvider + реализация GoodooPay
// GoodooPay Flutter SDK: goodoo_pay ^1.0.0

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:goodoo_pay/goodoo_pay.dart' as gp;
import '../utils/sdk_logger.dart';

// Результат оплаты
enum PaymentResultStatus { success, failed, cancelled }

class PaymentResult {
  final PaymentResultStatus status;
  final String? transactionId;
  final String? error;

  PaymentResult({
    required this.status,
    this.transactionId,
    this.error,
  });

  bool get isSuccess => status == PaymentResultStatus.success;
  bool get isFailed => status == PaymentResultStatus.failed;
  bool get isCancelled => status == PaymentResultStatus.cancelled;
}

// Абстрактный интерфейс платёжного провайдера (для SDK-интеграции)
abstract class PaymentProvider {
  Future<bool> isAvailable();
  Future<PaymentResult> payByQR({
    required double amount,
    required String description,
    required BuildContext context,
  });
  Future<PaymentResult> payByCard({
    required double amount,
    required String description,
    required BuildContext context,
  });
}

// Параметры GoodooPay
class GoodooPayConfig {
  final String ls; // лицевой счёт
  final String bank; // наименование банка
  final String apiKey; // API ключ (если нужен)
  final bool qrEnabled; // метод QR включён
  final bool bankEnabled; // метод банк включён

  GoodooPayConfig({
    this.ls = '112197',
    this.bank = 'О! банк',
    this.apiKey = '',
    this.qrEnabled = true,
    this.bankEnabled = true,
  });

  List<gp.PaymentMethod> get availableMethods {
    final methods = <gp.PaymentMethod>[];
    if (bankEnabled) methods.add(gp.PaymentMethod.bank);
    if (qrEnabled) methods.add(gp.PaymentMethod.qr);
    // Если ничего не выбрано - включаем оба по умолчанию
    if (methods.isEmpty) {
      methods.add(gp.PaymentMethod.bank);
      methods.add(gp.PaymentMethod.qr);
    }
    return methods;
  }
}

// Реализация GoodooPay через Flutter SDK goodoo_pay
class GoodooPayProvider implements PaymentProvider {
  final GoodooPayConfig config;

  GoodooPayProvider({required this.config});

  @override
  Future<bool> isAvailable() async {
    return config.ls.isNotEmpty;
  }

  @override
  Future<PaymentResult> payByQR({
    required double amount,
    required String description,
    required BuildContext context,
  }) async {
    SdkLogger.info('GoodooPay: оплата QR $amount - $description');
    return _startPayment(
      context: context,
      amount: amount,
      description: description,
      methods: config.availableMethods,
    );
  }

  @override
  Future<PaymentResult> payByCard({
    required double amount,
    required String description,
    required BuildContext context,
  }) async {
    SdkLogger.info('GoodooPay: оплата картой $amount - $description');
    return _startPayment(
      context: context,
      amount: amount,
      description: description,
      methods: config.availableMethods,
    );
  }

  Future<PaymentResult> _startPayment({
    required BuildContext context,
    required double amount,
    required String description,
    required List<gp.PaymentMethod> methods,
  }) async {
    final completer = Completer<PaymentResult>();

    try {
      await gp.GoodooPayFlutter.startPayment(
        context: context,
        params: gp.PaymentParams(
          apiKey: config.apiKey,
          ls: config.ls,
          bank: config.bank,
          amount: amount,
          description: description,
          availableMethods: methods,
        ),
        onResult: (result) {
          if (completer.isCompleted) return;
          if (result.status == gp.PaymentStatus.success) {
            completer.complete(PaymentResult(
              status: PaymentResultStatus.success,
              transactionId: result.transactionId,
            ));
          } else if (result.status == gp.PaymentStatus.cancelled) {
            completer.complete(PaymentResult(
              status: PaymentResultStatus.cancelled,
            ));
          } else {
            completer.complete(PaymentResult(
              status: PaymentResultStatus.failed,
              error: result.errorMessage ?? 'Ошибка оплаты',
            ));
          }
        },
      );

      // Если startPayment вернулся без вызова onResult (пользователь нажал назад)
      if (!completer.isCompleted) {
        completer.complete(PaymentResult(
          status: PaymentResultStatus.cancelled,
        ));
      }
    } catch (e) {
      SdkLogger.error('GoodooPay: исключение - $e');
      if (!completer.isCompleted) {
        completer.complete(PaymentResult(
          status: PaymentResultStatus.failed,
          error: 'Ошибка GoodooPay: $e',
        ));
      }
    }

    return completer.future;
  }
}

// Демо-провайдер (для тестирования без SDK)
class DemoPaymentProvider implements PaymentProvider {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PaymentResult> payByQR({
    required double amount,
    required String description,
    required BuildContext context,
  }) async {
    SdkLogger.info('Демо: оплата QR $amount сом');
    return PaymentResult(status: PaymentResultStatus.success);
  }

  @override
  Future<PaymentResult> payByCard({
    required double amount,
    required String description,
    required BuildContext context,
  }) async {
    SdkLogger.info('Демо: оплата картой $amount сом');
    return PaymentResult(status: PaymentResultStatus.success);
  }
}
