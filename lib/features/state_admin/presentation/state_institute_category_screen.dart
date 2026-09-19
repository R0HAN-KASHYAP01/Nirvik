// lib/features/state_admin/presentation/state_institute_category_screen.dart
//
// Step 2 of the State Admin "Schemes" flow (district is step 1, see
// StateDistrictSelectionScreen): pick a category. Same three category
// keys as District Admin's InstituteCategoryScreen (they match
// scheme_catalog.category in Supabase exactly), reused here so both
// flows stay in sync if a category is ever added.
//
// The district chosen in step 1 (or "All Districts") is carried forward
// from here through scheme selection to the final institute list, so it
// is only ever asked for once.

import 'package:flutter/material.dart';

import 'state_institute_scheme_list_screen.dart';

class StateInstituteCategoryScreen extends StatelessWidget {
  final String adminState;
  final String selectedDistrict;

  const StateInstituteCategoryScreen({
    super.key,
    required this.adminState,
    required this.selectedDistrict,
  });

  static const Color _background = Color(0xFFEAF2F8);
  static const Color _border = Color(0xFFD1DEE7);
  static const Color _textGrey = Color(0xFF667788);

  static const List<_Category> _categories = [
    _Category(
      key: 'educational',
      title: 'Educational',
      subtitle: 'Scholarships and education schemes',
      icon: Icons.school_outlined,
    ),
    _Category(
      key: 'social_empowerment',
      title: 'Social Empowerment',
      subtitle: 'Social welfare and empowerment schemes',
      icon: Icons.diversity_3_outlined,
    ),
    _Category(
      key: 'economic_development',
      title: 'Economic Development',
      subtitle: 'Livelihood and economic schemes',
      icon: Icons.trending_up_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(title: const Text('Schemes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          Text(
            selectedDistrict == 'All Districts'
                ? 'Select a category · institutes across $adminState'
                : 'Select a category · institutes in $selectedDistrict, '
                    '$adminState',
            style: const TextStyle(fontSize: 13, color: _textGrey),
          ),
          const SizedBox(height: 10),
          for (final c in _categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CategoryTile(
                category: c,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StateInstituteSchemeListScreen(
                      categoryKey: c.key,
                      categoryTitle: c.title,
                      adminState: adminState,
                      selectedDistrict: selectedDistrict,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Category {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;

  const _Category({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _CategoryTile extends StatelessWidget {
  final _Category category;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: StateInstituteCategoryScreen._border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(category.icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: StateInstituteCategoryScreen._textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: StateInstituteCategoryScreen._textGrey),
            ],
          ),
        ),
      ),
    );
  }
}