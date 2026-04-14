# ExpediFlow SDK

Модуль Order Selling для автоматизации работы экспедиторов.

## Подключение

```yaml
dependencies:
  expediflow_sdk:
    git:
      url: https://github.com/GoodooLLC/ExpediFlow-sdk.git
```

## Использование

```dart
import 'package:expediflow_sdk/expediflow_sdk.dart';

// Инициализация
OrderSellingSDK.init(SdkConfig(
  appConfig: AppConfig(
    ordersUrl: 'https://your-server/api/GetOrders',
    login: 'user',
    password: 'pass',
    driverId: 'driver-id',
  ),
));

// Запуск UI
OrderSellingSDK.launch(context);

// Или как виджет
OrderSellingSDK.buildWidget();
```
