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

// Инициализация (все параметры подключения задаются пользователем
// внутри SDK в экране настроек, передавать их при init не нужно).
OrderSellingSDK.init(SdkConfig(appConfig: AppConfig()));

// Запуск UI
OrderSellingSDK.launch(context);

// Или как виджет
OrderSellingSDK.buildWidget();
```

## Настройки

При первом запуске SDK все поля в настройках пустые. Пользователь
самостоятельно открывает настройки (иконка шестерёнки вверху справа
на главном экране) и заполняет:

- Адрес сервера 1С, логин, пароль, ID водителя
- Адрес ККМ, РНМ, номер ФП (опционально)
- Ставки НДС/НсП, реквизиты банка, методы оплаты

Все данные сохраняются локально: пароль — в `flutter_secure_storage`,
остальное — в `SharedPreferences`.
