import 'package:flutter/material.dart';
import 'package:expediflow_sdk/expediflow_sdk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  OrderSellingSDK.init(SdkConfig(
    appConfig: AppConfig(
      ordersUrl: 'https://your-server/api/GetOrders',
      login: 'user',
      password: 'pass',
      driverId: 'driver-id',
    ),
  ));

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
