// Экран детали заявки - 2 вкладки: основная информация + товары

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../order_selling_sdk.dart';
import 'order_info_tab.dart';
import 'order_items_tab.dart';

class OrderDetailScreen extends StatelessWidget {
  final int orderIndex;

  const OrderDetailScreen({super.key, required this.orderIndex});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersProvider>(
      builder: (context, provider, child) {
        final order = provider.getOrderAt(orderIndex);
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Заявка')),
            body: const Center(child: Text('Заявка не найдена')),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Заявка #${order.invoiceNumber}'),
              bottom: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'Информация'),
                  Tab(text: 'Товары'),
                ],
              ),
            ),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      children: [
                        OrderInfoTab(order: order),
                        OrderItemsTab(order: order),
                      ],
                    ),
                  ),
                  _buildPaymentButtons(context, order, provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentButtons(
    BuildContext context,
    Order order,
    OrdersProvider provider,
  ) {
    if (order.status == OrderStatus.paid) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: AppTheme.successColor.withValues(alpha: 0.1),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor),
            SizedBox(width: 8),
            Text(
              'Оплачено',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _onQrPayment(context, order, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.qr_code),
              label: const Text('QR', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _onCardPayment(context, order, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.credit_card),
              label: const Text('Карта', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _onQrPayment(BuildContext context, Order order, OrdersProvider provider) async {
    final paymentProvider = OrderSellingSDK.paymentProvider;

    if (paymentProvider == null || !(await paymentProvider.isAvailable())) {
      if (!context.mounted) return;
      _showErrorDialog(context,
        'Платёжная система GoodooPay не настроена.\n'
        'Проверьте настройки приложения.');
      return;
    }

    if (!context.mounted) return;
    _showLoadingDialog(context, 'Запуск оплаты...');

    SdkLogger.info('Оплата QR: заявка #${order.invoiceNumber}, ${order.invoiceSum} сом');

    final result = await paymentProvider.payByQR(
      amount: order.invoiceSum,
      description: 'Оплата заявки #${order.invoiceNumber}',
      context: context,
    );

    if (!context.mounted) return;
    Navigator.pop(context);

    if (result.isSuccess) {
      SdkLogger.info('Оплата QR: успех');
      await _onPaymentSuccess(context, order, provider, 'qr');
    } else if (result.isCancelled) {
      SdkLogger.info('Оплата QR: отменена');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Оплата отменена')),
      );
    } else {
      SdkLogger.error('Оплата QR: ${result.error}');
      _showErrorDialog(context, result.error ?? 'Ошибка оплаты');
    }
  }

  void _onCardPayment(BuildContext context, Order order, OrdersProvider provider) async {

    final fiscalProvider = OrderSellingSDK.fiscalProvider;

    if (fiscalProvider == null || !(await fiscalProvider.isAvailable())) {
      if (!context.mounted) return;
      String details = 'provider: ${fiscalProvider == null ? "null" : fiscalProvider.runtimeType}';
      if (fiscalProvider is HttpFiscalProvider) {
        details += '\nkkmUrl: "${(fiscalProvider as HttpFiscalProvider).config.baseUrl}"';
        details += '\nRNM: "${(fiscalProvider as HttpFiscalProvider).config.rnm}"';
      }
      _showErrorDialog(context,
        'ККМ не настроена.\n\n$details\n\n'
        'Укажите адрес ККМ в настройках и нажмите "Сохранить".');
      return;
    }

    if (!context.mounted) return;
    _showLoadingDialog(context, 'Связь с ККМ...');

    SdkLogger.info('Оплата картой: заявка #${order.invoiceNumber}, ${order.invoiceSum} сом');

    final result = await fiscalProvider.printReceipt(
      order: order,
      paymentType: 'card',
    );

    if (!context.mounted) return;
    Navigator.pop(context);

    if (result.success) {
      SdkLogger.info('Оплата картой: чек пробит');
      await _onPaymentSuccess(
        context, order, provider, 'card',
        fiscalData: result.toJson(),
      );
    } else {
      SdkLogger.error('Оплата картой: ${result.error}');
      _showErrorDialog(context, result.error ?? 'Ошибка ККМ');
    }
  }

  Future<void> _onPaymentSuccess(
    BuildContext context,
    Order order,
    OrdersProvider provider,
    String paymentType, {
    Map<String, dynamic>? fiscalData,
  }) async {
    // QR-оплата тоже требует чек
    if (paymentType == 'qr') {
      final fiscalProvider = OrderSellingSDK.fiscalProvider;
      if (fiscalProvider != null && await fiscalProvider.isAvailable()) {
        final fiscalResult = await fiscalProvider.printReceipt(
          order: order,
          paymentType: 'qr',
        );
        if (fiscalResult.success) {
          fiscalData = fiscalResult.toJson();
        }
      }
    }

    provider.markOrderAsPaid(order.invoiceNumber);

    await CallbackQueue.enqueue(CallbackData(
      orderNumber: order.invoiceNumber,
      statusPay: 'оплачено',
      statusDoc: 'доставлен',
    ));

    if (provider.api != null) {
      final sent = await CallbackQueue.flush(provider.api!);
      SdkLogger.info('Callback: отправлено $sent');
    }

    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed('/review', arguments: order.id);
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLarge),
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLarge),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.dangerColor),
            SizedBox(width: 8),
            Text('Ошибка'),
          ],
        ),
        content: Text(error),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
