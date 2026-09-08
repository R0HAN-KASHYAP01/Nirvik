import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/project.dart';
import '../data/projects_repository.dart';
import 'project_details_screen.dart';
import 'widgets/project_list_item.dart';

enum _ProjectFilter { all, active, underReview, highRisk }

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProjectsRepository _repository = ProjectsRepository();

  late Future<List<Project>> _projectsFuture;

  String _query = '';
  _ProjectFilter _filter = _ProjectFilter.all;

  @override
  void initState() {
    super.initState();
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
        _ProjectFilter.active => project.status == ProjectStatus.active,
        _ProjectFilter.underReview =>
          project.status == ProjectStatus.underReview,
        _ProjectFilter.highRisk => project.riskLevel == RiskLevel.high,
      };

      return matchesQuery && matchesFilter;
    }).toList();
  }

  Widget _filterChip(String label, _ProjectFilter value) {
    final selected = _filter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _filter = value;
          });
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load projects',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _projectsFuture = _loadProjects();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final project = results[index];

        return ProjectListItem(
          project: project,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectDetailsScreen(project: project),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              _refreshProjects();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monitor registered projects and institutions',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name, location, or type',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();

                                setState(() {
                                  _query = '';
                                });
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('All', _ProjectFilter.all),
                        _filterChip('Active', _ProjectFilter.active),
                        _filterChip('Under Review', _ProjectFilter.underReview),
                        _filterChip('High Risk', _ProjectFilter.highRisk),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Project>>(
                future: _projectsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error!);
                  }

                  final projects = snapshot.data ?? [];

                  return _buildProjectList(projects);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
