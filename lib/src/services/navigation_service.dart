// Сервис навигации - открытие Яндекс Навигатора

import 'package:url_launcher/url_launcher.dart';

class NavigationService {
  // Открыть Яндекс Навигатор с маршрутом до точки
  static Future<bool> openYandexNavigator({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      'yandexnavi://build_route_on_map?lat_to=$latitude&lon_to=$longitude',
    );

    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }

    // Fallback - открыть Яндекс Карты в браузере
    final webUri = Uri.parse(
      'https://yandex.ru/maps/?rtext=~$latitude,$longitude&rtt=auto',
    );
    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  // Открыть точку на карте (просмотр)
  static Future<bool> openPointOnMap({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final uri = Uri.parse(
      'https://yandex.ru/maps/?pt=$longitude,$latitude&z=16&l=map',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
