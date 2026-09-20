import 'package:flutter/material.dart';

import '../../../services/session_service.dart';
import '../data/national_dashboard_repository.dart';

/// Combined national dashboard.
///
/// Used for:
/// - DoSJE Officials
/// - MoSJE / National Admin
///
/// Institute data comes from approved institute_reps records.
///
/// Dashboard intentionally does NOT contain:
/// - Schemes
/// - State-wise monitoring
/// - PMU Monitoring screen
class OfficialHomeScreen extends StatefulWidget {
  const OfficialHomeScreen({super.key});

  // ---- NIRIKSHA palette : primary blues ----
  static const Color primaryBlue = Color(0xFF084482); // primary-blue
  static const Color navy = Color(0xFF063A77); // primary-dark
  static const Color primaryMedium = Color(0xFF0B5AA0); // primary-medium
  static const Color lightBlue = Color(0xFFEAF4FD); // primary-light

  // ---- Backgrounds ----
  static const Color background = Color(0xFFF1F7FC); // app-background
  static const Color sectionBackground = Color(0xFFF7FAFD);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ---- Borders ----
  static const Color borderColor = Color(0xFFDCE8F2); // border-light
  static const Color borderMedium = Color(0xFFC8D9E8);

  // ---- Text ----
  static const Color textDark = Color(0xFF173B63); // text-primary
  static const Color textGrey = Color(0xFF5F7285); // text-secondary
  static const Color textMuted = Color(0xFF8191A1);

  // ---- Success ----
  static const Color green = Color(0xFF20A866);
  static const Color greenDark = Color(0xFF16834D);
  static const Color greenBg = Color(0xFFE7F8EE);

  // ---- Warning ----
  static const Color orange = Color(0xFFF2A51A);
  static const Color orangeDark = Color(0xFFC77B00);
  static const Color orangeBg = Color(0xFFFFF3D9);

  // ---- Danger ----
  static const Color red = Color(0xFFE84B4B);
  static const Color redDark = Color(0xFFC93636);
  static const Color redBg = Color(0xFFFDEAEA);

  // ---- Info ----
  static const Color info = Color(0xFF2486D9);
  static const Color infoBg = Color(0xFFE7F3FF);

  // ---- Gradients ----

  // Main blue gradient: 135deg  #0B5AA0 -> #084482 (55%) -> #063A77
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B5AA0),
      Color(0xFF084482),
      Color(0xFF063A77),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  // Light blue gradient
  static const LinearGradient lightBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF7FAFD),
      Color(0xFFEFF7FD),
      Color(0xFFEAF4FD),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Screen background gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF7FAFD),
      Color(0xFFEAF4FD),
    ],
  );

  // White card gradient (very subtle)
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFBFDFF),
    ],
  );

  // Danger card gradient
  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF7F7),
      Color(0xFFFDE5E5),
    ],
  );

  // Warning card gradient
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFBF2),
      Color(0xFFFFF0D0),
    ],
  );

  // Soft shadow tinted with blue
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x14084482),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  @override
  State<OfficialHomeScreen> createState() =>
      _OfficialHomeScreenState();
}

