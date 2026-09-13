import 'package:flutter/material.dart';

import '../models/dealer.dart';
import '../theme/app_theme.dart';
import 'common.dart';

class DealerOption extends StatelessWidget {
  const DealerOption({super.key, required this.dealer, required this.selected, required this.onTap});

  final Dealer dealer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.stroke, width: selected ? 1.6 : 1),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: AppColors.primaryBright),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dealer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${dealer.address} · ${dealer.hours}',
                        maxLines: 2,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      if (dealer.bigBikeCenter) ...[
                        const SizedBox(height: 8),
                        const StatusPill('BIG BIKE CENTER', color: AppColors.warning),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
