// Экран списка заявок

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/orders_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../order_detail/order_detail_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            _PeriodFilter(provider: provider),
            Expanded(child: _buildContent(context, provider)),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, OrdersProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return _buildErrorState(context, provider);
    }

    if (provider.orders.isEmpty) {
      return _buildEmptyState(context, provider);
    }

    return RefreshIndicator(
      onRefresh: provider.fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: provider.orders.length,
        itemBuilder: (context, index) => _buildOrderCard(
          context,
          provider.orders[index],
          index,
          index == provider.currentOrderIndex,
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    Order order,
    int index,
    bool isCurrent,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
        side: isCurrent
            ? const BorderSide(color: AppTheme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: AppTheme.borderRadiusMedium,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderIndex: index),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Номер заявки
              _buildOrderNumber(index + 1, order.status),
              const SizedBox(width: 12),

              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название точки (заголовок)
                    Text(
                      order.pointName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Адрес
                    if (order.address != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        order.address!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Контакт + телефон в одну строку
                    if (order.contactPerson != null || order.phone != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (order.contactPerson != null) order.contactPerson!,
                          if (order.phone != null) order.phone!,
                        ].join(' · '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Сумма и статус
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(order.invoiceSum),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(order),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderNumber(int number, OrderStatus status) {
    final color = _statusColor(status);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Order order) {
    final color = _statusColor(order.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: Text(
        order.statusText,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppTheme.pendingColor;
      case OrderStatus.inProgress:
        return AppTheme.inProgressColor;
      case OrderStatus.delivered:
        return AppTheme.deliveredColor;
      case OrderStatus.paid:
        return AppTheme.paidColor;
      case OrderStatus.cancelled:
        return AppTheme.cancelledColor;
    }
  }

  Widget _buildErrorState(BuildContext context, OrdersProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.dangerColor),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: provider.fetchOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, OrdersProvider provider) {
    final notConfigured = provider.api == null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              notConfigured ? Icons.settings_outlined : Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              notConfigured ? 'Не настроено подключение' : 'Нет заявок',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              notConfigured
                  ? 'Откройте настройки (иконка шестерёнки вверху справа)\nи укажите адрес сервера, логин, пароль и ID водителя.'
                  : 'За выбранный период заявок нет.\nПопробуйте изменить период вверху.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (!notConfigured)
              ElevatedButton.icon(
                onPressed: provider.fetchOrders,
                icon: const Icon(Icons.refresh),
                label: const Text('Обновить'),
              ),
          ],
        ),
      ),
    );
  }
}

// Панель фильтра периода заявок (даты "с" и "по" + кнопка применения)
class _PeriodFilter extends StatelessWidget {
  final OrdersProvider provider;

  const _PeriodFilter({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDateField(
              context,
              label: 'С',
              date: provider.dateFrom,
              onPick: (picked) => provider.setPeriod(picked, provider.dateTo),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildDateField(
              context,
              label: 'По',
              date: provider.dateTo,
              onPick: (picked) => provider.setPeriod(provider.dateFrom, picked),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: provider.fetchOrders,
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            tooltip: 'Обновить',
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required DateTime date,
    required ValueChanged<DateTime> onPick,
  }) {
    final formatter = DateFormat('dd.MM.yyyy');
    return InkWell(
      borderRadius: AppTheme.borderRadiusSmall,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(DateTime.now().year + 2, 12, 31),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: AppTheme.borderRadiusSmall,
        ),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Expanded(
              child: Text(
                formatter.format(date),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
