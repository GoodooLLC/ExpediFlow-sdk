// Конфигурация SDK - настройки подключения к серверу

class AppConfig {
  final String ordersUrl;
  final String login;
  final String password;
  final String driverId;
  final String? kkmUrl; // http://77.220.204.134:9995
  final String kkmRnm; // РНМ: 0000000000023458
  final String kkmFmNumber; // Номер ФП: 0000000002432961
  final double vatRate; // Ставка НДС, % (по умолчанию 0 - без НДС)
  final double stRate; // Ставка НсП, % (по умолчанию 0 - без НсП)
  final String bankAccount; // Лицевой счёт
  final String bankName; // Название банка
  final bool payQrEnabled; // Метод оплаты: QR
  final bool payBankEnabled; // Метод оплаты: банковское приложение

  AppConfig({
    required this.ordersUrl,
    required this.login,
    required this.password,
    required this.driverId,
    this.kkmUrl,
    this.kkmRnm = '0000000000023458',
    this.kkmFmNumber = '0000000002432961',
    this.vatRate = 0.0,
    this.stRate = 0.0,
    this.bankAccount = '',
    this.bankName = '',
    this.payQrEnabled = true,
    this.payBankEnabled = true,
  });

  // URL для callback: замена последнего сегмента на CallBackAnswer
  // Пример: .../OrderSelling/GetOrders -> .../OrderSelling/CallBackAnswer
  String get callbackUrl {
    final uri = Uri.parse(ordersUrl);
    final segments = uri.pathSegments.toList();
    if (segments.isNotEmpty) {
      segments[segments.length - 1] = 'CallBackAnswer';
    }
    return uri.replace(pathSegments: segments).toString();
  }

  bool get isValid =>
      ordersUrl.isNotEmpty &&
      login.isNotEmpty &&
      password.isNotEmpty &&
      driverId.isNotEmpty;

  AppConfig copyWith({
    String? ordersUrl,
    String? login,
    String? password,
    String? driverId,
    String? kkmUrl,
    String? kkmRnm,
    String? kkmFmNumber,
    double? vatRate,
    double? stRate,
    String? bankAccount,
    String? bankName,
    bool? payQrEnabled,
    bool? payBankEnabled,
  }) {
    return AppConfig(
      ordersUrl: ordersUrl ?? this.ordersUrl,
      login: login ?? this.login,
      password: password ?? this.password,
      driverId: driverId ?? this.driverId,
      kkmUrl: kkmUrl ?? this.kkmUrl,
      kkmRnm: kkmRnm ?? this.kkmRnm,
      kkmFmNumber: kkmFmNumber ?? this.kkmFmNumber,
      vatRate: vatRate ?? this.vatRate,
      stRate: stRate ?? this.stRate,
      bankAccount: bankAccount ?? this.bankAccount,
      bankName: bankName ?? this.bankName,
      payQrEnabled: payQrEnabled ?? this.payQrEnabled,
      payBankEnabled: payBankEnabled ?? this.payBankEnabled,
    );
  }
}
