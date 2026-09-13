import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/motorcycle.dart';
import '../models/shop_order.dart';
import '../models/test_ride.dart';
import '../services/auth_service.dart';
import '../services/store_service.dart';

/// Signed-in user plus their live cart, favorites, orders and test rides.
class Session extends ChangeNotifier {
  Session({required this.auth, required this.store}) {
    _authSub = auth.authStateChanges().listen(_onAuthChanged, onError: (Object error) {
      debugPrint('Auth stream error: $error');
      ready = true;
      notifyListeners();
    });
  }

  final AuthService auth;
  final StoreService store;

  StreamSubscription<AppUser?>? _authSub;
  final List<StreamSubscription<Object?>> _dataSubs = [];
  final List<Timer> _retryTimers = [];
  final Map<String, String> _streamErrors = {};
  String? _writeError;

  /// Bumped whenever the signed-in user changes, so stale retries are ignored.
  int _generation = 0;

  bool ready = false;
  AppUser? user;
  List<CartItem> cart = const [];
  Set<String> favorites = const {};
  List<ShopOrder> orders = const [];
  List<TestRide> testRides = const [];

  String? get dataError => _writeError ?? (_streamErrors.isEmpty ? null : _streamErrors.values.first);

  int get cartCount => cart.fold(0, (sum, item) => sum + item.quantity);
  int get cartTotal => cart.fold(0, (sum, item) => sum + item.total);
  int get upcomingRideCount => testRides.where((r) => r.isUpcoming).length;

  String get _uid {
    final current = user;
    if (current == null) throw const AuthFailure('Please sign in first.');
    return current.uid;
  }

  void _onAuthChanged(AppUser? next) {
    final userChanged = next?.uid != user?.uid;
    user = next;
    ready = true;
    if (userChanged) _bindUserData();
    notifyListeners();
  }

  void _cancelDataSubscriptions() {
    _generation++;
    for (final sub in _dataSubs) {
      sub.cancel();
    }
    _dataSubs.clear();
    for (final timer in _retryTimers) {
      timer.cancel();
    }
    _retryTimers.clear();
  }

  void _bindUserData() {
    _cancelDataSubscriptions();
    _streamErrors.clear();
    _writeError = null;
    cart = const [];
    favorites = const {};
    orders = const [];
    testRides = const [];

    final uid = user?.uid;
    if (uid == null) return;
    _watch('cart', () => store.watchCart(uid), (v) => cart = v);
    _watch('favorites', () => store.watchFavorites(uid), (v) => favorites = v);
    _watch('orders', () => store.watchOrders(uid), (v) => orders = v);
    _watch('test rides', () => store.watchTestRides(uid), (v) => testRides = v);
  }

  /// A Firestore listener stops for good after an error (for example while
  /// newly published security rules are still propagating), so re-subscribe
  /// with backoff instead of leaving that list stuck empty.
  void _watch<T>(String name, Stream<T> Function() open, void Function(T value) apply, [int attempt = 0]) {
    final generation = _generation;
    late final StreamSubscription<T> sub;
    sub = open().listen(
      (value) {
        apply(value);
        _streamErrors.remove(name);
        _writeError = null;
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('Store stream error ($name): $error');
        _streamErrors[name] = 'Could not load $name: $error';
        _dataSubs.remove(sub);
        notifyListeners();
        final delay = Duration(seconds: math.min(30, 2 << math.min(attempt, 4)));
        _retryTimers.add(Timer(delay, () {
          if (generation == _generation) _watch(name, open, apply, attempt + 1);
        }));
      },
      cancelOnError: true,
    );
    _dataSubs.add(sub);
  }

  void _onWriteError(Object error) {
    debugPrint('Store write error: $error');
    _writeError = '$error';
    notifyListeners();
  }

  Future<void> addToCart(Motorcycle bike, BikeColor color) {
    final price = bike.priceThb;
    if (price == null) throw StateError('${bike.name} is not sold in Thailand');
    return store.addToCart(
      _uid,
      CartItem(
        id: CartItem.makeId(bike.id, color.name),
        bikeId: bike.id,
        bikeName: bike.name,
        colorName: color.name,
        colorValue: color.color.toARGB32(),
        unitPrice: price,
        imageUrl: bike.imageUrl,
        addedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> setQuantity(String itemId, int quantity) async {
    if (quantity <= 0) return removeFromCart(itemId);
    cart = [for (final item in cart) item.id == itemId ? item.copyWith(quantity: quantity) : item];
    notifyListeners();
    try {
      await store.setCartQuantity(_uid, itemId, quantity);
    } catch (error) {
      _onWriteError(error);
    }
  }

  /// Removes locally first so a dismissed list tile disappears immediately.
  Future<void> removeFromCart(String itemId) async {
    cart = cart.where((item) => item.id != itemId).toList();
    notifyListeners();
    try {
      await store.removeFromCart(_uid, itemId);
    } catch (error) {
      _onWriteError(error);
    }
  }

  Future<void> toggleFavorite(String bikeId) async {
    final makeFavorite = !favorites.contains(bikeId);
    favorites = makeFavorite ? {...favorites, bikeId} : ({...favorites}..remove(bikeId));
    notifyListeners();
    try {
      await store.setFavorite(_uid, bikeId, makeFavorite);
    } catch (error) {
      _onWriteError(error);
    }
  }

  Future<String> placeOrder(ShopOrder order) => store.placeOrder(_uid, order);

  Future<String> bookTestRide(TestRide ride) => store.bookTestRide(_uid, ride);

  Future<void> cancelTestRide(String rideId) => store.cancelTestRide(_uid, rideId);

  Future<void> signOut() => auth.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _cancelDataSubscriptions();
    super.dispose();
  }
}
