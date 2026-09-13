class CartItem {
  const CartItem({
    required this.id,
    required this.bikeId,
    required this.bikeName,
    required this.colorName,
    required this.colorValue,
    required this.unitPrice,
    this.quantity = 1,
    this.imageUrl,
    this.addedAt = 0,
  });

  factory CartItem.fromMap(String id, Map<String, dynamic> map) => CartItem(
        id: id,
        bikeId: map['bikeId'] as String? ?? '',
        bikeName: map['bikeName'] as String? ?? '',
        colorName: map['colorName'] as String? ?? '',
        colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFF2F6BFF,
        unitPrice: (map['unitPrice'] as num?)?.toInt() ?? 0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        imageUrl: map['imageUrl'] as String?,
        addedAt: (map['addedAt'] as num?)?.toInt() ?? 0,
      );

  /// One cart line per bike + color combination.
  static String makeId(String bikeId, String colorName) =>
      '${bikeId}_${colorName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}';

  final String id;
  final String bikeId;
  final String bikeName;
  final String colorName;
  final int colorValue;
  final int unitPrice;
  final int quantity;
  final String? imageUrl;
  final int addedAt;

  int get total => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        id: id,
        bikeId: bikeId,
        bikeName: bikeName,
        colorName: colorName,
        colorValue: colorValue,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        imageUrl: imageUrl,
        addedAt: addedAt,
      );

  Map<String, dynamic> toMap() => {
        'bikeId': bikeId,
        'bikeName': bikeName,
        'colorName': colorName,
        'colorValue': colorValue,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'addedAt': addedAt,
      };
}
