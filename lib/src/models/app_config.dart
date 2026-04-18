// Конфигурация SDK - настройки подключения к серверу.
// Параметры подключения (ordersUrl/login/password/driverId) опциональны:
// они задаются в настройках внутри SDK, а не передаются извне при вызове.

class AppConfig {
  final String ordersUrl;
  final String login;
  final String password;
  final String driverId;
  final String? kkmUrl;
  final String kkmRnm; // РНМ
  final String kkmFmNumber; // Номер ФП
  final double vatRate; // Ставка НДС, %
  final double stRate; // Ставка НсП, %
  final String bankAccount; // Лицевой счёт
  final String bankName; // Название банка
  final bool payQrEnabled; // Метод оплаты: QR
  final bool payBankEnabled; // Метод оплаты: банковское приложение

  AppConfig({
    this.ordersUrl = '',
    this.login = '',
    this.password = '',
    this.driverId = '',
    this.kkmUrl,
    this.kkmRnm = '',
    this.kkmFmNumber = '',
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
