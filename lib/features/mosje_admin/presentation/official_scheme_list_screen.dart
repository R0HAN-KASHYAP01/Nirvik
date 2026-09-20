import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'official_scheme_institute_list_screen.dart';

class OfficialSchemeListScreen extends StatefulWidget {
  final String selectedState;
  final String selectedDistrict;
  final String categoryKey;
  final String categoryTitle;

  const OfficialSchemeListScreen({
    super.key,
    required this.selectedState,
    required this.selectedDistrict,
    required this.categoryKey,
    required this.categoryTitle,
  });

  @override
  State<OfficialSchemeListScreen> createState() =>
      _OfficialSchemeListScreenState();
}

class _OfficialSchemeListScreenState
    extends State<OfficialSchemeListScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _schemes = [];
  List<Map<String, dynamic>> _filteredSchemes = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSchemes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rows = await Supabase.instance.client
          .from('scheme_catalog')
          .select('code, label, display_order')
          .eq('category', widget.categoryKey)
          .order('display_order', ascending: true);

      final schemes = rows
          .map<Map<String, dynamic>>(
            (row) => Map<String, dynamic>.from(row),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _schemes = schemes;
        _filteredSchemes = List<Map<String, dynamic>>.from(schemes);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load schemes.';
        _isLoading = false;
      });

      debugPrint('OFFICIAL SCHEMES - SCHEME LOAD ERROR: $e');
    }
  }

  void _filterSchemes(String value) {
    final query = value.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredSchemes =
            List<Map<String, dynamic>>.from(_schemes);
        return;
      }

      _filteredSchemes = _schemes.where((scheme) {
        final label = scheme['label']?.toString().toLowerCase() ?? '';
        final code = scheme['code']?.toString().toLowerCase() ?? '';

        return label.contains(query) || code.contains(query);
      }).toList();
    });
  }

  void _openInstitutes(Map<String, dynamic> scheme) {
    final schemeCode = scheme['code']?.toString() ?? '';
    final schemeLabel = scheme['label']?.toString() ?? schemeCode;

    if (schemeCode.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OfficialSchemeInstituteListScreen(
          selectedState: widget.selectedState,
          selectedDistrict: widget.selectedDistrict,
          categoryKey: widget.categoryKey,
          categoryTitle: widget.categoryTitle,
          schemeCode: schemeCode,
          schemeLabel: schemeLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Scheme'),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadSchemes,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _buildSelectionHeader(),
          const SizedBox(height: 20),
          _buildSearchBox(),
          const SizedBox(height: 20),
          _buildSchemeCount(),
          const SizedBox(height: 12),
          if (_filteredSchemes.isEmpty)
            _buildEmptyState()
          else
            ..._filteredSchemes.asMap().entries.map(
              (entry) => _buildSchemeCard(
                entry.key,
                entry.value,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionHeader() {
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
                Icons.account_balance_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Available Schemes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _selectionRow(
            Icons.location_on_outlined,
            'State',
            widget.selectedState,
          ),
          const SizedBox(height: 9),
          _selectionRow(
            Icons.location_city_outlined,
            'District',
            widget.selectedDistrict,
          ),
          const SizedBox(height: 9),
          _selectionRow(
            Icons.category_outlined,
            'Category',
            widget.categoryTitle,
          ),
        ],
      ),
    );
  }

  Widget _selectionRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
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

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      onChanged: _filterSchemes,
      decoration: InputDecoration(
        hintText: 'Search scheme',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _filterSchemes('');
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

  Widget _buildSchemeCount() {
    final count = _filteredSchemes.length;

    return Text(
      '$count scheme${count == 1 ? '' : 's'} available',
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildSchemeCard(
    int index,
    Map<String, dynamic> scheme,
  ) {
    final code = scheme['code']?.toString() ?? '';
    final label = scheme['label']?.toString() ?? code;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openInstitutes(scheme),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (code.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        code,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 54,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 14),
          Text(
            'No schemes found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'No schemes are currently available for this category.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 52,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 14),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadSchemes,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}