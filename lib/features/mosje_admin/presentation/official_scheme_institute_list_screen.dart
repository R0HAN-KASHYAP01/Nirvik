import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfficialSchemeInstituteListScreen extends StatefulWidget {
  final String selectedState;
  final String selectedDistrict;
  final String categoryKey;
  final String categoryTitle;
  final String schemeCode;
  final String schemeLabel;

  const OfficialSchemeInstituteListScreen({
    super.key,
    required this.selectedState,
    required this.selectedDistrict,
    required this.categoryKey,
    required this.categoryTitle,
    required this.schemeCode,
    required this.schemeLabel,
  });

  @override
  State<OfficialSchemeInstituteListScreen> createState() =>
      _OfficialSchemeInstituteListScreenState();
}

class _OfficialSchemeInstituteListScreenState
    extends State<OfficialSchemeInstituteListScreen> {
  List<Map<String, dynamic>> _institutes = [];

  bool _isLoading = true;
  String? _error;

  static const String _allDistricts = 'All Districts';

  @override
  void initState() {
    super.initState();
    _loadInstitutes();
  }

  Future<void> _loadInstitutes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      var query = Supabase.instance.client
          .from('institute_reps')
          .select(
            'profile_id, organization_name, registration_number, '
            'organization_type, complete_address, district, state, '
            'pin_code, representative_name, designation, mobile_number, '
            'official_email',
          )
          .eq('scheme_category', widget.categoryKey)
          .eq('scheme_code', widget.schemeCode)
          .ilike('state', _escapeLike(widget.selectedState));

      if (widget.selectedDistrict != _allDistricts) {
        query = query.ilike(
          'district',
          _escapeLike(widget.selectedDistrict),
        );
      }

      final rows = await query
          .not('reviewed_at', 'is', null)
          .isFilter('rejection_reason', null)
          .order('district', ascending: true)
          .order('organization_name', ascending: true);

      final institutes = rows
          .map<Map<String, dynamic>>(
            (row) => Map<String, dynamic>.from(row),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _institutes = institutes;
        _isLoading = false;
      });

      debugPrint(
        'OFFICIAL SCHEMES - INSTITUTES: ${institutes.length}',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load approved institutes.';
        _isLoading = false;
      });

      debugPrint(
        'OFFICIAL SCHEMES - INSTITUTE LOAD ERROR: $e',
      );
    }
  }

  String _escapeLike(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approved Institutes'),
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
      onRefresh: _loadInstitutes,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _buildSelectionHeader(),
          const SizedBox(height: 20),
          _buildResultSummary(),
          const SizedBox(height: 14),
          if (_institutes.isEmpty)
            _buildEmptyState()
          else
            ..._institutes.map(_buildInstituteCard),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Approved Institutes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
          const SizedBox(height: 9),
          _selectionRow(
            Icons.account_balance_outlined,
            'Scheme',
            widget.schemeLabel,
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

  Widget _buildResultSummary() {
    final count = _institutes.length;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.business_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count approved institute${count == 1 ? '' : 's'} found',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstituteCard(Map<String, dynamic> institute) {
    final organizationName =
        _value(institute['organization_name'], 'Unnamed Institute');

    final registrationNumber =
        _value(institute['registration_number']);

    final organizationType =
        _value(institute['organization_type']);

    final address =
        _value(institute['complete_address']);

    final district =
        _value(institute['district']);

    final state =
        _value(institute['state']);

    final pinCode =
        _value(institute['pin_code']);

    final representativeName =
        _value(institute['representative_name']);

    final designation =
        _value(institute['designation']);

    final mobileNumber =
        _value(institute['mobile_number']);

    final email =
        _value(institute['official_email']);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 6,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.business_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          organizationName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            [
              if (district != '-') district,
              if (organizationType != '-') organizationType,
            ].join(' • '),
          ),
        ),
        children: [
          if (registrationNumber != '-')
            _detailRow(
              Icons.badge_outlined,
              'Registration',
              registrationNumber,
            ),
          if (organizationType != '-')
            _detailRow(
              Icons.business_center_outlined,
              'Type',
              organizationType,
            ),
          if (address != '-')
            _detailRow(
              Icons.home_work_outlined,
              'Address',
              address,
            ),
          if (district != '-')
            _detailRow(
              Icons.location_city_outlined,
              'District',
              district,
            ),
          if (state != '-')
            _detailRow(
              Icons.location_on_outlined,
              'State',
              state,
            ),
          if (pinCode != '-')
            _detailRow(
              Icons.markunread_mailbox_outlined,
              'PIN Code',
              pinCode,
            ),
          if (representativeName != '-')
            _detailRow(
              Icons.person_outline,
              'Representative',
              representativeName,
            ),
          if (designation != '-')
            _detailRow(
              Icons.work_outline,
              'Designation',
              designation,
            ),
          if (mobileNumber != '-')
            _detailRow(
              Icons.phone_outlined,
              'Mobile',
              mobileNumber,
            ),
          if (email != '-')
            _detailRow(
              Icons.email_outlined,
              'Email',
              email,
            ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _value(dynamic value, [String fallback = '-']) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.business_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 14),
          Text(
            'No approved institutes found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 7),
          Text(
            'There are no approved institutes matching the selected state, district, category and scheme.',
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
              onPressed: _loadInstitutes,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}