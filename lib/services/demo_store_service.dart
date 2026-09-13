import 'dart:async';

import '../models/cart_item.dart';
import '../models/shop_order.dart';
import '../models/test_ride.dart';
import 'store_service.dart';

/// In-memory store used in demo mode (no Firebase keys configured).
class DemoStoreService implements StoreService {
  final _carts = <String, _Live<List<CartItem>>>{};
  final _favorites = <String, _Live<Set<String>>>{};
  final _orders = <String, _Live<List<ShopOrder>>>{};
  final _rides = <String, _Live<List<TestRide>>>{};

  _Live<List<CartItem>> _cart(String uid) => _carts.putIfAbsent(uid, () => _Live(const []));
  _Live<Set<String>> _favs(String uid) => _favorites.putIfAbsent(uid, () => _Live(const {}));
  _Live<List<ShopOrder>> _ord(String uid) => _orders.putIfAbsent(uid, () => _Live(const []));
  _Live<List<TestRide>> _ride(String uid) => _rides.putIfAbsent(uid, () => _Live(const []));

  Future<void> _latency() => Future<void>.delayed(const Duration(milliseconds: 350));

  @override
  Stream<List<CartItem>> watchCart(String uid) => _cart(uid).stream;

  @override
  Future<void> addToCart(String uid, CartItem item) async {
    await _latency();
    final live = _cart(uid);
    final items = [...live.value];
    final index = items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + item.quantity);
    } else {
      items.insert(0, item);
    }
    live.update(items);
  }

  @override
  Future<void> setCartQuantity(String uid, String itemId, int quantity) async {
    if (quantity <= 0) return removeFromCart(uid, itemId);
    final live = _cart(uid);
    live.update([for (final i in live.value) i.id == itemId ? i.copyWith(quantity: quantity) : i]);
  }

  @override
  Future<void> removeFromCart(String uid, String itemId) async {
    final live = _cart(uid);
    live.update(live.value.where((i) => i.id != itemId).toList());
  }

  @override
  Stream<Set<String>> watchFavorites(String uid) => _favs(uid).stream;

  @override
  Future<void> setFavorite(String uid, String bikeId, bool favorite) async {
    final live = _favs(uid);
    live.update(favorite ? {...live.value, bikeId} : ({...live.value}..remove(bikeId)));
  }

  @override
  Stream<List<ShopOrder>> watchOrders(String uid) => _ord(uid).stream;

  @override
  Future<String> placeOrder(String uid, ShopOrder order) async {
    await _latency();
    final id = 'SZ${DateTime.now().millisecondsSinceEpoch}';
    final live = _ord(uid);
    live.update([order.copyWith(id: id), ...live.value]);
    _cart(uid).update(const []);
    return id;
  }

  @override
  Stream<List<TestRide>> watchTestRides(String uid) => _ride(uid).stream;

  @override
  Future<String> bookTestRide(String uid, TestRide ride) async {
    await _latency();
    final id = 'TR${DateTime.now().millisecondsSinceEpoch}';
    final live = _ride(uid);
    live.update([ride.copyWith(id: id), ...live.value]..sort((a, b) => b.date.compareTo(a.date)));
    return id;
  }

  @override
  Future<void> cancelTestRide(String uid, String rideId) async {
    final live = _ride(uid);
    live.update([for (final r in live.value) r.id == rideId ? r.copyWith(status: 'cancelled') : r]);
  }
}

/// A value that replays its latest state to every new listener.
class _Live<T> {
  _Live(this.value);

  T value;
  final _controller = StreamController<T>.broadcast();

  Stream<T> get stream async* {
    yield value;
    yield* _controller.stream;
  }

  void update(T next) {
    value = next;
    _controller.add(next);
  }
}
