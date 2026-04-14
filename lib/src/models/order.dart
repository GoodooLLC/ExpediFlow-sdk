// Модель заявки на доставку
// Формат 1С: n, date, TT, latitude, longitude, agent, amount, goods[]
// Координаты 1С: "41,0113" (запятая) или "4248,873" (DDMM,MMMM)
// TT (подтверждено клиентом 07.04.2026): строго 4 элемента через запятую:
//   "Название точки, Адрес, Телефон, Контактное лицо"
// Пример: "Токтогул,Мамаджан 60,0999331000,Садиков Р"

class OrderItem {
  final String name;
  final double quantity;
  final double price;
  final double total;
  final String? article;
  final String? unit;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
    this.article,
    this.unit,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // 1С: Product, count, prise (опечатка!), amount
    final name = _str(json, ['Product', 'name', 'Name', 'itemName',
        'Наименование']) ?? 'Без названия';
    final qty = _num(json, ['count', 'quantity', 'Quantity',
        'Количество']) ?? 1.0;
    final price = _num(json, ['prise', 'price', 'Price', 'Цена']) ?? 0.0;
    final total = _num(json, ['amount', 'total', 'Total', 'Сумма']) ??
        qty * price;

    // Артикул: извлекаем код из начала Product (например "1Э00245")
    String? article;
    final nameStr = _str(json, ['Product']) ?? '';
    final match = RegExp(r'^(\S+)\s').firstMatch(nameStr);
    if (match != null) {
      article = match.group(1);
    }

    return OrderItem(
      name: name,
      quantity: qty,
      price: price,
      total: total,
      article: article,
      unit: _str(json, ['unit', 'Unit', 'ЕдИзм']) ?? 'шт.',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'price': price,
        'total': total,
        'article': article,
        'unit': unit,
      };
}

enum OrderStatus { pending, inProgress, delivered, paid, cancelled }

class Order {
  final String id;
  final String clientName;
  final String pointName;
  final String? address;
  final String? phone;
  final String? contactPerson;
  final String date;
  final String agent;
  final String invoiceNumber;
  final double invoiceSum;
  final double latitude;
  final double longitude;
  final List<OrderItem> items;
  OrderStatus status;

  Order({
    required this.id,
    required this.clientName,
    required this.pointName,
    this.address,
    this.phone,
    this.contactPerson,
    required this.date,
    required this.agent,
    required this.invoiceNumber,
    required this.invoiceSum,
    required this.latitude,
    required this.longitude,
    required this.items,
    this.status = OrderStatus.pending,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // 1С: n, date, TT, latitude, longitude, agent, amount, goods[]
    final n = _str(json, ['n', 'id', 'Id', 'Номер']) ?? '';
    final tt = _str(json, ['TT', 'client_name', 'ClientName', 'Клиент',
        'point_name', 'PointName', 'Точка']) ?? '';
    final address = _str(json, ['address', 'Address', 'Адрес']);
    final date = _str(json, ['date', 'Date', 'Дата']) ?? '';
    final agent = _str(json, ['agent', 'Agent', 'Агент']) ?? '';
    final amount = _num(json, ['amount', 'invoice_sum', 'InvoiceSum',
        'Sum', 'Сумма']) ?? 0.0;

    // Координаты: 1С передаёт через запятую ("41,0113") или DDMM,MMMM ("4248,873")
    final lat = _parseCoord(
      _str(json, ['latitude', 'Latitude', 'lat']) ?? '',
    );
    final lon = _parseCoord(
      _str(json, ['longitude', 'Longitude', 'lon']) ?? '',
    );

    // Товары
    List<OrderItem> items = [];
    final itemsRaw = json['goods'] ?? json['items'] ?? json['Items'] ??
        json['Товары'] ?? [];
    if (itemsRaw is List) {
      items = itemsRaw
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // TT содержит 4 элемента через запятую (подтверждено клиентом):
    // "Название точки, Адрес, Телефон, Контактное лицо"
    // Пример: "Токтогул,Мамаджан 60,0999331000,Садиков Р"
    final parsed = _parseTT(tt, fallbackId: n);

    return Order(
      id: n,
      clientName: parsed.pointName,
      pointName: parsed.pointName,
      address: address ?? parsed.address,
      phone: parsed.phone,
      contactPerson: parsed.contactPerson,
      date: _formatDate(date),
      agent: agent,
      invoiceNumber: n,
      invoiceSum: amount,
      latitude: lat,
      longitude: lon,
      items: items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_name': clientName,
        'point_name': pointName,
        'address': address,
        'phone': phone,
        'contact_person': contactPerson,
        'date': date,
        'agent': agent,
        'invoice_number': invoiceNumber,
        'invoice_sum': invoiceSum,
        'latitude': latitude,
        'longitude': longitude,
        'items': items.map((item) => item.toJson()).toList(),
      };

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Новая';
      case OrderStatus.inProgress:
        return 'В пути';
      case OrderStatus.delivered:
        return 'Доставлена';
      case OrderStatus.paid:
        return 'Оплачена';
      case OrderStatus.cancelled:
        return 'Отменена';
    }
  }
}

// Результат разбора поля TT (4 элемента через запятую)
class _TTParts {
  final String pointName;
  final String? address;
  final String? phone;
  final String? contactPerson;