class _OfficialHomeScreenState
    extends State<OfficialHomeScreen> {
  final NationalDashboardRepository _repository =
      NationalDashboardRepository();

  late Future<NationalDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadDashboard();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repository.loadDashboard();
    });

    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final user =
        SessionService.instance.currentUser;

    return Scaffold(
      backgroundColor:
          OfficialHomeScreen.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient:
              OfficialHomeScreen.backgroundGradient,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color:
                OfficialHomeScreen.primaryBlue,
            onRefresh: _refresh,
            child:
                FutureBuilder<NationalDashboardData>(
              future: _future,
              builder:
                  (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 260),
                      Center(
                        child:
                            CircularProgressIndicator(
                          color: OfficialHomeScreen
                              .primaryBlue,
                        ),
                      ),
                    ],
                  );
                }

                if (snapshot.hasError) {
                  return ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.all(20),
                    children: [
                      _Header(
                        userName:
                            user?.name ?? 'Official',
                        onRefresh: _refresh,
                      ),
                      const SizedBox(height: 28),
                      _ErrorCard(
                        message:
                            'Dashboard data could not be loaded.\n'
                            '${snapshot.error}',
                        onRetry: _refresh,
                      ),
                    ],
                  );
                }

                final data = snapshot.data;

                if (data == null) {
                  return ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.all(20),
                    children: [
                      _Header(
                        userName:
                            user?.name ?? 'Official',
                        onRefresh: _refresh,
                      ),
                      const SizedBox(height: 28),
                      const _ErrorCard(
                        message:
                            'No dashboard data available.',
                      ),
                    ],
                  );
                }

                return LayoutBuilder(
                  builder:
                      (context, constraints) {
                    final horizontal =
                        constraints.maxWidth >= 700
                            ? 32.0
                            : 18.0;

                    return ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          EdgeInsets.fromLTRB(
                        horizontal,
                        16,
                        horizontal,
                        28,
                      ),
                      children: [
                        _Header(
                          userName:
                              user?.name ??
                                  'Official',
                          onRefresh: _refresh,
                        ),

                        const SizedBox(height: 22),

                        const _PageIntro(),

                        const SizedBox(height: 16),

                        _MetricGrid(
                          data: data,
                        ),

                        const SizedBox(height: 18),

                        _InstituteCategoryCard(
                          data: data,
                        ),

                        const SizedBox(height: 18),

                        _ComplianceCard(
                          data: data,
                        ),

                        const SizedBox(height: 18),

                        _FindingsCard(
                          count:
                              data.openCriticalFindingsCount,
                        ),

                        const SizedBox(height: 18),

                        _ApprovedInstitutesCard(
                          institutes:
                              data.approvedInstitutes,
                        ),

                        if (data
                            .unavailableMetrics
                            .isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _LimitationsCard(
                            metrics:
                                data.unavailableMetrics,
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HEADER
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.userName,
    required this.onRefresh,
  });

  final String userName;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient:
                OfficialHomeScreen.primaryGradient,
            borderRadius:
                BorderRadius.circular(13),
            boxShadow:
                OfficialHomeScreen.softShadow,
          ),
          child: const Icon(
            Icons.account_balance,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'DoSJE • National Monitoring',
                style: TextStyle(
                  color:
                      OfficialHomeScreen.textGrey,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Welcome, $userName',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color:
                      OfficialHomeScreen.textDark,
                  fontSize: 19,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh dashboard',
          onPressed: onRefresh,
          icon: const Icon(
            Icons.refresh_rounded,
            color:
                OfficialHomeScreen.primaryBlue,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// PAGE INTRO
// ---------------------------------------------------------------------------

class _PageIntro extends StatelessWidget {
  const _PageIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient:
            OfficialHomeScreen.primaryGradient,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow:
            OfficialHomeScreen.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(alpha: 0.14),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.insights_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'National Monitoring Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Real-time overview of approved institutes, inspections and compliance.',
                  style: TextStyle(
                    color: Color(0xFFDCE9F5),
                    fontSize: 12,
                    height: 1.35,
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

// ---------------------------------------------------------------------------
// METRIC GRID
// ---------------------------------------------------------------------------

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.data,
  });

  final NationalDashboardData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder:
          (context, constraints) {
        final width =
            constraints.maxWidth;

        final columns =
            width >= 1000 ? 4 : 2;

        const gap = 12.0;

        final cardWidth =
            (width -
                    gap * (columns - 1)) /
                columns;

        final cards = [
          _MetricCard(
            icon:
                Icons.apartment_outlined,
            title:
                'APPROVED INSTITUTES',
            value:
                data.totalInstitutes
                    .toString(),
            subtitle:
                'Approved registrations',
            iconColor:
                OfficialHomeScreen.primaryBlue,
            iconBg:
                OfficialHomeScreen.lightBlue,
          ),

          _MetricCard(
            icon:
                Icons.fact_check_outlined,
            title:
                'TOTAL INSPECTIONS',
            value:
                data.totalAssignedInspections
                    .toString(),
            subtitle:
                'Assigned inspections',
            iconColor:
                OfficialHomeScreen.info,
            iconBg:
                OfficialHomeScreen.infoBg,
          ),

          _MetricCard(
            icon:
                Icons.verified_outlined,
            title:
                'INSPECTION COMPLIANCE',
            value:
                '${(data.complianceRate * 100).round()}%',
            subtitle:
                '${data.completedInspections}/${data.totalAssignedInspections} completed',
            iconColor:
                OfficialHomeScreen.greenDark,
            iconBg:
                OfficialHomeScreen.greenBg,
          ),

          _MetricCard(
            icon:
                Icons.warning_amber_rounded,
            title:
                'CRITICAL FINDINGS',
            value:
                data.openCriticalFindingsCount
                    .toString(),
            subtitle:
                'High / critical / severe',
            iconColor:
                OfficialHomeScreen.redDark,
            iconBg:
                OfficialHomeScreen.redBg,
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map(
                (card) => SizedBox(
                  width: cardWidth,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// METRIC CARD
// ---------------------------------------------------------------------------

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.iconColor,
    required this.iconBg,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          const BoxConstraints(
        minHeight: 150,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient:
            OfficialHomeScreen.cardGradient,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              OfficialHomeScreen
                  .borderColor,
        ),
        boxShadow:
            OfficialHomeScreen.softShadow,
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color: iconBg,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color:
                  OfficialHomeScreen
                      .textGrey,
              fontSize: 10,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            style: const TextStyle(
              color:
                  OfficialHomeScreen.primaryBlue,
              fontSize: 28,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            subtitle,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color:
                  OfficialHomeScreen
                      .textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// INSTITUTE CATEGORY SUMMARY
// ---------------------------------------------------------------------------

class _InstituteCategoryCard
    extends StatelessWidget {
  const _InstituteCategoryCard({
    required this.data,
  });

  final NationalDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient:
            OfficialHomeScreen.cardGradient,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              OfficialHomeScreen
                  .borderColor,
        ),
        boxShadow:
            OfficialHomeScreen.softShadow,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.category_outlined,
                color:
                    OfficialHomeScreen
                        .primaryMedium,
                size: 22,
              ),
              SizedBox(width: 9),
              Text(
                'Approved Institutes by Category',
                style: TextStyle(
                  color:
                      OfficialHomeScreen
                          .textDark,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _CategoryItem(
                  label:
                      'Educational',
                  value:
                      data.educationalInstitutes,
                  icon:
                      Icons.school_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CategoryItem(
                  label:
                      'Social Empowerment',
                  value:
                      data.socialEmpowermentInstitutes,
                  icon:
                      Icons.volunteer_activism_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CategoryItem(
                  label:
                      'Economic Development',
                  value:
                      data.economicDevelopmentInstitutes,
                  icon:
                      Icons.trending_up_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryItem
    extends StatelessWidget {
  const _CategoryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          const BoxConstraints(
        minHeight: 92,
      ),
      padding:
          const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient:
            OfficialHomeScreen
                .lightBlueGradient,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              OfficialHomeScreen
                  .borderColor,
        ),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color:
                OfficialHomeScreen
                    .primaryMedium,
            size: 22,
          ),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: const TextStyle(
              color:
                  OfficialHomeScreen.primaryBlue,
              fontSize: 21,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign:
                TextAlign.center,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color:
                  OfficialHomeScreen
                      .textGrey,
              fontSize: 9,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// INSPECTION COMPLIANCE
// ---------------------------------------------------------------------------

class _ComplianceCard
    extends StatelessWidget {
  const _ComplianceCard({
    required this.data,
  });

  final NationalDashboardData data;

  @override
  Widget build(BuildContext context) {
    final rate =
        data.complianceRate;

    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient:
            OfficialHomeScreen.cardGradient,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              OfficialHomeScreen
                  .borderColor,
        ),
        boxShadow:
            OfficialHomeScreen.softShadow,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fact_check_outlined,
                color:
                    OfficialHomeScreen
                        .primaryMedium,
                size: 22,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Inspection Compliance',
                  style: TextStyle(
                    color:
                        OfficialHomeScreen
                            .textDark,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${(rate * 100).round()}%',
                style:
                    const TextStyle(
                  color:
                      OfficialHomeScreen
                          .primaryBlue,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              8,
            ),
            child:
                LinearProgressIndicator(
              value: rate,
              minHeight: 9,
              backgroundColor:
                  OfficialHomeScreen
                      .lightBlue,
              valueColor:
                  const AlwaysStoppedAnimation<
                      Color>(
                OfficialHomeScreen
                    .green,
              ),
            ),
          ),

          const SizedBox(height: 15),

          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _ComplianceItem(
                label: 'Completed',
                value:
                    data.completedInspections,
                color:
                    OfficialHomeScreen
                        .green,
              ),
              _ComplianceItem(
                label: 'Pending',
                value:
                    data.pendingInspections,
                color:
                    OfficialHomeScreen
                        .orange,
              ),
              _ComplianceItem(
                label: 'In Progress',
                value:
                    data.inProgressInspections,
                color:
                    OfficialHomeScreen
                        .info,
              ),
              _ComplianceItem(
                label: 'Overdue',
                value:
                    data.overdueInspections,
                color:
                    OfficialHomeScreen
                        .red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComplianceItem
    extends StatelessWidget {
  const _ComplianceItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '$label: $value',
          style:
              const TextStyle(
            color:
                OfficialHomeScreen
                    .textGrey,
            fontSize: 11,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CRITICAL FINDINGS
// ---------------------------------------------------------------------------

class _FindingsCard
    extends StatelessWidget {
  const _FindingsCard({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient:
            OfficialHomeScreen.dangerGradient,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF2BDBD),
        ),
        boxShadow:
            OfficialHomeScreen.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration:
                BoxDecoration(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.75,
              ),
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),
            child: const Icon(
              Icons
                  .report_gmailerrorred_outlined,
              color:
                  OfficialHomeScreen.redDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Critical Findings',
                  style: TextStyle(
                    color:
                        OfficialHomeScreen
                            .textDark,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'High, critical and severe inspection findings',
                  style: TextStyle(
                    color:
                        OfficialHomeScreen
                            .textGrey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            count.toString(),
            style:
                const TextStyle(
              color:
                  OfficialHomeScreen.redDark,
              fontSize: 27,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// APPROVED INSTITUTES
// ---------------------------------------------------------------------------

class _ApprovedInstitutesCard
    extends StatelessWidget {
  const _ApprovedInstitutesCard({
    required this.institutes,
  });

  final List<DashboardInstitute>
      institutes;

  @override
  Widget build(BuildContext context) {
    final visible =
        institutes.take(5).toList();

    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient:
            OfficialHomeScreen.cardGradient,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              OfficialHomeScreen
                  .borderColor,
        ),
        boxShadow:
            OfficialHomeScreen.softShadow,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(
                  gradient:
                      OfficialHomeScreen
                          .primaryGradient,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: const Icon(
                  Icons
                      .apartment_outlined,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Approved Institutes',
                      style: TextStyle(
                        color:
                            OfficialHomeScreen
                                .textDark,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Institutes approved through the registration workflow',
                      style: TextStyle(
                        color:
                            OfficialHomeScreen
                                .textGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                institutes.length
                    .toString(),
                style:
                    const TextStyle(
                  color:
                      OfficialHomeScreen
                          .primaryBlue,
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (visible.isEmpty)
            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets
                      .symmetric(
                vertical: 18,
                horizontal: 12,
              ),
              decoration:
                  BoxDecoration(
                gradient:
                    OfficialHomeScreen
                        .lightBlueGradient,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child:
                  const Column(
                children: [
                  Icon(
                    Icons
                        .apartment_outlined,
                    color:
                        OfficialHomeScreen
                            .textGrey,
                    size: 28,
                  ),
                  SizedBox(height: 7),
                  Text(
                    'No approved institutes found.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          OfficialHomeScreen
                              .textDark,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            ...visible.map(
              (institute) =>
                  _InstituteRow(
                institute:
                    institute,
              ),
            ),
        ],
      ),
    );
  }
}

class _InstituteRow
    extends StatelessWidget {
  const _InstituteRow({
    required this.institute,
  });

  final DashboardInstitute
      institute;

  @override
  Widget build(BuildContext context) {
    final location = [
      institute.district,
      institute.state,
    ]
        .where(
          (value) =>
              value.trim().isNotEmpty,
        )
        .join(', ');

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color:
              OfficialHomeScreen
                  .borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration:
                BoxDecoration(
              color:
                  OfficialHomeScreen
                      .lightBlue,
              borderRadius:
                  BorderRadius.circular(
                9,
              ),
            ),
            child: const Icon(
              Icons
                  .apartment_outlined,
              color:
                  OfficialHomeScreen
                      .primaryMedium,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  institute
                      .organizationName,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        OfficialHomeScreen
                            .textDark,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  location.isEmpty
                      ? institute.address
                      : location,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        OfficialHomeScreen
                            .textGrey,
                    fontSize: 10,
                  ),
                ),
                if (institute
                    .schemeCode
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    institute
                        .schemeCode,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      color:
                          OfficialHomeScreen
                              .info,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DATA AVAILABILITY
// ---------------------------------------------------------------------------

class _LimitationsCard
    extends StatelessWidget {
  const _LimitationsCard({
    required this.metrics,
  });

  final List<String> metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient:
            OfficialHomeScreen.warningGradient,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF2D69A),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Data availability',
            style: TextStyle(
              color:
                  OfficialHomeScreen
                      .textDark,
              fontSize: 14,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...metrics.map(
            (metric) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 6,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color:
                        OfficialHomeScreen
                            .orangeDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      metric,
                      style:
                          const TextStyle(
                        color:
                            OfficialHomeScreen
                                .textGrey,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ERROR CARD
// ---------------------------------------------------------------------------

class _ErrorCard
    extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient:
            OfficialHomeScreen.cardGradient,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              OfficialHomeScreen
                  .borderColor,
        ),
        boxShadow:
            OfficialHomeScreen.softShadow,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color:
                OfficialHomeScreen.redDark,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  OfficialHomeScreen
                      .textDark,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    OfficialHomeScreen
                        .primaryBlue,
                side: const BorderSide(
                  color:
                      OfficialHomeScreen
                          .primaryBlue,
                ),
              ),
              child:
                  const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}