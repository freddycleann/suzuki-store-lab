import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dealers.dart';
import '../models/dealer.dart';
import '../models/shop_order.dart';
import '../state/session.dart';
import '../state/shell_controller.dart';
import '../theme/app_theme.dart';
import '../utils/finance.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/dealer_option.dart';
import 'cart_screen.dart';
import 'success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _phone = TextEditingController();
  PaymentPlan _plan = PaymentPlan.full;
  double _down = 0.25;
  int _months = 48;
  Dealer _dealer = Dealers.all.first;
  bool _placing = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _place() async {
    FocusScope.of(context).unfocus();
    final session = context.read<Session>();
    final navigator = Navigator.of(context);
    final items = session.cart;
    if (items.isEmpty) {
      showAppSnack(context, 'Your cart is empty', error: true);
      return;
    }
    if (validatePhone(_phone.text) != null) {
      showAppSnack(context, 'Enter a valid mobile number so the showroom can reach you', error: true);
      return;
    }
    final subtotal = session.cartTotal;
    final finance = _plan == PaymentPlan.finance;
    final dealer = _dealer;
    final order = ShopOrder(
      items: items,
      subtotal: subtotal,
      plan: _plan,
      downPayment: finance ? Finance.downPayment(subtotal, _down) : subtotal,
      months: finance ? _months : 0,
      monthlyInstallment: finance ? Finance.monthly(price: subtotal, downPercent: _down, months: _months) : 0,
      dealerId: dealer.id,
      dealerName: dealer.name,
      phone: _phone.text.trim(),
      createdAt: DateTime.now(),
    );

    setState(() => _placing = true);
    try {
      final id = await session.placeOrder(order);
      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            title: 'Order placed!',
            message: '${dealer.name} will call you within 24 hours to confirm paperwork, '
                'registration and delivery.',
            reference: shortReference(id),
            primaryLabel: 'Track my order',
            primaryTab: ShellController.activity,
          ),
        ),
      );
    } catch (e) {
      if (mounted) showAppSnack(context, 'Could not place order: $e', error: true);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final subtotal = session.cartTotal;
    final finance = _plan == PaymentPlan.finance;
    final down = Finance.downPayment(subtotal, _down);
    final monthly = subtotal == 0 ? 0 : Finance.monthly(price: subtotal, downPercent: _down, months: _months);
    final card = BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.stroke),
    );

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 72,
        leading: const Padding(padding: EdgeInsets.only(left: 20), child: Center(child: BackButtonCircle())),
        title: const Text('Checkout'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const _Title('Order summary'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: card,
            child: Column(
              children: [
                for (final item in session.cart)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
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
                            '${item.bikeName} · ${item.colorName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        Text('×${item.quantity}', style: const TextStyle(color: AppColors.textMuted)),
                        const SizedBox(width: 12),
                        Text(formatThb(item.total), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const _Title('Payment plan'),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _PlanCard(
                    icon: Icons.payments_rounded,
                    title: 'Pay in full',
                    subtitle: 'Cash or bank transfer at the showroom',
                    selected: !finance,
                    onTap: () => setState(() => _plan = PaymentPlan.full),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PlanCard(
                    icon: Icons.account_balance_rounded,
                    title: 'Suzuki Finance',
                    subtitle: '${(Finance.ratePerYear * 100).toStringAsFixed(2)}% flat rate per year',
                    selected: finance,
                    onTap: () => setState(() => _plan = PaymentPlan.finance),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !finance
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      decoration: card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Down payment', style: TextStyle(fontWeight: FontWeight.w700)),
                              const Spacer(),
                              Text(
                                '${(_down * 100).round()}% · ${formatThb(down)}',
                                style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Slider(
                            value: _down,
                            min: 0.1,
                            max: 0.5,
                            divisions: 8,
                            onChanged: (v) => setState(() => _down = v),
                          ),
                          const Text('Term', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final months in Finance.termOptions)
                                GestureDetector(
                                  onTap: () => setState(() => _months = months),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: months == _months ? AppColors.primary : AppColors.surfaceHigh,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      '$months mo',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Divider(height: 30),
                          Row(
                            children: [
                              const Expanded(
                                child: Text('Monthly installment', style: TextStyle(color: AppColors.textMuted)),
                              ),
                              Text(
                                formatThb(monthly),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Illustrative estimate. Final finance terms are confirmed by the showroom.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const _Title('Pick-up showroom'),
          for (final dealer in Dealers.all)
            DealerOption(
              dealer: dealer,
              selected: dealer.id == _dealer.id,
              onTap: () => setState(() => _dealer = dealer),
            ),
          const _Title('Contact'),
          AppTextField(
            controller: _phone,
            hint: 'Mobile number, e.g. 081 234 5678',
            icon: Icons.phone_iphone_rounded,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, -6))],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SummaryRow(label: 'Total', value: formatThb(subtotal), emphasize: true),
                if (finance) SummaryRow(label: 'Due at showroom (down payment)', value: formatThb(down)),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: finance ? 'Apply & place order' : 'Place order',
                  icon: Icons.check_rounded,
                  loading: _placing,
                  onPressed: _place,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? AppColors.primary : AppColors.stroke, width: selected ? 1.6 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: selected ? AppColors.primaryBright : AppColors.textMuted),
                const Spacer(),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.35)),
          ],
        ),
      ),
    );
  }
}
