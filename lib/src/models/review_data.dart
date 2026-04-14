// Данные отзыва клиента

class ReviewData {
  final String orderId;
  final int stars;
  final double tips;

  ReviewData({
    required this.orderId,
    required this.stars,
    this.tips = 0,
  });

  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'stars': stars,
        'tips': tips,
      };
}
