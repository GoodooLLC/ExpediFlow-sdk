// Сервис построения маршрута - OSRM (бесплатный, без ключа)
// Рассчитывает реальный маршрут по дорогам, дистанцию и время

import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../utils/sdk_logger.dart';

class RouteInfo {
  final List<LatLng> points; // точки маршрута для отрисовки
  final double distanceKm; // общая дистанция в км
  final int durationMinutes; // время в минутах

  RouteInfo({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });

  String get distanceText {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} м';
    }
    return '${distanceKm.toStringAsFixed(1)} км';
  }

  String get durationText {
    if (durationMinutes < 60) {
      return '$durationMinutes мин';
    }
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    return '$hours ч ${mins > 0 ? "$mins мин" : ""}';
  }
}

class RouteService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Построить маршрут через все точки по порядку (OSRM)
  static Future<RouteInfo?> buildRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return null;

    SdkLogger.info('Маршрут: построение через ${waypoints.length} точек');

    try {
      // Формат координат для OSRM: lon,lat;lon,lat;...
      final coords = waypoints
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      final response = await _dio.get(
        'https://router.project-osrm.org/route/v1/driving/$coords',
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
          'steps': 'false',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        SdkLogger.warning('Маршрут: OSRM вернул пустой результат');
        return null;
      }

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List;
      final distance = (route['distance'] as num).toDouble();
      final duration = (route['duration'] as num).toDouble();

      // GeoJSON: [lon, lat] -> LatLng(lat, lon)
      final routePoints = coordinates.map((coord) {
        final c = coord as List;
        return LatLng(
          (c[1] as num).toDouble(),
          (c[0] as num).toDouble(),
        );
      }).toList();

      final info = RouteInfo(
        points: routePoints,
        distanceKm: distance / 1000,
        durationMinutes: (duration / 60).ceil(),
      );

      SdkLogger.info(
        'Маршрут: ${info.distanceText}, ${info.durationText}',
      );

      return info;
    } catch (e) {
      SdkLogger.error('Маршрут: ошибка построения - $e');
      return null;
    }
  }
}
