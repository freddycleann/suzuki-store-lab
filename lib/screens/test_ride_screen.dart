import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/dealers.dart';
import '../models/dealer.dart';
import '../models/motorcycle.dart';
import '../models/test_ride.dart';
import '../state/catalog_provider.dart';
import '../state/session.dart';
import '../state/shell_controller.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/bike_image.dart';
import '../widgets/common.dart';
import '../widgets/dealer_option.dart';
import 'success_screen.dart';

class TestRideScreen extends StatefulWidget {
  const TestRideScreen({super.key, this.bike, this.dealer});

  final Motorcycle? bike;
  final Dealer? dealer;

  @override
  State<TestRideScreen> createState() => _TestRideScreenState();
}

class _TestRideScreenState extends State<TestRideScreen> {
  static const _slots = ['10:00', '11:00', '13:00', '14:00', '15:00', '16:30'];

  final _phone = TextEditingController();
  final _note = TextEditingController();
  late final List<DateTime> _days;
  Motorcycle? _bike;
  Dealer? _dealer;
  late DateTime _day;
  String? _slot;
  bool _licensed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bike = widget.bike;
    _dealer = widget.dealer;
    final now = DateTime.now();
    _days = [for (var i = 1; i <= 14; i++) DateTime(now.year, now.month, now.day + i)];
    _day = _days.first;
  }

  @override
  void dispose() {
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final bike = _bike;
    final dealer = _dealer;
    final slot = _slot;
    if (bike == null) {
      showAppSnack(context, 'Choose the bike you want to ride', error: true);
      return;
    }
    if (dealer == null) {
      showAppSnack(context, 'Pick a showroom', error: true);
      return;
    }
    if (slot == null) {
      showAppSnack(context, 'Pick a time slot', error: true);
      return;
    }
    if (validatePhone(_phone.text) != null) {
      showAppSnack(context, 'Enter a valid Thai mobile number', error: true);
      return;
    }
    if (bike.isBigBike && !_licensed) {
      showAppSnack(context, 'Big bikes require a valid motorcycle licence', error: true);
      return;
    }

    final parts = slot.split(':');
    final date = DateTime(_day.year, _day.month, _day.day, int.parse(parts[0]), int.parse(parts[1]));
    final session = context.read<Session>();
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final id = await session.bookTestRide(
        TestRide(
          bikeId: bike.id,
          bikeName: bike.name,
          imageUrl: bike.imageUrl,
          dealerId: dealer.id,
          dealerName: dealer.name,
          date: date,
          timeSlot: slot,
          phone: _phone.text.trim(),
          note: _note.text.trim(),
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            title: 'Test ride booked!',
            message: '${bike.fullName}\n${dealer.name}\n${formatDate(date)} · $slot',
            reference: shortReference(id),
            primaryLabel: 'View my bookings',
            primaryTab: ShellController.activity,
          ),
        ),
      );
    } catch (e) {
      if (mounted) showAppSnack(context, 'Booking failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final preselected = widget.bike;
    final bikes = [
      if (preselected != null) catalog.byId(preselected.id) ?? preselected,
      ...catalog.thaiBikes.where((b) => b.id != preselected?.id),
    ];

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 72,
        leading: const Padding(padding: EdgeInsets.only(left: 20), child: Center(child: BackButtonCircle())),
        title: const Text('Book a test ride'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _StepTitle(step: 1, title: 'Choose your bike'),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: bikes.length,
              separatorBuilder: (context, i) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final bike = bikes[i];
                return _BikeOption(
                  bike: bike,
                  selected: bike.id == _bike?.id,
                  onTap: () => setState(() => _bike = bike),
                );
              },
            ),
          ),
          const _StepTitle(step: 2, title: 'Pick a showroom'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (final dealer in Dealers.all)
                  DealerOption(
                    dealer: dealer,
                    selected: dealer.id == _dealer?.id,
                    onTap: () => setState(() => _dealer = dealer),
                  ),
              ],
            ),
          ),
          const _StepTitle(step: 3, title: 'Date & time'),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _days.length,
              separatorBuilder: (context, i) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final day = _days[i];
                final selected = DateUtils.isSameDay(day, _day);
                final subtle = selected ? Colors.white70 : AppColors.textMuted;
                return GestureDetector(
                  onTap: () => setState(() => _day = day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.stroke),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(day),
                          style: TextStyle(fontSize: 12, color: subtle, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text('${day.day}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        Text(DateFormat('MMM').format(day), style: TextStyle(fontSize: 11, color: subtle)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final slot in _slots)
                  GestureDetector(
                    onTap: () => setState(() => _slot = slot),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: slot == _slot ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: slot == _slot ? AppColors.primary : AppColors.stroke),
                      ),
                      child: Text(slot, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
          const _StepTitle(step: 4, title: 'Your details'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                AppTextField(
                  controller: _phone,
                  hint: 'Mobile number, e.g. 081 234 5678',
                  icon: Icons.phone_iphone_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _note,
                  hint: 'Notes for the showroom (optional)',
                  icon: Icons.edit_note_rounded,
                  maxLines: 3,
                ),
                if (_bike?.isBigBike ?? false) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _licensed,
                    onChanged: (v) => setState(() => _licensed = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'I hold a valid Thai motorcycle driving licence',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: PrimaryButton(
            label: 'Confirm booking',
            icon: Icons.event_available_rounded,
            loading: _saving,
            onPressed: _submit,
          ),
        ),
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.step, required this.title});

  final int step;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
            child: Text('$step', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _BikeOption extends StatelessWidget {
  const _BikeOption({required this.bike, required this.selected, required this.onTap});

  final Motorcycle bike;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? AppColors.primary : AppColors.stroke, width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BikeImage(bike: bike, iconSize: 32),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bike.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  Text(bike.category.label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
