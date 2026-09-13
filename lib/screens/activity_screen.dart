import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shop_order.dart';
import '../models/test_ride.dart';
import '../state/catalog_provider.dart';
import '../state/session.dart';
import '../state/shell_controller.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/bike_image.dart';
import '../widgets/common.dart';
import 'test_ride_screen.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 13.5);
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Text(
                'Activity',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: TabBar(
                  indicator: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: labelStyle,
                  unselectedLabelStyle: labelStyle,
                  splashBorderRadius: BorderRadius.circular(14),
                  tabs: [
                    Tab(text: 'Orders · ${session.orders.length}'),
                    Tab(text: 'Test rides · ${session.testRides.length}'),
                  ],
                ),
              ),
            ),
            if (session.dataError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: ErrorCard(message: session.dataError!),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _OrdersTab(orders: session.orders),
                  _RidesTab(rides: session.testRides),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({required this.orders});

  final List<ShopOrder> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'No orders yet',
        message: 'Bikes you order will show up here with their status.',
        actionLabel: 'Shop bikes',
        onAction: () => context.read<ShellController>().openExplore(global: false),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
      itemCount: orders.length,
      separatorBuilder: (context, i) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _OrderCard(order: orders[i]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    final finance = order.plan == PaymentPlan.finance;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${shortReference(order.id)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                ),
              ),
              StatusPill(order.statusLabel, color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 4),
          Text(formatDate(order.createdAt), style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          const Divider(height: 24),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: Color(item.colorValue), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Suzuki ${item.bikeName} · ${item.colorName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text('×${item.quantity}', style: const TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: StatusRow(icon: Icons.storefront_outlined, text: order.dealerName)),
              const SizedBox(width: 8),
              Text(
                finance
                    ? '${formatThb(order.monthlyInstallment)}/mo × ${order.months}'
                    : formatThb(order.subtotal),
                style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RidesTab extends StatelessWidget {
  const _RidesTab({required this.rides});

  final List<TestRide> rides;

  @override
  Widget build(BuildContext context) {
    if (rides.isEmpty) {
      return EmptyState(
        icon: Icons.sports_motorsports_outlined,
        title: 'No test rides booked',
        message: 'Try a bike at a showroom near you before you buy.',
        actionLabel: 'Book a test ride',
        onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TestRideScreen())),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
      itemCount: rides.length,
      separatorBuilder: (context, i) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _RideCard(ride: rides[i]),
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({required this.ride});

  final TestRide ride;

  Future<void> _cancel(BuildContext context) async {
    final session = context.read<Session>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel test ride?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'Your ${ride.bikeName} ride on ${formatDate(ride.date)} will be released.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel ride', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await session.cancelTestRide(ride.id);
    } catch (e) {
      if (context.mounted) showAppSnack(context, 'Could not cancel: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bike = context.read<CatalogProvider>().byId(ride.bikeId);
    final imageUrl = ride.imageUrl;
    final (label, color) = ride.isCancelled
        ? ('CANCELLED', AppColors.red)
        : ride.isUpcoming
            ? ('CONFIRMED', AppColors.success)
            : ('COMPLETED', AppColors.textMuted);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 92,
              height: 108,
              child: bike != null
                  ? BikeImage(bike: bike, iconSize: 30)
                  : imageUrl != null
                      ? NetworkBikeImage(url: imageUrl, iconSize: 30)
                      : const BikeImagePlaceholder(iconSize: 30),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suzuki ${ride.bikeName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                ),
                const SizedBox(height: 6),
                StatusRow(icon: Icons.event_rounded, text: '${formatDate(ride.date)} · ${ride.timeSlot}'),
                const SizedBox(height: 4),
                StatusRow(icon: Icons.storefront_outlined, text: ride.dealerName),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatusPill(label, color: color),
                    const Spacer(),
                    if (ride.isUpcoming)
                      SizedBox(
                        height: 30,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () => _cancel(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
