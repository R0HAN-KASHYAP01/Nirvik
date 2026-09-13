import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/project.dart';
import '../data/projects_repository.dart';
import 'project_details_screen.dart';
import 'widgets/project_list_item.dart';

enum _ProjectFilter {
  all,
  active,
  underReview,
  highRisk,
}

class ProjectListScreen extends StatefulWidget {
  final bool initialHighRiskFilter;

  const ProjectListScreen({
    super.key,
    this.initialHighRiskFilter = false,
  });

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  final ProjectsRepository _repository = ProjectsRepository();

  late Future<List<Project>> _projectsFuture;

  String _query = '';

  late _ProjectFilter _filter;

  // ---------------------------------------------------------------------------
  // Blue-Grey Government Theme
  // ---------------------------------------------------------------------------

  static const Color _navy = Color(0xFF123E68);
  static const Color _background = Color(0xFFEAF2F8);
  static const Color _cardBackground = Color(0xFFE1ECF3);
  static const Color _softBlue = Color(0xFFD7E5EE);
  static const Color _border = Color(0xFFD1DEE7);
  static const Color _textDark = Color(0xFF17324D);
  static const Color _textGrey = Color(0xFF667788);

  @override
  void initState() {
    super.initState();

    _filter = widget.initialHighRiskFilter
        ? _ProjectFilter.highRisk
        : _ProjectFilter.all;

    _projectsFuture = _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Project>> _loadProjects() {
    return _repository.getProjects();
  }

  Future<void> _refreshProjects() async {
    setState(() {
      _projectsFuture = _loadProjects();
    });

    await _projectsFuture;
  }

  // ---------------------------------------------------------------------------
  // Filtering
  // ---------------------------------------------------------------------------

  List<Project> _filterProjects(List<Project> projects) {
    final q = _query.trim().toLowerCase();

    return projects.where((project) {
      final matchesQuery =
          q.isEmpty ||
          project.name.toLowerCase().contains(q) ||
          project.location.toLowerCase().contains(q) ||
          project.type.toLowerCase().contains(q) ||
          project.id.toLowerCase().contains(q);

      final matchesFilter = switch (_filter) {
        _ProjectFilter.all => true,
        _ProjectFilter.active =>
          project.status == ProjectStatus.active,
        _ProjectFilter.underReview =>
          project.status == ProjectStatus.underReview,
        _ProjectFilter.highRisk =>
          project.riskLevel == RiskLevel.high,
      };

      return matchesQuery && matchesFilter;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Filter Chip
  // ---------------------------------------------------------------------------

  Widget _filterChip(
    String label,
    _ProjectFilter value,
  ) {
    final selected = _filter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _filter = value;
          });
        },
        selectedColor: _navy,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : _textGrey,
        ),
        side: BorderSide(
          color: selected ? _navy : _border,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(
          color: _navy,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(Object error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 46,
                color: _textGrey,
              ),
              const SizedBox(height: 14),
              const Text(
                'Unable to load projects',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: _textGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _projectsFuture = _loadProjects();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _navy,
                  side: const BorderSide(
                    color: _navy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Project List
  // ---------------------------------------------------------------------------

  Widget _buildProjectList(List<Project> projects) {
    final results = _filterProjects(projects);

    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: EmptyState(
          icon: Icons.search_off,
          title: 'No projects found',
          message: 'Try adjusting your search or filters.',
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        28,
      ),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final project = results[index];

        return SizedBox(
          width: double.infinity,
          child: ProjectListItem(
            project: project,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProjectDetailsScreen(
                    project: project,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Screen
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,

      // -----------------------------------------------------------------------
      // App Bar
      // -----------------------------------------------------------------------

      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          'Projects',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshProjects,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      // -----------------------------------------------------------------------
      // Body
      // -----------------------------------------------------------------------

      body: SafeArea(
        child: Column(
          children: [
            // =================================================================
            // Search + Filters Header
            // =================================================================

            Container(
              width: double.infinity,
              color: _background,
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monitor registered projects and institutions',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: _textGrey,
                    ),
                  ),

                  const SizedBox(height: 13),

                  // Search
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                      });
                    },
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText:
                          'Search by name, location, or type',
                      hintStyle: const TextStyle(
                        color: _textGrey,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: _textGrey,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();

                                setState(() {
                                  _query = '';
                                });
                              },
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(
                          color: _border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(
                          color: _border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(
                          color: _navy,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 11),

                  // Filters
                  SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _filterChip(
                            'All',
                            _ProjectFilter.all,
                          ),
                          _filterChip(
                            'Active',
                            _ProjectFilter.active,
                          ),
                          _filterChip(
                            'Under Review',
                            _ProjectFilter.underReview,
                          ),
                          _filterChip(
                            'High Risk',
                            _ProjectFilter.highRisk,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // =================================================================
            // Divider
            // =================================================================

            const Divider(
              height: 1,
              thickness: 1,
              color: _border,
            ),

            // =================================================================
            // Projects
            // =================================================================

            Expanded(
              child: FutureBuilder<List<Project>>(
                future: _projectsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(
                      snapshot.error!,
                    );
                  }

                  final projects = snapshot.data ?? [];

                  return RefreshIndicator(
                    color: _navy,
                    onRefresh: _refreshProjects,
                    child: _buildProjectList(projects),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}