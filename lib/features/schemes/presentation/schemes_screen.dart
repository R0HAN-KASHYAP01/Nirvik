import 'package:flutter/material.dart';

import '../../../core/widgets/error_start.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../models/scheme.dart';
import '../data/mock_schemes_data.dart';
import '../data/schemes_repository.dart';
import 'scheme_details_screen.dart';
import 'widgets/scheme_card.dart';

class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  final _repository = SchemesRepository();

  late Future<Map<SchemeType, int>> _future;

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

    _future = _repository.fetchSchemeCounts();
  }

  void _reload() {
    setState(() {
      _future = _repository.fetchSchemeCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scheme name, description, icon and color stay static config.
    // Only institute counts come from Supabase.
    final schemes = MockSchemesData.schemes;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360 ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,

        title: const Text(
          'Schemes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: FutureBuilder<Map<SchemeType, int>>(
          future: _future,

          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingState(
                message: 'Loading schemes…',
              );
            }

            if (snapshot.hasError) {
              return ErrorStateView(
                message: 'Could not load scheme data.',
                onRetry: _reload,
              );
            }

            final counts = snapshot.data ?? {};

            return RefreshIndicator(
              color: _primaryBlue,
              backgroundColor: Colors.white,

              onRefresh: () async {
                _reload();
                await _future;
              },

              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  24,
                ),

                children: [
                  // Header information
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

                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,

                          decoration: BoxDecoration(
                            color: _primaryBlue.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),

                          child: const Icon(
                            Icons.account_balance_outlined,
                            color: _primaryBlue,
                            size: 22,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              const Text(
                                'Government Schemes',
                                style: TextStyle(
                                  color: _textDark,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'Government schemes and their funded institutes',
                                style: const TextStyle(
                                  color: _textGrey,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Scheme cards
                  ...schemes.map(
                    (scheme) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10,
                      ),

                      child: SizedBox(
                        width: double.infinity,

                        child: SchemeCard(
                          scheme: scheme,
                          instituteCount:
                              counts[scheme.type] ?? 0,

                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    SchemeDetailsScreen(
                                  scheme: scheme,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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