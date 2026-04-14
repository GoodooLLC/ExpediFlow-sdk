// Мок-сервис для демо - загрузка тестовых данных из assets

import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/order.dart';

class MockService {
  static Future<List<Order>> loadMockOrders() async {
    final jsonString = await rootBundle.loadString('assets/mock/orders.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final ordersList = data['orders'] as List;

    return ordersList
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
