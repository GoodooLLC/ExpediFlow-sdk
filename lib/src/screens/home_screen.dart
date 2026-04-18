// Главный экран - вкладки "Заявки" и "Маршрут"

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/orders_provider.dart';
import '../services/config_service.dart';
import 'orders/orders_screen.dart';
import 'route_map/route_map_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  final _configService = ConfigService();

  final _screens = const [
    OrdersScreen(),
    RouteMapScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  // Загрузить настройки (без автозагрузки заявок - только по кнопке "Обновить").
  // Если настройки не заданы - открывать окно настроек НЕ надо:
  // пользователь сам откроет их кнопкой в AppBar.
  Future<void> _initAndLoad() async {
    final config = await _configService.loadConfig();
    if (!mounted) return;

    if (config != null && config.isValid) {
      final provider = context.read<OrdersProvider>();
      provider.init(config);
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          onConfigSaved: (config) {
            final provider = context.read<OrdersProvider>();
            provider.init(config);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ExpediFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Настройки',
          ),
        ],
      ),
      body: SafeArea(child: _screens[_currentTab]),
      bottomNavigationBar: SafeArea(child: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          setState(() => _currentTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Заявки',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Маршрут',
          ),
        ],
      )),
    );
  }
}
