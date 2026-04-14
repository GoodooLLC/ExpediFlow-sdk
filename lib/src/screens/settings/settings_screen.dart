// Экран настроек - URL, логин, пароль, ID водителя, ККМ

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../models/app_config.dart';
import '../../services/config_service.dart';
import '../../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final Function(AppConfig config) onConfigSaved;

  const SettingsScreen({super.key, required this.onConfigSaved});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _configService = ConfigService();

  final _urlController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _driverIdController = TextEditingController();
  final _kkmUrlController = TextEditingController();
  final _kkmRnmController = TextEditingController();
  final _kkmFmController = TextEditingController();
  final _vatRateController = TextEditingController();
  final _stRateController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankNameController = TextEditingController();

  String _workMode = 'order_selling';
  bool _isLoading = true;
  bool _obscurePassword = true;
  bool _payQrEnabled = true;
  bool _payBankEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _configService.loadConfig();
    final mode = await _configService.loadWorkMode();

    if (config != null) {
      _urlController.text = config.ordersUrl;
      _loginController.text = config.login;
      _passwordController.text = config.password;
      _driverIdController.text = config.driverId;
      _kkmUrlController.text = config.kkmUrl ?? 'http://77.220.204.134:9995';
      _kkmRnmController.text = config.kkmRnm;
      _kkmFmController.text = config.kkmFmNumber;
      _vatRateController.text = config.vatRate.toString();
      _stRateController.text = config.stRate.toString();
      _bankAccountController.text = config.bankAccount;
      _bankNameController.text = config.bankName;
      _payQrEnabled = config.payQrEnabled;
      _payBankEnabled = config.payBankEnabled;
    } else {
      // Дефолтные значения
      _urlController.text = 'https://test1c.goodoo.kg/Goodoo/hs/OrderSelling/GetOrders';
      _loginController.text = 'goodoo';
      _passwordController.text = 'rjvfylf ghjatccbjyfkjd';
      _driverIdController.text = 'eb572cff0d4640cc8cf72752684c5373';
      _kkmUrlController.text = 'http://77.220.204.134:9995';
      _kkmRnmController.text = '0000000000023458';
      _kkmFmController.text = '0000000002432961';
      _vatRateController.text = '0';
      _stRateController.text = '0';
    }

    setState(() {
      _workMode = mode;
      _isLoading = false;
    });
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final kkmUrl = _kkmUrlController.text.trim();
    final vatRate = double.tryParse(_vatRateController.text.trim().replaceAll(',', '.')) ?? 0.0;
    final stRate = double.tryParse(_stRateController.text.trim().replaceAll(',', '.')) ?? 0.0;

    final config = AppConfig(
      ordersUrl: _urlController.text.trim(),
      login: _loginController.text.trim(),
      password: _passwordController.text,
      driverId: _driverIdController.text.trim(),
      kkmUrl: kkmUrl.isNotEmpty ? kkmUrl : null,
      kkmRnm: _kkmRnmController.text.trim(),
      kkmFmNumber: _kkmFmController.text.trim(),
      vatRate: vatRate,
      stRate: stRate,
      bankAccount: _bankAccountController.text.trim(),
      bankName: _bankNameController.text.trim(),
      payQrEnabled: _payQrEnabled,
      payBankEnabled: _payBankEnabled,
    );

    await _configService.saveConfig(config);
    await _configService.saveWorkMode(_workMode);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Сохранено. ККМ: ${config.kkmUrl ?? "не задан"}'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      widget.onConfigSaved(config);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _driverIdController.dispose();
    _kkmUrlController.dispose();
    _kkmRnmController.dispose();
    _kkmFmController.dispose();
    _vatRateController.dispose();
    _stRateController.dispose();
    _bankAccountController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Режим работы'),
              const SizedBox(height: 8),
              _buildWorkModeSelector(),
              const SizedBox(height: 24),

              _buildSectionTitle('Подключение к серверу'),
              const SizedBox(height: 8),
              _buildUrlField(),
              const SizedBox(height: 12),
              _buildLoginField(),
              const SizedBox(height: 12),
              _buildPasswordField(),
              const SizedBox(height: 24),

              _buildSectionTitle('Идентификация водителя'),
              const SizedBox(height: 8),
              _buildDriverIdField(),
              const SizedBox(height: 24),

              _buildSectionTitle('ККМ (кассовый аппарат)'),
              const SizedBox(height: 8),
              _buildKkmUrlField(),
              const SizedBox(height: 12),
              _buildKkmRnmField(),
              const SizedBox(height: 12),
              _buildKkmFmField(),
              const SizedBox(height: 12),
              _buildVatRateField(),
              const SizedBox(height: 12),
              _buildStRateField(),
              const SizedBox(height: 12),
              _buildTestKkmButton(),
              const SizedBox(height: 24),

              _buildSectionTitle('Платёжные реквизиты'),
              const SizedBox(height: 8),
              _buildBankAccountField(),
              const SizedBox(height: 12),
              _buildBankNameField(),
              const SizedBox(height: 24),

              _buildSectionTitle('Методы оплаты GoodooPay'),
              const SizedBox(height: 8),
              _buildPaymentMethodsSelector(),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saveConfig,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('Сохранить', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.accentColor,
      ),
    );
  }

  Widget _buildWorkModeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonFormField<String>(
          initialValue: _workMode,
          decoration: const InputDecoration(
            border: InputBorder.none,
            labelText: 'Режим',
          ),
          items: const [
            DropdownMenuItem(
              value: 'order_selling',
              child: Text('Order Selling'),
            ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _workMode = value);
          },
        ),
      ),
    );
  }

  Widget _buildUrlField() {
    return TextFormField(
      controller: _urlController,
      maxLength: 250,
      keyboardType: TextInputType.url,
      decoration: const InputDecoration(
        labelText: 'URL для запроса заявок',
        hintText: 'https://example.com/api/Orders',
        prefixIcon: Icon(Icons.link),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Укажите URL';
        }
        final uri = Uri.tryParse(value.trim());
        if (uri == null || !uri.hasScheme) {
          return 'Некорректный URL';
        }
        return null;
      },
    );
  }

  Widget _buildLoginField() {
    return TextFormField(
      controller: _loginController,
      maxLength: 250,
      decoration: const InputDecoration(
        labelText: 'Логин',
        prefixIcon: Icon(Icons.person),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Укажите логин';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      maxLength: 250,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Пароль',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Укажите пароль';
        return null;
      },
    );
  }

  Widget _buildDriverIdField() {
    return TextFormField(
      controller: _driverIdController,
      decoration: const InputDecoration(
        labelText: 'ID водителя',
        hintText: 'Идентификатор из системы учета',
        prefixIcon: Icon(Icons.badge),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Укажите ID водителя';
        return null;
      },
    );
  }

  Widget _buildKkmUrlField() {
    return TextFormField(
      controller: _kkmUrlController,
      keyboardType: TextInputType.url,
      decoration: const InputDecoration(
        labelText: 'Адрес ККМ',
        hintText: 'http://77.220.204.134:9995',
        prefixIcon: Icon(Icons.point_of_sale),
      ),
    );
  }

  Widget _buildKkmRnmField() {
    return TextFormField(
      controller: _kkmRnmController,
      decoration: const InputDecoration(
        labelText: 'РНМ (регистрационный номер)',
        hintText: '0000000000023458',
        prefixIcon: Icon(Icons.numbers),
      ),
    );
  }

  Widget _buildKkmFmField() {
    return TextFormField(
      controller: _kkmFmController,
      decoration: const InputDecoration(
        labelText: 'Номер фискальной памяти',
        hintText: '0000000002432961',
        prefixIcon: Icon(Icons.memory),
      ),
    );
  }

  Widget _buildVatRateField() {
    return TextFormField(
      controller: _vatRateController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Ставка НДС, %',
        hintText: '0 (без НДС)',
        prefixIcon: Icon(Icons.percent),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null;
        final v = double.tryParse(value.trim().replaceAll(',', '.'));
        if (v == null || v < 0 || v > 100) {
          return 'Введите число от 0 до 100';
        }
        return null;
      },
    );
  }

  Widget _buildStRateField() {
    return TextFormField(
      controller: _stRateController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Ставка НсП, %',
        hintText: '0 (без НсП)',
        prefixIcon: Icon(Icons.percent),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null;
        final v = double.tryParse(value.trim().replaceAll(',', '.'));
        if (v == null || v < 0 || v > 100) {
          return 'Введите число от 0 до 100';
        }
        return null;
      },
    );
  }

  Widget _buildTestKkmButton() {
    return OutlinedButton.icon(
      onPressed: _testKkm,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.accentColor,
        side: const BorderSide(color: AppTheme.accentColor),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: const Icon(Icons.wifi_find),
      label: const Text('Проверка связи'),
    );
  }

  Future<void> _testKkm() async {
    final baseUrl = _kkmUrlController.text.trim();
    final rnm = _kkmRnmController.text.trim();

    if (baseUrl.isEmpty) {
      _showKkmResult(
        title: 'Ошибка',
        icon: Icons.error_outline,
        color: AppTheme.dangerColor,
        body: 'Укажите адрес ККМ',
      );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLarge),
        content: const Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Selftest ККМ...'),
          ],
        ),
      ),
    );

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'RNM': rnm,
      },
    ));

    final endpoint = '$baseUrl/fiscal/commons/selfTest/';

    try {
      final response = await dio.post(endpoint);
      if (!mounted) return;
      Navigator.pop(context);

      final prettyResponse = const JsonEncoder.withIndent('  ')
          .convert(response.data);

      _showKkmResult(
        title: 'Ответ ККМ',
        icon: Icons.check_circle,
        color: AppTheme.successColor,
        body: 'POST $endpoint\nRNM: $rnm\n\n'
            'Status: ${response.statusCode}\n\n'
            'Ответ:\n$prettyResponse',
        copyText: 'POST $endpoint\nRNM: $rnm\n\n'
            'Status: ${response.statusCode}\n$prettyResponse',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      String errorBody = e.toString();
      if (e is DioException && e.response != null) {
        errorBody = 'Status: ${e.response?.statusCode}\n'
            'Ответ: ${e.response?.data}';
      }

      _showKkmResult(
        title: 'Ошибка ККМ',
        icon: Icons.error_outline,
        color: AppTheme.dangerColor,
        body: 'POST $endpoint\nRNM: $rnm\n\n$errorBody',
        copyText: 'POST $endpoint\nRNM: $rnm\n\n$errorBody',
      );
    }
  }

  void _showKkmResult({
    required String title,
    required IconData icon,
    required Color color,
    required String body,
    String? copyText,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLarge),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            body,
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          if (copyText != null)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: copyText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Скопировано в буфер')),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Копировать'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountField() {
    return TextFormField(
      controller: _bankAccountController,
      decoration: const InputDecoration(
        labelText: 'Лицевой счёт',
        hintText: 'Номер лицевого счёта',
        prefixIcon: Icon(Icons.account_balance_wallet),
      ),
    );
  }

  Widget _buildPaymentMethodsSelector() {
    return Card(
      child: Column(
        children: [
          CheckboxListTile(
            title: const Text('QR-оплата'),
            subtitle: const Text('Оплата через QR-код'),
            value: _payQrEnabled,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) {
              setState(() => _payQrEnabled = value ?? true);
            },
          ),
          const Divider(height: 1),
          CheckboxListTile(
            title: const Text('Банковское приложение'),
            subtitle: const Text('Оплата через банк'),
            value: _payBankEnabled,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) {
              setState(() => _payBankEnabled = value ?? true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBankNameField() {
    return TextFormField(
      controller: _bankNameController,
      decoration: const InputDecoration(
        labelText: 'Название банка',
        hintText: 'Название банка',
        prefixIcon: Icon(Icons.account_balance),
      ),
    );
  }
}
