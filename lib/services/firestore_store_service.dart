import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item.dart';
import '../models/shop_order.dart';
import '../models/test_ride.dart';
import 'store_service.dart';

/// Thrown when Firestore does not confirm a write in time — most often
/// because the Firestore database has not been created for the project.
class FirestoreUnavailable implements Exception {
  const FirestoreUnavailable();

  @override
  String toString() =>
      'Cloud Firestore did not respond. Make sure the Firestore database is created in the Firebase console.';
}

/// Firestore layout:
///   users/{uid}                 profile
///   users/{uid}/cart/{itemId}
///   users/{uid}/favorites/{bikeId}
///   users/{uid}/orders/{orderId}
///   users/{uid}/testRides/{rideId}
class FirestoreStoreService implements StoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _writeTimeout = Duration(seconds: 15);

  CollectionReference<Map<String, dynamic>> _col(String uid, String name) =>
      _db.collection('users').doc(uid).collection(name);

  /// Firestore write futures only complete when the server acknowledges them,
  /// so a missing or unreachable database would otherwise leave the UI spinning.
  Future<T> _confirmed<T>(Future<T> write) =>
      write.timeout(_writeTimeout, onTimeout: () => throw const FirestoreUnavailable());

  @override
  Stream<List<CartItem>> watchCart(String uid) => _col(uid, 'cart')
      .orderBy('addedAt', descending: true)
      .snapshots()
      .map((s) => [for (final d in s.docs) CartItem.fromMap(d.id, d.data())]);

  @override
  Future<void> addToCart(String uid, CartItem item) => _confirmed(
        _col(uid, 'cart').doc(item.id).set(
              item.toMap()..['quantity'] = FieldValue.increment(item.quantity),
              SetOptions(merge: true),
            ),
      );

  @override
  Future<void> setCartQuantity(String uid, String itemId, int quantity) {
    if (quantity <= 0) return removeFromCart(uid, itemId);
    return _confirmed(_col(uid, 'cart').doc(itemId).update({'quantity': quantity}));
  }

  @override
  Future<void> removeFromCart(String uid, String itemId) =>
      _confirmed(_col(uid, 'cart').doc(itemId).delete());

  @override
  Stream<Set<String>> watchFavorites(String uid) =>
      _col(uid, 'favorites').snapshots().map((s) => {for (final d in s.docs) d.id});

  @override
  Future<void> setFavorite(String uid, String bikeId, bool favorite) {
    final doc = _col(uid, 'favorites').doc(bikeId);
    return _confirmed(favorite ? doc.set({'addedAt': DateTime.now().millisecondsSinceEpoch}) : doc.delete());
  }

  @override
  Stream<List<ShopOrder>> watchOrders(String uid) => _col(uid, 'orders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => [for (final d in s.docs) ShopOrder.fromMap(d.id, d.data())]);

  @override
  Future<String> placeOrder(String uid, ShopOrder order) async {
    final ref = _col(uid, 'orders').doc();
    final cart = await _confirmed(_col(uid, 'cart').get());
    final batch = _db.batch()..set(ref, order.toMap()..['userId'] = uid);
    for (final doc in cart.docs) {
      batch.delete(doc.reference);
    }
    await _confirmed(batch.commit());
    return ref.id;
  }

  @override
  Stream<List<TestRide>> watchTestRides(String uid) => _col(uid, 'testRides')
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => [for (final d in s.docs) TestRide.fromMap(d.id, d.data())]);

  @override
  Future<String> bookTestRide(String uid, TestRide ride) async {
    final ref = _col(uid, 'testRides').doc();
    await _confirmed(ref.set(ride.toMap()..['userId'] = uid));
    return ref.id;
  }

  @override
  Future<void> cancelTestRide(String uid, String rideId) =>
      _confirmed(_col(uid, 'testRides').doc(rideId).update({'status': 'cancelled'}));
}
