class CropPrice {
  final String crop;
  final double currentPrice;
  final double change;
  final String unit;
  final String trend;
  final String? market;
  final String? state;
  final String? district;
  final String? date;
  String? smartAdvice;
  String? adviceColor; // 'green', 'yellow', 'red'

  CropPrice({
    required this.crop,
    required this.currentPrice,
    required this.change,
    required this.unit,
    required this.trend,
    this.market,
    this.state,
    this.district,
    this.date,
    this.smartAdvice,
    this.adviceColor,
  });

  bool get isUp => change >= 0;

  factory CropPrice.fromJson(Map<String, dynamic> json) => CropPrice(
    crop: json['crop'] ?? '',
    currentPrice: (json['price'] as num?)?.toDouble() ?? 0.0,
    change: (json['change'] as num?)?.toDouble() ?? 0.0,
    unit: json['unit'] ?? 'QUINTAL',
    trend: json['trend'] ?? 'STABLE',
    market: json['market'],
    state: json['state'],
    district: json['district'],
    date: json['date'],
  );
}
