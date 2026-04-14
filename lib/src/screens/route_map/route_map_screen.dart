// Экран маршрута - карта OpenStreetMap + маршрут по дорогам + навигация

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/orders_provider.dart';
import '../../services/navigation_service.dart';
import '../../services/route_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/sdk_logger.dart';
import '../order_detail/order_detail_screen.dart';

class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({super.key});

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  RouteInfo? _routeInfo;
  bool _isLoadingRoute = false;
  bool _navigatingToPoint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Строим маршрут автоматически при загрузке
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildRoute());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Обнаружение возврата из навигатора
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _navigatingToPoint) {
      _navigatingToPoint = false;
      _onReturnFromNavigator();
    }
  }

  // Возврат из навигатора -> открываем деталь текущей заявки
  void _onReturnFromNavigator() {
    final provider = context.read<OrdersProvider>();
    final current = provider.currentOrder;
    if (current == null) return;

    SdkLogger.info('Возврат из навигатора -> заявка #${current.invoiceNumber}');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderIndex: provider.currentOrderIndex,
        ),
      ),
    );
  }

  Future<void> _buildRoute() async {
    final provider = context.read<OrdersProvider>();
    if (provider.orders.isEmpty) return;

    setState(() => _isLoadingRoute = true);

    final waypoints = provider.orders
        .map((o) => LatLng(o.latitude, o.longitude))
        .toList();

    final route = await RouteService.buildRoute(waypoints);

    if (mounted) {
      setState(() {
        _routeInfo = route;
        _isLoadingRoute = false;
      });

      // Подгоняем камеру под все точки
      if (waypoints.length >= 2) {
        final bounds = LatLngBounds.fromPoints(waypoints);
        // Если все точки совпадают - bounds нулевого размера, fitCamera даст Infinity
        final dlat = (bounds.north - bounds.south).abs();
        final dlng = (bounds.east - bounds.west).abs();
        if (dlat < 0.0001 && dlng < 0.0001) {
          _mapController.move(waypoints.first, 14);
        } else {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(40),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersProvider>(
      builder: (context, provider, child) {
        if (provider.orders.isEmpty) {
          return const Center(child: Text('Нет точек для маршрута'));
        }

        return Column(
          children: [
            _buildMap(provider),
            _buildRouteInfoBar(provider),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: provider.orders.length,
                itemBuilder: (context, index) => _buildRoutePoint(
                  context,
                  provider.orders[index],
                  index,
                  index == provider.currentOrderIndex,
                  provider,
                ),
              ),
            ),
            _buildNavigationButton(context, provider),
          ],
        );
      },
    );
  }

  Widget _buildMap(OrdersProvider provider) {
    final points = provider.orders
        .map((o) => LatLng(o.latitude, o.longitude))
        .toList();

    final center = provider.currentOrder != null
        ? LatLng(provider.currentOrder!.latitude, provider.currentOrder!.longitude)
        : points.first;

    return SizedBox(
      height: 220,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 12,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.newcas.app',
          ),
          // Маршрут по дорогам (если построен) или прямые линии
          PolylineLayer(
            polylines: [
              if (_routeInfo != null)
                Polyline(
                  points: _routeInfo!.points,
                  color: AppTheme.primaryColor,
                  strokeWidth: 4,
                )
              else
                Polyline(
                  points: points,
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  strokeWidth: 2,
                  isDotted: true,
                ),
            ],
          ),
          MarkerLayer(markers: _buildMarkers(provider)),
        ],
      ),
    );
  }

  // Панель с информацией о маршруте: прогресс + дистанция/время
  Widget _buildRouteInfoBar(OrdersProvider provider) {
    final doneCount = provider.orders.where((o) => o.status == OrderStatus.paid).length;
    final total = provider.orders.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Прогресс
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: total > 0 ? doneCount / total : 0,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation(AppTheme.successColor),
                  borderRadius: AppTheme.borderRadiusSmall,
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$doneCount / $total',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          // Дистанция и время
          if (_routeInfo != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.route, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _routeInfo!.distanceText,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _routeInfo!.durationText,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
          if (_isLoadingRoute)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: SizedBox(
                height: 2,
                child: LinearProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(OrdersProvider provider) {
    return List.generate(provider.orders.length, (index) {
      final order = provider.orders[index];
      final isDone = order.status == OrderStatus.paid;
      final isCurrent = index == provider.currentOrderIndex;

      Color color;
      if (isDone) {
        color = AppTheme.markerDone;
      } else if (isCurrent) {
        color = AppTheme.markerCurrent;
      } else {
        color = AppTheme.markerPending;
      }

      return Marker(
        point: LatLng(order.latitude, order.longitude),
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () {
            provider.setCurrentIndex(index);
            _mapController.move(LatLng(order.latitude, order.longitude), 14);
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildRoutePoint(
    BuildContext context,
    Order order,
    int index,
    bool isCurrent,
    OrdersProvider provider,
  ) {
    final isDone = order.status == OrderStatus.paid;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
        side: isCurrent
            ? const BorderSide(color: AppTheme.inProgressColor, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _buildPointMarker(index + 1, isDone, isCurrent),
        title: Text(
          order.pointName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          order.address ?? '${order.latitude.toStringAsFixed(5)}, ${order.longitude.toStringAsFixed(5)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Formatters.currency(order.invoiceSum),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDone ? Colors.grey : null,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isDone ? Icons.check_circle : Icons.chevron_right,
              color: isDone ? AppTheme.successColor : Colors.grey[400],
              size: 20,
            ),
          ],
        ),
        onTap: () {
          provider.setCurrentIndex(index);
          _mapController.move(LatLng(order.latitude, order.longitude), 14);
        },
      ),
    );
  }

  Widget _buildPointMarker(int number, bool isDone, bool isCurrent) {
    Color color;
    if (isDone) {
      color = AppTheme.markerDone;
    } else if (isCurrent) {
      color = AppTheme.markerCurrent;
    } else {
      color = AppTheme.markerPending;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: isDone
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _buildNavigationButton(BuildContext context, OrdersProvider provider) {
    final current = provider.currentOrder;
    if (current == null || current.status == OrderStatus.paid) {
      final allDone = provider.orders.every((o) => o.status == OrderStatus.paid);

      if (allDone && provider.orders.isNotEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: AppTheme.successColor, size: 28),
              SizedBox(width: 8),
              Text(
                'Все заявки доставлены!',
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
      return const SizedBox.shrink();
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _startNavigation(context, current, provider),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.navigation),
          label: Text(
            'Начать движение -> ${current.pointName}',
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ),
    );
  }

  Future<void> _startNavigation(
    BuildContext context,
    Order order,
    OrdersProvider provider,
  ) async {
    provider.startMovingToCurrent();
    _navigatingToPoint = true;

    SdkLogger.info('Навигация: старт к ${order.pointName}');

    final launched = await NavigationService.openYandexNavigator(
      latitude: order.latitude,
      longitude: order.longitude,
    );

    if (!launched && context.mounted) {
      _navigatingToPoint = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось открыть навигатор'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }
}
