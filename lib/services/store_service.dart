import '../models/cart_item.dart';
import '../models/shop_order.dart';
import '../models/test_ride.dart';

/// Per-user shop data: cart, favorites, orders and test-ride bookings.
abstract class StoreService {
  Stream<List<CartItem>> watchCart(String uid);

  Future<void> addToCart(String uid, CartItem item);

  Future<void> setCartQuantity(String uid, String itemId, int quantity);

  Future<void> removeFromCart(String uid, String itemId);

  Stream<Set<String>> watchFavorites(String uid);

  Future<void> setFavorite(String uid, String bikeId, bool favorite);

  Stream<List<ShopOrder>> watchOrders(String uid);

  /// Saves the order and empties the cart. Returns the order id.
  Future<String> placeOrder(String uid, ShopOrder order);

  Stream<List<TestRide>> watchTestRides(String uid);

  Future<String> bookTestRide(String uid, TestRide ride);

  Future<void> cancelTestRide(String uid, String rideId);
}
