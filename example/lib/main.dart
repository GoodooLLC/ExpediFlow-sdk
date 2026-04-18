import 'package:flutter/material.dart';
import 'package:expediflow_sdk/expediflow_sdk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Параметры подключения (URL сервера, логин, пароль, ID водителя)
  // задаются пользователем внутри SDK в экране настроек.
  OrderSellingSDK.init(SdkConfig(appConfig: AppConfig()));

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExpediFlow Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('ExpediFlow Example')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => OrderSellingSDK.launch(context),
            child: const Text('Launch ExpediFlow'),
          ),
        ),
      ),
    );
  }
}
