import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../state/catalog_provider.dart';
import '../state/session.dart';
import '../state/shell_controller.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/bike_image.dart';
import '../widgets/common.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final items = session.cart;
    final count = session.cartCount;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                const Text(
                  'My Cart',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                ),
                const SizedBox(width: 12),
                if (items.isNotEmpty) StatusPill('$count ${count == 1 ? 'BIKE' : 'BIKES'}'),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Your cart is empty',
                    message: 'Browse the Suzuki lineup and add your next ride.',
                    actionLabel: 'Explore bikes',
                    onAction: () => context.read<ShellController>().openExplore(global: false),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => session.removeFromCart(item.id),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: AppColors.red.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
                            ),
                            child: _CartTile(item: item),
                          ),
                        ),
                      const SizedBox(height: 6),
                      _Summary(subtotal: session.cartTotal),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: 'Checkout · ${formatThb(session.cartTotal)}',
                        icon: Icons.lock_outline_rounded,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Swipe a bike left to remove it',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final session = context.read<Session>();
    final bike = context.read<CatalogProvider>().byId(item.bikeId);
    final imageUrl = item.imageUrl;
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
              width: 100,
              height: 92,
              child: bike != null
                  ? BikeImage(bike: bike, iconSize: 32)
                  : imageUrl != null
                      ? NetworkBikeImage(url: imageUrl, iconSize: 32)
                      : const BikeImagePlaceholder(iconSize: 32),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.bikeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: Color(item.colorValue),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.colorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  formatThb(item.total),
                  style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w800, fontSize: 15.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              _StepButton(
                icon: Icons.add_rounded,
                onTap: () => session.setQuantity(item.id, item.quantity + 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              _StepButton(
                icon: item.quantity == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                onTap: () => session.setQuantity(item.id, item.quantity - 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    return Material(
      color: AppColors.surfaceHigh,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: SizedBox(width: 30, height: 30, child: Icon(icon, size: 17)),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.subtotal});

  final int subtotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        children: [
          SummaryRow(label: 'Subtotal', value: formatThb(subtotal)),
          const SummaryRow(label: 'Registration & plate', value: 'Included'),
          const SummaryRow(label: 'Delivery', value: 'Pick up at showroom'),
          const Divider(height: 24),
          SummaryRow(label: 'Total', value: formatThb(subtotal), emphasize: true),
        ],
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.label, required this.value, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasize ? AppColors.text : AppColors.textMuted,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
                fontSize: emphasize ? 16 : 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700, fontSize: emphasize ? 19 : 14),
          ),
        ],
      ),
    );
  }
}
