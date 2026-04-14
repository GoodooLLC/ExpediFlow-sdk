// Сервис хранения и загрузки настроек

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';

class ConfigService {
  static const _keyOrdersUrl = 'orders_url';
  static const _keyLogin = 'login';
  static const _keyPassword = 'password';
  static const _keyDriverId = 'driver_id';
  static const _keyKkmUrl = 'kkm_url';
  static const _keyKkmRnm = 'kkm_rnm';
  static const _keyKkmFmNumber = 'kkm_fm_number';
  static const _keyVatRate = 'vat_rate';
  static const _keyStRate = 'st_rate';
  static const _keyBankAccount = 'bank_account';
  static const _keyBankName = 'bank_name';
  static const _keyPayQrEnabled = 'pay_qr_enabled';
  static const _keyPayBankEnabled = 'pay_bank_enabled';
  static const _keyWorkMode = 'work_mode';

  final FlutterSecureStorage _secureStorage;

  ConfigService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // Сохранить конфигурацию
  Future<void> saveConfig(AppConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOrdersUrl, config.ordersUrl);
    await prefs.setString(_keyLogin, config.login);
    await prefs.setString(_keyDriverId, config.driverId);
    if (config.kkmUrl != null) {
      await prefs.setString(_keyKkmUrl, config.kkmUrl!);
    } else {
      await prefs.remove(_keyKkmUrl);
    }
    await prefs.setString(_keyKkmRnm, config.kkmRnm);
    await prefs.setString(_keyKkmFmNumber, config.kkmFmNumber);
    await prefs.setDouble(_keyVatRate, config.vatRate);
    await prefs.setDouble(_keyStRate, config.stRate);
    await prefs.setString(_keyBankAccount, config.bankAccount);
    await prefs.setString(_keyBankName, config.bankName);
    await prefs.setBool(_keyPayQrEnabled, config.payQrEnabled);
    await prefs.setBool(_keyPayBankEnabled, config.payBankEnabled);
    await _secureStorage.write(key: _keyPassword, value: config.password);
  }

  // Загрузить конфигурацию
  Future<AppConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersUrl = prefs.getString(_keyOrdersUrl);
    final login = prefs.getString(_keyLogin);
    final driverId = prefs.getString(_keyDriverId);
    final kkmUrl = prefs.getString(_keyKkmUrl);
    final kkmRnm = prefs.getString(_keyKkmRnm) ?? '0000000000023458';
    final kkmFmNumber = prefs.getString(_keyKkmFmNumber) ?? '0000000002432961';
    final vatRate = prefs.getDouble(_keyVatRate) ?? 0.0;
    final stRate = prefs.getDouble(_keyStRate) ?? 0.0;
    final bankAccount = prefs.getString(_keyBankAccount) ?? '';
    final bankName = prefs.getString(_keyBankName) ?? '';
    final payQrEnabled = prefs.getBool(_keyPayQrEnabled) ?? true;
    final payBankEnabled = prefs.getBool(_keyPayBankEnabled) ?? true;
    final password = await _secureStorage.read(key: _keyPassword);

    if (ordersUrl == null || login == null || driverId == null) {
      return null;
    }

    // Замена устаревшего localhost на реальный сервер
    final actualOrdersUrl = ordersUrl.contains('localhost')
        ? 'https://test1c.goodoo.kg/Goodoo/hs/OrderSelling/GetOrders'
        : ordersUrl;

    return AppConfig(
      ordersUrl: actualOrdersUrl,
      login: login,
      password: password ?? '',
      driverId: driverId,
      kkmUrl: kkmUrl,
      kkmRnm: kkmRnm,
      kkmFmNumber: kkmFmNumber,
      vatRate: vatRate,
      stRate: stRate,
      bankAccount: bankAccount,
      bankName: bankName,
      payQrEnabled: payQrEnabled,
      payBankEnabled: payBankEnabled,
    );
  }

  // Сохранить режим работы
  Future<void> saveWorkMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWorkMode, mode);
  }

  // Загрузить режим работы
  Future<String> loadWorkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyWorkMode) ?? 'order_selling';
  }
}
