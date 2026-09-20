import 'package:flutter/material.dart';

import 'official_scheme_list_screen.dart';

class OfficialSchemeCategoryScreen extends StatelessWidget {
  final String selectedState;
  final String selectedDistrict;

  const OfficialSchemeCategoryScreen({
    super.key,
    required this.selectedState,
    required this.selectedDistrict,
  });

  static const List<_OfficialCategory> _categories = [
    _OfficialCategory(
      key: 'educational',
      title: 'Educational',
      subtitle: 'Scholarships and education schemes',
      icon: Icons.school_outlined,
    ),
    _OfficialCategory(
      key: 'social_empowerment',
      title: 'Social Empowerment',
      subtitle: 'Social welfare and empowerment schemes',
      icon: Icons.diversity_3_outlined,
    ),
    _OfficialCategory(
      key: 'economic_development',
      title: 'Economic Development',
      subtitle: 'Livelihood and economic schemes',
      icon: Icons.trending_up_outlined,
    ),
  ];

  void _openSchemes(
    BuildContext context,
    _OfficialCategory category,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OfficialSchemeListScreen(
          selectedState: selectedState,
          selectedDistrict: selectedDistrict,
          categoryKey: category.key,
          categoryTitle: category.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Category'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            _buildSelectionHeader(context),
            const SizedBox(height: 24),
            Text(
              'Scheme Categories',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            ..._categories.map(
              (category) => _buildCategoryCard(
                context,
                category,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Choose Scheme Category',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSelectionRow(
            context,
            Icons.location_on_outlined,
            'State',
            selectedState,
          ),
          const SizedBox(height: 10),
          _buildSelectionRow(
            context,
            Icons.location_city_outlined,
            'District',
            selectedDistrict,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    _OfficialCategory category,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openSchemes(context, category),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  category.icon,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      category.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfficialCategory {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;

  const _OfficialCategory({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}