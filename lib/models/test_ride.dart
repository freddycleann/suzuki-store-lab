class TestRide {
  const TestRide({
    this.id = '',
    required this.bikeId,
    required this.bikeName,
    this.imageUrl,
    required this.dealerId,
    required this.dealerName,
    required this.date,
    required this.timeSlot,
    required this.phone,
    this.note = '',
    this.status = 'confirmed',
    required this.createdAt,
  });

  factory TestRide.fromMap(String id, Map<String, dynamic> map) => TestRide(
        id: id,
        bikeId: map['bikeId'] as String? ?? '',
        bikeName: map['bikeName'] as String? ?? '',
        imageUrl: map['imageUrl'] as String?,
        dealerId: map['dealerId'] as String? ?? '',
        dealerName: map['dealerName'] as String? ?? '',
        date: DateTime.fromMillisecondsSinceEpoch((map['date'] as num?)?.toInt() ?? 0),
        timeSlot: map['timeSlot'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        note: map['note'] as String? ?? '',
        status: map['status'] as String? ?? 'confirmed',
        createdAt: DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num?)?.toInt() ?? 0),
      );

  final String id;
  final String bikeId;
  final String bikeName;
  final String? imageUrl;
  final String dealerId;
  final String dealerName;

  /// Ride start (date + time slot).
  final DateTime date;
  final String timeSlot;
  final String phone;
  final String note;
  final String status;
  final DateTime createdAt;

  bool get isCancelled => status == 'cancelled';
  bool get isUpcoming => !isCancelled && date.isAfter(DateTime.now());

  TestRide copyWith({String? id, String? status}) => TestRide(
        id: id ?? this.id,
        bikeId: bikeId,
        bikeName: bikeName,
        imageUrl: imageUrl,
        dealerId: dealerId,
        dealerName: dealerName,
        date: date,
        timeSlot: timeSlot,
        phone: phone,
        note: note,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'bikeId': bikeId,
        'bikeName': bikeName,
        'imageUrl': imageUrl,
        'dealerId': dealerId,
        'dealerName': dealerName,
        'date': date.millisecondsSinceEpoch,
        'timeSlot': timeSlot,
        'phone': phone,
        'note': note,
        'status': status,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}
