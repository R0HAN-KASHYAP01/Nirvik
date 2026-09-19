// lib/features/state_admin/presentation/state_district_selection_screen.dart
//
// Step 0 of the State Admin "Schemes" flow: pick a district of the
// admin's state (or "All Districts" to see every institute in the state)
// before narrowing down by category and scheme. This is the entry point
// pushed from the dashboard's Schemes nav item — everything after this
// screen (category -> scheme -> institutes) carries the chosen district
// forward instead of asking for it again.

import 'package:flutter/material.dart';

import 'state_institute_category_screen.dart';

const String kAllDistricts = 'All Districts';

class StateDistrictSelectionScreen extends StatefulWidget {
  final String adminState;
  final List<String> districts;

  const StateDistrictSelectionScreen({
    super.key,
    required this.adminState,
    required this.districts,
  });

  @override
  State<StateDistrictSelectionScreen> createState() =>
      _StateDistrictSelectionScreenState();
}

class _StateDistrictSelectionScreenState
    extends State<StateDistrictSelectionScreen> {
  static const Color _background = Color(0xFFEAF2F8);
  static const Color _border = Color(0xFFD1DEE7);
  static const Color _textGrey = Color(0xFF667788);

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredDistricts {
    if (_query.trim().isEmpty) return widget.districts;
    final q = _query.trim().toLowerCase();
    return widget.districts
        .where((d) => d.toLowerCase().contains(q))
        .toList();
  }

  void _selectDistrict(String district) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StateInstituteCategoryScreen(
          adminState: widget.adminState,
          selectedDistrict: district,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDistricts;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(title: const Text('Schemes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Text(
              'Select a district of ${widget.adminState} to view its '
              'institutes, or choose All Districts for the whole state.',
              style: const TextStyle(fontSize: 13, color: _textGrey),
            ),
          ),
          if (widget.districts.length > 8)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search districts',
                    hintStyle: TextStyle(fontSize: 13, color: _textGrey),
                    prefixIcon: Icon(Icons.search, color: _textGrey, size: 20),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
              children: [
                if (_query.trim().isEmpty)
                  _DistrictTile(
                    title: kAllDistricts,
                    subtitle: 'Every institute across ${widget.adminState}',
                    icon: Icons.public_outlined,
                    onTap: () => _selectDistrict(kAllDistricts),
                  ),
                if (_query.trim().isEmpty) const SizedBox(height: 10),
                for (final district in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DistrictTile(
                      title: district,
                      subtitle: widget.adminState,
                      icon: Icons.location_on_outlined,
                      onTap: () => _selectDistrict(district),
                    ),
                  ),
                if (filtered.isEmpty && _query.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Center(
                      child: Text(
                        'No districts match "$_query".',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textGrey,
                        ),
                      ),
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

class _DistrictTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DistrictTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  static const Color _border = Color(0xFFD1DEE7);
  static const Color _textGrey = Color(0xFF667788);
  static const Color _primaryBlue = Color(0xFF14568A);

  @override
  Widget build(BuildContext context) {
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
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11.5, color: _textGrey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _textGrey),
            ],
          ),
        ),
      ),
    );
  }
}