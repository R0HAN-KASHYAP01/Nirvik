import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_start.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../models/institute.dart';
import '../../../models/scheme.dart';
import '../data/schemes_repository.dart';
import 'institute_details_screen.dart';
import 'widgets/institute_list_item.dart';

class SchemeDetailsScreen extends StatefulWidget {
  final Scheme scheme;

  const SchemeDetailsScreen({
    super.key,
    required this.scheme,
  });

  @override
  State<SchemeDetailsScreen> createState() => _SchemeDetailsScreenState();
}

class _SchemeDetailsScreenState extends State<SchemeDetailsScreen> {
  final _repository = SchemesRepository();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Institute>> _future;

  String _query = '';

  @override
  void initState() {
    super.initState();

    _future = _repository.fetchInstitutesForScheme(
      widget.scheme.type,
    );
  }

  void _reload() {
    setState(() {
      _future = _repository.fetchInstitutesForScheme(
        widget.scheme.type,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Institute> _applyFilter(List<Institute> all) {
    final q = _query.trim().toLowerCase();

    if (q.isEmpty) {
      return all;
    }

    return all
        .where(
          (institute) =>
              institute.name.toLowerCase().contains(q) ||
              institute.location.toLowerCase().contains(q) ||
              institute.category.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final horizontalPadding = screenWidth < 360 ? 12.0 : 20.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.scheme.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Institute>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingState(
                message: 'Loading institutes…',
              );
            }

            if (snapshot.hasError) {
              return ErrorStateView(
                message: 'Could not load institutes for this scheme.',
                onRetry: _reload,
              );
            }

            final all = snapshot.data ?? [];
            final results = _applyFilter(all);

            return RefreshIndicator(
              onRefresh: () async {
                _reload();
              },
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      16,
                      horizontalPadding,
                      12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.scheme.description,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
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
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText:
                                'Search institutes by name, location, or category',
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 20,
                            ),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
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
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  Expanded(
                    child: results.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            children: const [
                              Padding(
                                padding: EdgeInsets.only(top: 48),
                                child: EmptyState(
                                  icon: Icons.search_off,
                                  title: 'No institutes found',
                                  message:
                                      'Try adjusting your search, or pull to refresh.',
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              16,
                              horizontalPadding,
                              24,
                            ),
                            itemCount: results.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final institute = results[index];

                              return InstituteListItem(
                                institute: institute,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          InstituteDetailsScreen(
                                        institute: institute,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
} 