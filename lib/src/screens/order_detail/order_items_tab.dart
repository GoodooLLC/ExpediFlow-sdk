// Вкладка товарных позиций заявки (только просмотр)

import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';

class OrderItemsTab extends StatelessWidget {
  final Order order;

  const OrderItemsTab({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Заголовок таблицы
        _buildHeader(),

        // Список товаров
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: order.items.length,
            separatorBuilder: (_, _) =>
                Divider(color: Colors.grey[200], height: 1),
            itemBuilder: (context, index) =>
                _buildItemRow(order.items[index], index),
          ),
        ),

        // Итого
        _buildTotalRow(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.grey[100],
      child: const Row(
        children: [
          SizedBox(width: 28),
          Expanded(
            flex: 4,
            child: Text(
              'Наименование',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Кол.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Цена',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Сумма',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${index + 1}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              item.name,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              Formatters.quantity(item.quantity),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              Formatters.currency(item.price),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              Formatters.currency(item.total),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'ИТОГО:',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Text(
            Formatters.currency(order.invoiceSum),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
