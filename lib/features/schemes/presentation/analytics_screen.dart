import 'package:flutter/material.dart';

import '../../projects/presentation/project_list_screen.dart';
import '../../schemes/presentation/schemes_screen.dart';
import '../../dashboard/presentation/assignments_screen.dart';
import '../../dashboard/presentation/official_cctv_screen.dart';
import '../../dashboard/presentation/official_profile_screen.dart';
import '../../dashboard/presentation/official_shell_screen.dart';
import '../../dashboard/presentation/pmu_monitoring_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static const Color navy = Color(0xFF0E4A82);
  static const Color darkNavy = Color(0xFF123E68);
  static const Color background = Color(0xFFEAF4FA);
  static const Color cardBlue = Color(0xFFEAF4FC);
  static const Color border = Color(0xFFBBD6EA);
  static const Color textDark = Color(0xFF103D69);
  static const Color textGrey = Color(0xFF64748B);

  String selectedPeriod = 'Last 30 days';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Overview'),
                    const SizedBox(height: 12),

                    _buildOverviewGrid(),

                    const SizedBox(height: 22),

                    _sectionTitle('Inspection Overview'),
                    const SizedBox(height: 10),

                    _buildInspectionOverview(),

                    const SizedBox(height: 22),

                    _sectionTitle('Risk Distribution'),
                    const SizedBox(height: 10),

                    _buildRiskDistribution(),

                    const SizedBox(height: 22),

                    _sectionTitle('Inspection Trend'),
                    const SizedBox(height: 10),

                    _buildInspectionTrend(),

                    const SizedBox(height: 22),

                    _sectionTitle('Scheme-wise Monitoring'),
                    const SizedBox(height: 10),

                    _buildSchemeMonitoring(),

                    const SizedBox(height: 22),

                    _buildBottomAnalyticsCards(),

                    const SizedBox(height: 18),

                    _buildCctvMonitoring(),

                    const SizedBox(height: 14),

                    _buildAttentionRequired(),

                    const SizedBox(height: 26),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  // ---------------------------------------------------------------------------
  // APP BAR
  // ---------------------------------------------------------------------------

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 28,
              ),
            ),

            const SizedBox(width: 6),

            const Expanded(
              child: Text(
                'Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _showPeriodSelector,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedPeriod,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION TITLE
  // ---------------------------------------------------------------------------

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: textDark,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OVERVIEW
  // ---------------------------------------------------------------------------

  Widget _buildOverviewGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 500;
        final width = twoColumns
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: width,
              child: _metricCard(
                icon: Icons.apartment_rounded,
                iconBackground: const Color(0xFFD8EDFF),
                iconColor: const Color(0xFF1476C9),
                title: 'Total Projects / Institutes',
                value: '6',
                chartColor: const Color(0xFF4CA3E8),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProjectListScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: width,
              child: _metricCard(
                icon: Icons.assignment_rounded,
                iconBackground: const Color(0xFFD7F1F1),
                iconColor: const Color(0xFF169B91),
                title: 'Total Inspections',
                value: '12',
                chartColor: const Color(0xFF19A397),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AssignmentsScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: width,
              child: _metricCard(
                icon: Icons.access_time_rounded,
                iconBackground: const Color(0xFFFFEBCF),
                iconColor: const Color(0xFFFF9E27),
                title: 'Under Review',
                value: '3',
                chartColor: const Color(0xFFFFA52D),
                onTap: () {
                  _showMessage('3 inspections are currently under review.');
                },
              ),
            ),
            SizedBox(
              width: width,
              child: _metricCard(
                icon: Icons.warning_amber_rounded,
                iconBackground: const Color(0xFFFFDDE2),
                iconColor: const Color(0xFFE73549),
                title: 'High Risk',
                value: '1',
                chartColor: const Color(0xFFE73549),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProjectListScreen(
                        initialHighRiskFilter: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String value,
    required Color chartColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBlue,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 29,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              _miniBars(chartColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBars(Color color) {
    return SizedBox(
      width: 32,
      height: 35,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _bar(11, color),
          const SizedBox(width: 3),
          _bar(20, color),
          const SizedBox(width: 3),
          _bar(30, color),
        ],
      ),
    );
  }

  Widget _bar(double height, Color color) {
    return Container(
      width: 6,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INSPECTION OVERVIEW
  // ---------------------------------------------------------------------------

  Widget _buildInspectionOverview() {
    return _whiteCard(
      child: Column(
        children: [
          _progressRow(
            title: 'Completed',
            value: '8',
            percentage: 8 / 12,
            color: const Color(0xFF159E8C),
          ),
          const SizedBox(height: 18),
          _progressRow(
            title: 'Under Review',
            value: '2',
            percentage: 2 / 12,
            color: const Color(0xFFFF9F2F),
          ),
          const SizedBox(height: 18),
          _progressRow(
            title: 'In Progress',
            value: '1',
            percentage: 1 / 12,
            color: const Color(0xFF2277CF),
          ),
          const SizedBox(height: 18),
          _progressRow(
            title: 'Assigned',
            value: '0',
            percentage: 0,
            color: const Color(0xFF8295AA),
          ),
          const SizedBox(height: 18),
          _progressRow(
            title: 'Overdue',
            value: '1',
            percentage: 1 / 12,
            color: const Color(0xFFE7374A),
          ),
        ],
      ),
    );
  }

  Widget _progressRow({
    required String title,
    required String value,
    required double percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: textDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 7,
            backgroundColor: const Color(0xFFE1EDF5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // RISK DISTRIBUTION
  // ---------------------------------------------------------------------------

  Widget _buildRiskDistribution() {
    return _whiteCard(
      child: Column(
        children: [
          _riskRow(
            icon: Icons.warning_rounded,
            title: 'High Risk',
            count: '1',
            percentage: '17%',
            progress: 0.17,
            color: const Color(0xFFE73549),
            iconBackground: const Color(0xFFFFDCE1),
          ),
          const SizedBox(height: 20),
          _riskRow(
            icon: Icons.warning_amber_rounded,
            title: 'Medium Risk',
            count: '3',
            percentage: '50%',
            progress: 0.50,
            color: const Color(0xFFFF9D27),
            iconBackground: const Color(0xFFFFE8CA),
          ),
          const SizedBox(height: 20),
          _riskRow(
            icon: Icons.check_circle_rounded,
            title: 'Low Risk',
            count: '2',
            percentage: '33%',
            progress: 0.33,
            color: const Color(0xFF1BA76B),
            iconBackground: const Color(0xFFD8F3E5),
          ),
        ],
      ),
    );
  }

  Widget _riskRow({
    required IconData icon,
    required String title,
    required String count,
    required String percentage,
    required double progress,
    required Color color,
    required Color iconBackground,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: color,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    count,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 42,
                    child: Text(
                      '($percentage)',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFE7EFF5),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // INSPECTION TREND
  // ---------------------------------------------------------------------------

  Widget _buildInspectionTrend() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inspection Trend',
            style: TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 155,
            child: CustomPaint(
              painter: _TrendPainter(),
              child: const SizedBox.expand(),
            ),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              _trendLabel('7 Days'),
              _trendLabel('30 Days', selected: true),
              _trendLabel('6 Months'),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8EDFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFF1476C9),
                    size: 25,
                  ),
                ),
                const SizedBox(width: 13),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '12 inspections',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'in last 30 days',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendLabel(
    String text, {
    bool selected = false,
  }) {
    return Expanded(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 7,
          ),
          decoration: selected
              ? BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(20),
                )
              : null,
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : textGrey,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SCHEME MONITORING
  // ---------------------------------------------------------------------------

  Widget _buildSchemeMonitoring() {
    return _whiteCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Scheme-wise Monitoring',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SchemesScreen(),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.chevron_right,
                      color: navy,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          _schemeHeader(),

          _schemeRow(
            icon: Icons.school_rounded,
            iconColor: const Color(0xFF1678C8),
            iconBackground: const Color(0xFFD9EEFF),
            name: 'Education Support Scheme',
            institutes: '3',
            inspections: '8',
          ),

          _schemeRow(
            icon: Icons.local_hospital_rounded,
            iconColor: const Color(0xFF18A66C),
            iconBackground: const Color(0xFFD9F3E5),
            name: 'Health Infrastructure Scheme',
            institutes: '2',
            inspections: '3',
          ),

          _schemeRow(
            icon: Icons.eco_rounded,
            iconColor: const Color(0xFF1C9E65),
            iconBackground: const Color(0xFFD9F3E5),
            name: 'Skill Development Scheme',
            institutes: '1',
            inspections: '1',
          ),
        ],
      ),
    );
  }

  Widget _schemeHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              'Scheme',
              style: TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Institutes',
              style: TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Inspections',
              style: TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 18),
        ],
      ),
    );
  }

  Widget _schemeRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String name,
    required String institutes,
    required String inspections,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SchemesScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 10,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFD7E5EF),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              flex: 5,
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Expanded(
              flex: 2,
              child: Text(
                institutes,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            Expanded(
              flex: 2,
              child: Text(
                inspections,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: navy,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INSTITUTE + INSPECTOR
  // ---------------------------------------------------------------------------

  Widget _buildBottomAnalyticsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 650;
        final width = twoColumns
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: width,
              child: _buildInstituteMonitoring(),
            ),
            SizedBox(
              width: width,
              child: _buildInspectorPerformance(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstituteMonitoring() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Institute Monitoring',
            style: TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _InstituteDonutPainter(),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '6',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Total',
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  children: [
                    _legendItem(
                      'Inspected',
                      '4',
                      const Color(0xFF1AA77A),
                    ),
                    _legendItem(
                      'Under Review',
                      '1',
                      const Color(0xFFFFA029),
                    ),
                    _legendItem(
                      'High Risk',
                      '1',
                      const Color(0xFFE73549),
                    ),
                    _legendItem(
                      'Not Inspected',
                      '0',
                      const Color(0xFF8094AA),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
    String title,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: textGrey,
                fontSize: 11,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: textDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorPerformance() {
    return _whiteCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Inspector Performance',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  _showMessage(
                    'Inspector performance details will open here.',
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        color: navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: navy,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _inspectorHeader(),
          _inspectorRow('Inspector A', '8', '6', '75%'),
          _inspectorRow('Inspector B', '5', '5', '100%'),
          _inspectorRow('Inspector C', '4', '2', '50%'),
        ],
      ),
    );
  }

  Widget _inspectorHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FA),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'Inspector',
              style: TextStyle(
                color: textGrey,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Assigned',
              style: TextStyle(
                color: textGrey,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Completed',
              style: TextStyle(
                color: textGrey,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Rate',
              style: TextStyle(
                color: textGrey,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inspectorRow(
    String name,
    String assigned,
    String completed,
    String rate,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFD7E5EF),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              name,
              style: const TextStyle(
                color: textDark,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              assigned,
              style: const TextStyle(
                color: textDark,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              completed,
              style: const TextStyle(
                color: textDark,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  rate,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: double.tryParse(
                            rate.replaceAll('%', ''),
                          )! /
                          100,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFDCE9F2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
                        Color(0xFF20A46E),
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

  // ---------------------------------------------------------------------------
  // CCTV
  // ---------------------------------------------------------------------------

  Widget _buildCctvMonitoring() {
    return _whiteCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const OfficialCctvScreen(),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFD9EEFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.videocam_rounded,
                color: Color(0xFF1476C9),
                size: 26,
              ),
            ),

            const SizedBox(width: 13),

            const Expanded(
              child: Text(
                'CCTV Monitoring',
                style: TextStyle(
                  color: textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            _cctvStat(
              'Online',
              '5',
              const Color(0xFF159E8C),
            ),

            _verticalDivider(),

            _cctvStat(
              'Offline',
              '1',
              const Color(0xFFE73549),
            ),

            _verticalDivider(),

            _cctvStat(
              'Alerts',
              '2',
              const Color(0xFFFF9D27),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.chevron_right,
              color: navy,
              size: 23,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cctvStat(
    String label,
    String value,
    Color color,
  ) {
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: textDark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 35,
      color: const Color(0xFFD3E2EC),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  // ---------------------------------------------------------------------------
  // ATTENTION REQUIRED
  // ---------------------------------------------------------------------------

  Widget _buildAttentionRequired() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ProjectListScreen(
                initialHighRiskFilter: true,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1DF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFFD39D),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDDAE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFFF8D17),
                  size: 26,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attention Required',
                      style: TextStyle(
                        color: Color(0xFFB33B20),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '2 High-risk institutes  •  3 Overdue inspections  •  1 CCTV offline',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: Color(0xFFB33B20),
                size: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAVIGATION
  // ---------------------------------------------------------------------------

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF1F8FC),
        border: Border(
          top: BorderSide(
            color: Color(0xFFD3E2EC),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              _bottomItem(
                context,
                icon: Icons.home_rounded,
                label: 'Home',
                selected: true,
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const OfficialShellScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
              _bottomItem(
                context,
                icon: Icons.account_balance_rounded,
                label: 'Schemes',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SchemesScreen(),
                    ),
                  );
                },
              ),
              _bottomItem(
                context,
                icon: Icons.groups_rounded,
                label: 'PMU',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PmuMonitoringScreen(),
                    ),
                  );
                },
              ),
              _bottomItem(
                context,
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OfficialProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFD5E7F3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                icon,
                color: selected ? navy : textGrey,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected ? navy : textGrey,
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PERIOD SELECTOR
  // ---------------------------------------------------------------------------

  void _showPeriodSelector() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        final options = [
          'Last 7 days',
          'Last 30 days',
          'Last 6 months',
          'Last 1 year',
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5DEE6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Select time period',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map(
                  (option) {
                    final selected = option == selectedPeriod;

                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: selected ? navy : textGrey,
                      ),
                      title: Text(
                        option,
                        style: TextStyle(
                          color: textDark,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          selectedPeriod = option;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // COMMON CARD
  // ---------------------------------------------------------------------------

  Widget _whiteCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: border,
        ),
      ),
      child: child,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}

// ============================================================================
// TREND CHART
// ============================================================================

class _TrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFD9E8F2)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = const Color(0xFF1476C9)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFF1476C9).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    const rows = 4;

    for (int i = 0; i <= rows; i++) {
      final y = i * size.height / rows;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    const values = [
      3.0,
      5.0,
      4.0,
      5.0,
      7.0,
      4.0,
      7.0,
      6.0,
      8.0,
      12.0,
    ];

    final maxValue = 15.0;

    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y = size.height -
          ((values[i] / maxValue) * size.height);

      points.add(Offset(x, y));
    }

    final linePath = Path();

    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        linePath.moveTo(
          points[i].dx,
          points[i].dy,
        );
      } else {
        linePath.lineTo(
          points[i].dx,
          points[i].dy,
        );
      }
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()
      ..color = const Color(0xFF1476C9)
      ..style = PaintingStyle.fill;

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(point, 2, whitePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================================
// INSTITUTE DONUT
// ============================================================================

class _InstituteDonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.butt;

    const total = 6.0;

    final sections = [
      (4.0, const Color(0xFF1AA77A)),
      (1.0, const Color(0xFFFFA029)),
      (1.0, const Color(0xFFE73549)),
    ];

    double startAngle = -1.5708;

    for (final section in sections) {
      final value = section.$1;
      final color = section.$2;

      paint.color = color;

      final sweep =
          (value / total) * 6.283185307;

      canvas.drawArc(
        rect.deflate(8),
        startAngle,
        sweep,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}