import 'package:flutter/material.dart';

import '../../../utils/india_locations.dart';
import 'official_scheme_category_screen.dart';

const String kOfficialAllDistricts = 'All Districts';

class OfficialSchemeDistrictScreen extends StatefulWidget {
  final String selectedState;

  const OfficialSchemeDistrictScreen({
    super.key,
    required this.selectedState,
  });

  @override
  State<OfficialSchemeDistrictScreen> createState() =>
      _OfficialSchemeDistrictScreenState();
}

class _OfficialSchemeDistrictScreenState
    extends State<OfficialSchemeDistrictScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<String> _districts = [];
  List<String> _filteredDistricts = [];

  @override
  void initState() {
    super.initState();
    _loadDistricts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadDistricts() {
    final districts = districtsForState(widget.selectedState).toList()
      ..sort();

    setState(() {
      _districts = districts;
      _filteredDistricts = List<String>.from(districts);
    });
  }

  void _filterDistricts(String value) {
    final query = value.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredDistricts = List<String>.from(_districts);
      } else {
        _filteredDistricts = _districts
            .where(
              (district) => district.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  void _openCategory(String district) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OfficialSchemeCategoryScreen(
          selectedState: widget.selectedState,
          selectedDistrict: district,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select District'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            _buildStateHeader(),
            const SizedBox(height: 20),
            _buildSearchBox(),
            const SizedBox(height: 20),
            _buildDistrictCount(),
            const SizedBox(height: 12),

            // All Districts option.
            _buildAllDistrictsCard(),

            if (_filteredDistricts.isEmpty)
              _buildNoResults()
            else
              ..._filteredDistricts.map(_buildDistrictCard),
          ],
        ),
      ),
    );
  }

  Widget _buildStateHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 34,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedState,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a district to continue to scheme categories.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      onChanged: _filterDistricts,
      decoration: InputDecoration(
        hintText: 'Search district',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _filterDistricts('');
                },
                icon: const Icon(Icons.clear),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildDistrictCount() {
    return Text(
      '${_filteredDistricts.length} district${_filteredDistricts.length == 1 ? '' : 's'}',
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildAllDistrictsCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openCategory(kOfficialAllDistricts),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 17,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.map_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kOfficialAllDistricts,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'View approved institutes across the selected state',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictCard(String district) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openCategory(district),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 17,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_city_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  district,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'No matching district found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Try another district name.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}