import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/motorcycle.dart';
import '../state/catalog_provider.dart';
import '../state/shell_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/bike_cards.dart';
import '../widgets/common.dart';
import 'bike_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  String _query = '';
  BikeCategory? _category;
  SortMode _sort = SortMode.featured;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickSort() async {
    final picked = await showModalBottomSheet<SortMode>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sort by', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final mode in SortMode.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(mode.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: mode == _sort ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                  onTap: () => Navigator.pop(context, mode),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _sort = picked);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final shell = context.watch<ShellController>();
    final global = shell.exploreGlobal;
    final year = catalog.lineupYear ?? DateTime.now().year;
    final results = catalog.search(query: _query, category: _category, global: global, sort: _sort);

    final Widget content;
    if (global && catalog.loadingLineup && catalog.globalBikes.isEmpty) {
      content = const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else if (global && catalog.lineupError != null && catalog.globalBikes.isEmpty) {
      content = SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ErrorCard(message: catalog.lineupError!, onRetry: catalog.loadLineup),
        ),
      );
    } else if (results.isEmpty) {
      content = const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'No bikes found',
          message: 'Try another model name or category.',
        ),
      );
    } else {
      content = SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.68,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final bike = results[i];
              final tag = 'explore-${bike.id}';
              return BikeGridCard(
                bike: bike,
                heroTag: tag,
                onTap: () => BikeDetailScreen.open(context, bike, heroTag: tag),
              );
            },
            childCount: results.length,
          ),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Explore',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                    ),
                  ),
                  CircleIconButton(icon: Icons.swap_vert_rounded, onTap: _pickSort),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: AppTextField(
                controller: _search,
                hint: 'Search models',
                icon: Icons.search_rounded,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                suffix: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: SegmentedTabs(
                labels: ['Thailand · ${catalog.thaiBikes.length}', 'Global $year · API'],
                index: global ? 1 : 0,
                onChanged: (i) {
                  setState(() => _category = null);
                  shell.setExploreGlobal(i == 1);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: CategoryChips(
                selected: _category,
                onSelected: (c) => setState(() => _category = c),
                categories: global ? BikeCategory.values : CategoryChips.thaiCategories,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Text(
                global
                    ? '${results.length} models · Suzuki $year motorcycle lineup from NHTSA vPIC'
                    : '${results.length} models · ${_sort.label}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
              ),
            ),
          ),
          content,
        ],
      ),
    );
  }
}
