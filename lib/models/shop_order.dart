import 'cart_item.dart';

enum PaymentPlan { full, finance }

class ShopOrder {
  const ShopOrder({
    this.id = '',
    required this.items,
    required this.subtotal,
    required this.plan,
    this.downPayment = 0,
    this.months = 0,
    this.monthlyInstallment = 0,
    required this.dealerId,
    required this.dealerName,
    required this.phone,
    this.status = 'pending',
    required this.createdAt,
  });

  factory ShopOrder.fromMap(String id, Map<String, dynamic> map) => ShopOrder(
        id: id,
        items: ((map['items'] as List?) ?? const [])
            .map((raw) {
              final item = Map<String, dynamic>.from(raw as Map);
              return CartItem.fromMap(item['id'] as String? ?? '', item);
            })
            .toList(),
        subtotal: (map['subtotal'] as num?)?.toInt() ?? 0,
        plan: PaymentPlan.values.firstWhere((p) => p.name == map['plan'], orElse: () => PaymentPlan.full),
        downPayment: (map['downPayment'] as num?)?.toInt() ?? 0,
        months: (map['months'] as num?)?.toInt() ?? 0,
        monthlyInstallment: (map['monthlyInstallment'] as num?)?.toInt() ?? 0,
        dealerId: map['dealerId'] as String? ?? '',
        dealerName: map['dealerName'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        status: map['status'] as String? ?? 'pending',
        createdAt: DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num?)?.toInt() ?? 0),
      );

  final String id;
  final List<CartItem> items;
  final int subtotal;
  final PaymentPlan plan;
  final int downPayment;
  final int months;
  final int monthlyInstallment;
  final String dealerId;
  final String dealerName;
  final String phone;
  final String status;
  final DateTime createdAt;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get statusLabel => switch (status) {
        'confirmed' => 'CONFIRMED',
        'delivered' => 'DELIVERED',
        'cancelled' => 'CANCELLED',
        _ => 'AWAITING SHOWROOM',
      };

  ShopOrder copyWith({String? id}) => ShopOrder(
        id: id ?? this.id,
        items: items,
        subtotal: subtotal,
        plan: plan,
        downPayment: downPayment,
        months: months,
        monthlyInstallment: monthlyInstallment,
        dealerId: dealerId,
        dealerName: dealerName,
        phone: phone,
        status: status,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'items': [for (final item in items) item.toMap()..['id'] = item.id],
        'subtotal': subtotal,
        'plan': plan.name,
        'downPayment': downPayment,
        'months': months,
        'monthlyInstallment': monthlyInstallment,
        'dealerId': dealerId,
        'dealerName': dealerName,
        'phone': phone,
        'status': status,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}