  _TTParts({
    required this.pointName,
    this.address,
    this.phone,
    this.contactPerson,
  });
}

// Разбор поля TT от 1С.
// Ожидаемый формат (подтверждён клиентом 07.04.2026):
//   "Название точки, Адрес, Телефон, Контактное лицо"
// Разбиваем строго по запятым. Если элементов меньше 4 - недостающие
// оставляем null, чтобы UI не падал на legacy-данных.
_TTParts _parseTT(String tt, {required String fallbackId}) {
  final trimmed = tt.trim();
  if (trimmed.isEmpty) {
    return _TTParts(pointName: 'Заявка $fallbackId');
  }

  // Разбиваем по запятым и убираем пустые/пробельные элементы
  final parts = trimmed
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return _TTParts(pointName: trimmed);
  }

  return _TTParts(
    pointName: parts[0],
    address: parts.length > 1 ? parts[1] : null,
    phone: parts.length > 2 ? parts[2] : null,
    contactPerson: parts.length > 3
        // Если после телефона больше 1 элемента (например, ФИО через запятую),
        // склеиваем оставшееся обратно
        ? parts.sublist(3).join(', ')
        : null,
  );
}

// Парсинг координат из 1С
// Варианты: "41,0113" (запятая вместо точки) -> 41.0113
//           "4248,873" (DDMM,MMMM - градусы+минуты) -> 42.81455
//           "" (пусто) -> 0.0
double _parseCoord(String raw) {
  if (raw.isEmpty) return 0.0;

  // Заменяем запятую на точку
  final normalized = raw.replaceAll(',', '.');
  final value = double.tryParse(normalized);
  if (value == null) return 0.0;

  // Проверяем формат DDMM.MMMM (значение > 90 для широты невозможно,
  // > 180 для долготы невозможно в обычном формате)
  // Для Кыргызстана: широта ~40-43, долгота ~69-80
  // Если value > 100 -> это DDMM.MMMM формат
  if (value > 100) {
    // DDMM.MMMM -> DD + MM.MMMM/60
    final degrees = (value / 100).floor();
    final minutes = value - degrees * 100;
    return degrees + minutes / 60;
  }

  return value;
}

// Формат даты 1С "20250708" -> "08.07.2025"
String _formatDate(String raw) {
  if (raw.length == 8) {
    try {
      return '${raw.substring(6, 8)}.${raw.substring(4, 6)}.${raw.substring(0, 4)}';
    } catch (_) {}
  }
  return raw;
}

// Ищем значение по нескольким ключам
String? _str(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final val = json[key];
    if (val != null && val.toString().isNotEmpty) return val.toString();
  }
  return null;
}

double? _num(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final val = json[key];
    if (val is num) return val.toDouble();
    if (val is String && val.isNotEmpty) {
      // 1С передаёт числа как строки, иногда с запятой
      final normalized = val.replaceAll(',', '.');
      final parsed = double.tryParse(normalized);
      if (parsed != null) return parsed;
    }
  }
  return null;
}
