// Вкладка основной информации заявки

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/sdk_logger.dart';

class OrderInfoTab extends StatelessWidget {
  final Order order;

  const OrderInfoTab({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRow('Точка', order.pointName),
            if (order.address != null) ...[
              _buildDivider(),
              _buildRow('Адрес', order.address!),
            ],
            if (order.phone != null) ...[
              _buildDivider(),
              _buildPhoneRow(order.phone!),
            ],
            if (order.contactPerson != null) ...[
              _buildDivider(),
              _buildRow('Контактное лицо', order.contactPerson!),
            ],
            _buildDivider(),
            _buildRow('Дата заявки', Formatters.date(order.date)),
            _buildDivider(),
            _buildRow('Агент', order.agent),
            _buildDivider(),
            _buildRow('Номер накладной', order.invoiceNumber),
            _buildDivider(),
            _buildRow(
              'Сумма накладной',
              Formatters.currency(order.invoiceSum),
              valueStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppTheme.accentColor,
              ),
            ),
            _buildDivider(),
            _buildRow(
              'Координаты',
              '${order.latitude}, ${order.longitude}',
              valueStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // Строка с телефоном - кликабельная, запускает набор номера
  Widget _buildPhoneRow(String phone) {
    return InkWell(
      onTap: () => _callPhone(phone),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                'Телефон',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Text(
                    phone,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.phone, size: 16, color: AppTheme.primaryColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callPhone(String phone) async {
    // Убираем всё кроме цифр и плюса
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    try {
      await launchUrl(uri);
    } catch (e) {
      SdkLogger.warning('Не удалось открыть звонок $clean: $e');
    }
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey[200], height: 1);
  }
}
