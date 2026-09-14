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

  // Blue-grey theme
  static const Color _navy = Color(0xFF123E68);
  static const Color _primaryBlue = Color(0xFF14568A);
  static const Color _background = Color(0xFFEAF2F8);
  static const Color _cardBackground = Color(0xFFE1ECF3);
  static const Color _borderColor = Color(0xFFD1DEE7);
  static const Color _textDark = Color(0xFF17324D);
  static const Color _textGrey = Color(0xFF667788);

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
      backgroundColor: _background,

      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,

        title: Text(
          widget.scheme.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
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
              color: _primaryBlue,
              backgroundColor: Colors.white,
              onRefresh: () async {
                _reload();
                await _future;
              },

              child: Column(
                children: [
                  // Scheme information + Search
                  Container(
                    width: double.infinity,
                    color: _background,

                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        16,
                        horizontalPadding,
                        12,
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Scheme description
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),

                            decoration: BoxDecoration(
                              color: _cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _borderColor,
                              ),
                            ),

                            child: Text(
                              widget.scheme.description,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                color: _textDark,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Search field
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

                              hintStyle: const TextStyle(
                                color: _textGrey,
                                fontSize: 13,
                              ),

                              prefixIcon: const Icon(
                                Icons.search,
                                size: 20,
                                color: _primaryBlue,
                              ),

                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',

                                      icon: const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: _textGrey,
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
                                vertical: 14,
                              ),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: _borderColor,
                                ),
                              ),

                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: _borderColor,
                                ),
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: _primaryBlue,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Divider
                  const Divider(
                    height: 1,
                    color: _borderColor,
                  ),

                  // Institutes
                  Expanded(
                    child: results.isEmpty
                        ? ListView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),

                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),

                            children: const [
                              Padding(
                                padding: EdgeInsets.only(
                                  top: 48,
                                ),

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

                            separatorBuilder: (_, __) =>
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