// FILE: lib/features/ngo/presentation/reports_screen.dart

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../services/session_service.dart';
import '../../../services/ngo_storage_service.dart';
import '../../../services/ngo_reports_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _observationsController = TextEditingController();
  final _findingsController = TextEditingController();
  final _actionController = TextEditingController();

  Uint8List? _attachmentBytes;
  String? _attachmentName;

  bool _isSubmitting = false;
  bool _loadingReports = true;

  String? _error;

  List<NgoReport> _reports = [];

  String _searchQuery = '';
  String _dateFilter = 'All dates';
  String _sortOrder = 'Newest first';

  DateTime? _selectedDate;

  String _selectedCategory = 'General';
  String _selectedPriority = 'Medium';

  DateTime _reportDate = DateTime.now();

  // ============================================================
  // COLOR PALETTE — Government of India / SIH theme
  // ============================================================

  static const Color navy = Color(0xFF174A7E); // Primary Navy Blue
  static const Color darkBlue = Color(0xFF123A63); // Dark Navy
  static const Color blue = Color(0xFF2468A8); // Info

  static const Color background = Color(0xFFF7F8FA);
  static const Color lightBlue = Color(0xFFEAF2F9);
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Surface / White

  static const Color green = Color(0xFF2E7D5B); // Success
  static const Color lightGreen = Color(0xFFEAF5EF); // Success Background

  static const Color red = Color(0xFFC0392B); // Danger
  static const Color lightRed = Color(0xFFFCEBE9); // Danger Background

  static const Color orange = Color(0xFFB7791F); // Warning
  static const Color lightOrange = Color(0xFFFFF4DC); // Warning Background

  static const Color info = Color(0xFF2468A8); // Info
  static const Color lightInfo = Color(0xFFEAF3FB); // Info Background

  static const Color textPrimary = Color(0xFF202124); // Primary Text
  static const Color greyText = Color(0xFF5F6368); // Secondary Text
  static const Color borderColor = Color(0xFFD5D9DE); // Border

  // ---------- Gradients ----------
  // Subtle, professional gradients built from closely related shades
  // of the palette above. Used selectively for headers, primary
  // actions, and highlighted / status areas — never bright or flashy.

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF174A7E), Color(0xFF123A63)],
  );

  static const LinearGradient lightBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF4F8FC), Color(0xFFEAF2F9)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF2FAF6), Color(0xFFEAF5EF)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF9EC), Color(0xFFFFF4DC)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFDF1F0), Color(0xFFFCEBE9)],
  );

  static const LinearGradient infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3F9FD), Color(0xFFEAF3FB)],
  );

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _observationsController.dispose();
    _findingsController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD REPORTS
  // ============================================================

  Future<void> _loadReports() async {
    final user = SessionService.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _loadingReports = false;
      });

      return;
    }

    setState(() {
      _loadingReports = true;
    });

    try {
      final reports =
      await NgoReportsService.instance.fetchReports(user.id);

      if (!mounted) return;

      setState(() {
        _reports = reports;
        _loadingReports = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingReports = false;
      });

      _showError('Could not load reports.');
    }
  }

  // ============================================================
  // FILTERED REPORTS
  // ============================================================

  List<NgoReport> get _filteredReports {
    final query = _searchQuery.trim().toLowerCase();

    List<NgoReport> result = _reports.where((report) {
      if (query.isNotEmpty) {
        final title = report.title.toLowerCase();
        final description =
            report.description?.toLowerCase() ?? '';

        if (!title.contains(query) &&
            !description.contains(query)) {
          return false;
        }
      }

      if (_dateFilter == 'Today') {
        return _isSameDate(
          report.createdAt,
          DateTime.now(),
        );
      }

      if (_dateFilter == 'Last 7 days') {
        final now = DateTime.now();
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));

        return !report.createdAt.isBefore(start);
      }

      if (_dateFilter == 'This month') {
        final now = DateTime.now();

        return report.createdAt.year == now.year &&
            report.createdAt.month == now.month;
      }

      if (_dateFilter == 'Selected date' &&
          _selectedDate != null) {
        return _isSameDate(
          report.createdAt,
          _selectedDate!,
        );
      }

      return true;
    }).toList();

    result.sort((a, b) {
      if (_sortOrder == 'Newest first') {
        return b.createdAt.compareTo(a.createdAt);
      }

      return a.createdAt.compareTo(b.createdAt);
    });

    return result;
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // ============================================================
  // PICK DATE FILTER
  // ============================================================

  Future<void> _pickFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: darkBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
      _dateFilter = 'Selected date';
    });
  }

  // ============================================================
  // PICK REPORT DATE
  // ============================================================

  Future<void> _pickReportDate(
      StateSetter setSheetState,
      ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reportDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: darkBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setSheetState(() {
      _reportDate = picked;
    });
  }

  // ============================================================
  // PICK ATTACHMENT
  // ============================================================

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'doc',
        'docx',
      ],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      return;
    }

    setState(() {
      _attachmentBytes = bytes;
      _attachmentName = file.name;
    });
  }

  // ============================================================
  // SUBMIT REPORT
  // ============================================================

  Future<void> _handleSubmit() async {
    final user = SessionService.instance.currentUser;

    if (user == null) {
      _showError(
        'User session not found. Please login again.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      String? attachmentPath;

      if (_attachmentBytes != null &&
          _attachmentName != null) {
        attachmentPath =
        await NgoStorageService.instance.uploadFile(
          folder: 'reports',
          fileName: _attachmentName!,
          bytes: _attachmentBytes!,
        );
      }

      final detailedDescription =
      _buildDetailedDescription();

      await NgoReportsService.instance.submitReport(
        user: user,
        title: _titleController.text.trim(),
        description: detailedDescription,
        attachmentPath: attachmentPath,
      );

      if (!mounted) return;

      _clearForm();

      Navigator.of(context).pop();

      _showSuccess(
        'Report submitted successfully!',
      );

      await _loadReports();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error =
        'Could not submit report. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _buildDetailedDescription() {
    final parts = <String>[];

    parts.add(
      'Category: $_selectedCategory',
    );

    parts.add(
      'Priority: $_selectedPriority',
    );

    parts.add(
      'Report Date: ${_formatDate(_reportDate)}',
    );

    final location =
    _locationController.text.trim();

    if (location.isNotEmpty) {
      parts.add('Location / Project: $location');
    }

    final description =
    _descriptionController.text.trim();

    if (description.isNotEmpty) {
      parts.add('Description: $description');
    }

    final observations =
    _observationsController.text.trim();

    if (observations.isNotEmpty) {
      parts.add(
        'Detailed Observations: $observations',
      );
    }

    final findings =
    _findingsController.text.trim();

    if (findings.isNotEmpty) {
      parts.add('Issues / Findings: $findings');
    }

    final action =
    _actionController.text.trim();

    if (action.isNotEmpty) {
      parts.add(
        'Recommended Action: $action',
      );
    }

    return parts.join('\n\n');
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _observationsController.clear();
    _findingsController.clear();
    _actionController.clear();

    _attachmentBytes = null;
    _attachmentName = null;
    _error = null;

    _selectedCategory = 'General';
    _selectedPriority = 'Medium';
    _reportDate = DateTime.now();
  }

  // ============================================================
  // SUCCESS / ERROR
  // ============================================================

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // Subtle primary gradient header — the main brand surface.
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: primaryGradient,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            size: 27,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Reports',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          // Very subtle blue-tinted backdrop for the whole screen.
          decoration: const BoxDecoration(
            gradient: lightBlueGradient,
          ),
          child: RefreshIndicator(
            onRefresh: _loadReports,
            color: darkBlue,
            backgroundColor: Colors.white,
            child: ListView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                14,
                10,
                14,
                24,
              ),
              children: [
                _buildSearchBar(),

                const SizedBox(height: 10),

                _buildFilterRow(),

                const SizedBox(height: 14),

                _buildSubmitButton(),

                const SizedBox(height: 18),

                _buildRecentReports(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search reports...',
        hintStyle: const TextStyle(
          color: greyText,
          fontSize: 11,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: darkBlue,
          size: 21,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
          onPressed: () {
            setState(() {
              _searchQuery = '';
            });
          },
          icon: const Icon(
            Icons.close_rounded,
            size: 18,
            color: greyText,
          ),
        )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: blue,
            width: 1.3,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER ROW
  // ============================================================

  Widget _buildFilterRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildFilterButton(
              icon: Icons.calendar_month_rounded,
              label: _dateFilter == 'Selected date'
                  ? _formatDate(_selectedDate!)
                  : _dateFilter,
              onTap: _showDateFilterMenu,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _buildFilterButton(
              icon: Icons.swap_vert_rounded,
              label: _sortOrder,
              onTap: _showSortMenu,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          // minHeight instead of a locked height: keeps the usual
          // 38px pill in the common case but lets it grow if a
          // larger system font scale needs more room for the label.
          constraints: const BoxConstraints(minHeight: 38),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: darkBlue,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: greyText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DATE MENU
  // ============================================================

  Future<void> _showDateFilterMenu() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildSelectionSheet(
          title: 'Filter Reports by Date',
          options: const [
            'All dates',
            'Today',
            'Last 7 days',
            'This month',
            'Selected date',
          ],
          selected: _dateFilter,
        );
      },
    );

    if (value == null) return;

    if (value == 'Selected date') {
      await _pickFilterDate();
      return;
    }

    setState(() {
      _dateFilter = value;
      _selectedDate = null;
    });
  }

  // ============================================================
  // SORT MENU
  // ============================================================

  Future<void> _showSortMenu() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildSelectionSheet(
          title: 'Sort Reports',
          options: const [
            'Newest first',
            'Oldest first',
          ],
          selected: _sortOrder,
        );
      },
    );

    if (value == null) return;

    setState(() {
      _sortOrder = value;
    });
  }

  Widget _buildSelectionSheet({
    required String title,
    required List<String> options,
    required String selected,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        24,
      ),
      decoration: const BoxDecoration(
        color: background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius:
                BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...options.map(
                  (option) {
                final isSelected =
                    option == selected;

                return ListTile(
                  contentPadding:
                  EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(
                      context,
                      option,
                    );
                  },
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? darkBlue
                        : greyText,
                  ),
                  title: Text(
                    option,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? darkBlue
                          : navy,
                      fontSize: 12,
                      fontWeight:
                      isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUBMIT BUTTON
  //
  // Was `SizedBox(height: 42)` around a button whose label had no
  // maxLines/overflow handling at all. At a larger system font
  // scale "Submit a New Report" needs more width than 42px of
  // height can comfortably lay out with the icon, which is exactly
  // the kind of thing that overflows on a real device but not an
  // emulator at 1.0x scale.
  //
  // Now uses the primary navy gradient to read as the screen's main
  // call to action.
  // ============================================================

  Widget _buildSubmitButton() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 42),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            gradient: primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _showSubmitReportDialog,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Submit a New Report',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REPORT LIST
  // ============================================================

  Widget _buildRecentReports() {
    final reports = _filteredReports;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Reports',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: navy,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${reports.length} found',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: greyText,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 9),

        if (_loadingReports)
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 30,
            ),
            child: Center(
              child: SizedBox(
                width: 23,
                height: 23,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                ),
              ),
            ),
          )
        else if (reports.isEmpty)
          _buildEmptyReports()
        else
          ...reports.map(
                (report) => _buildReportCard(report),
          ),
      ],
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyReports() {
    final hasFilters =
        _searchQuery.isNotEmpty ||
            _dateFilter != 'All dates';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilters
                ? Icons.search_off_rounded
                : Icons.description_outlined,
            size: 36,
            color: greyText,
          ),
          const SizedBox(height: 9),
          Text(
            hasFilters
                ? 'No matching reports'
                : 'No reports yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: navy,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasFilters
                ? 'Try changing your search or date filter.'
                : 'Reports you submit will appear here.',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: greyText,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REPORT CARD
  // ============================================================

  Widget _buildReportCard(NgoReport report) {
    final hasAttachment =
        report.attachmentPath != null &&
            report.attachmentPath!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: () {
            _showReportDetails(report);
          },
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              10,
              10,
              8,
              9,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: borderColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: 0.025),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 45,
                  margin: const EdgeInsets.only(
                    right: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                    _reportIconBackground(report),
                    borderRadius:
                    BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _reportIcon(report),
                    color: _reportIconColor(report),
                    size: 21,
                  ),
                ),

                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 4),

                      if (report.description != null &&
                          report.description!.isNotEmpty)
                        Text(
                          _cleanDescription(
                            report.description!,
                          ),
                          maxLines: 2,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: greyText,
                            fontSize: 9,
                            height: 1.25,
                          ),
                        ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          _buildStatusBadge(),

                          const SizedBox(width: 7),

                          Flexible(
                            child: Text(
                              _formatDate(
                                report.createdAt,
                              ),
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: greyText,
                                fontSize: 8.5,
                                fontWeight:
                                FontWeight.w500,
                              ),
                            ),
                          ),

                          if (hasAttachment) ...[
                            const SizedBox(width: 7),
                            const Icon(
                              Icons.attach_file_rounded,
                              size: 12,
                              color: greyText,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.only(
                    top: 22,
                    left: 5,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: greyText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _cleanDescription(String description) {
    final lines = description.split('\n');

    final usefulLines = lines.where((line) {
      final trimmed = line.trim();

      return trimmed.isNotEmpty &&
          !trimmed.startsWith('Category:') &&
          !trimmed.startsWith('Priority:') &&
          !trimmed.startsWith('Report Date:');
    }).toList();

    if (usefulLines.isEmpty) {
      return description;
    }

    return usefulLines.join(' ');
  }

  // ============================================================
  // STATUS BADGE
  //
  // Uses a soft success gradient rather than a flat fill, since a
  // "Submitted" badge is exactly the kind of small, important
  // status indicator the gradient guidance calls out.
  // ============================================================

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        gradient: successGradient,
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 10,
            color: green,
          ),
          SizedBox(width: 3),
          Text(
            'Submitted',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: green,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REPORT DETAILS
  // ============================================================

  void _showReportDetails(NgoReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: const BoxConstraints(
            maxHeight: 700,
          ),
          decoration: const BoxDecoration(
            color: background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                18,
                12,
                18,
                24,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          report.title,
                          maxLines: 2,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: navy,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      _buildStatusBadge(),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _formatDate(
                            report.createdAt,
                          ),
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: greyText,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _buildDetailSection(
                    'Report Information',
                    _parseReportDetails(
                      report.description,
                    ),
                  ),

                  if (report.attachmentPath != null &&
                      report.attachmentPath!.isNotEmpty)
                    _buildAttachmentInfo(
                      report.attachmentPath!,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, String> _parseReportDetails(
      String? description,
      ) {
    final result = <String, String>{};

    if (description == null ||
        description.trim().isEmpty) {
      return result;
    }

    final lines = description.split('\n');

    String? currentKey;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty) continue;

      final separator =
      trimmed.indexOf(':');

      if (separator > 0) {
        currentKey =
            trimmed.substring(0, separator).trim();

        final value =
        trimmed.substring(separator + 1).trim();

        result[currentKey] = value;
      } else if (currentKey != null) {
        result[currentKey] =
        '${result[currentKey]} $trimmed';
      }
    }

    return result;
  }

  Widget _buildDetailSection(
      String title,
      Map<String, String> details,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: navy,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 9),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: details.isEmpty
              ? const Text(
            'No additional details provided.',
            style: TextStyle(
              color: greyText,
              fontSize: 10,
            ),
          )
              : Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: details.entries
                .map(
                  (entry) => Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 11,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        color: greyText,
                        fontSize: 9,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      entry.value,
                      style:
                      const TextStyle(
                        color: navy,
                        fontSize: 11,
                        height: 1.35,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
                .toList(),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ATTACHMENT INFO
  //
  // Uses the soft info gradient — this is a highlighted card the
  // user should notice, not plain body content.
  // ============================================================

  Widget _buildAttachmentInfo(
      String path,
      ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: infoGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.attach_file_rounded,
            color: darkBlue,
            size: 22,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attachment available',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  path.split('/').last,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: greyText,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REPORT ICON
  // ============================================================

  IconData _reportIcon(NgoReport report) {
    final title =
    report.title.toLowerCase();

    if (title.contains('water')) {
      return Icons.water_drop_rounded;
    }

    if (title.contains('infrastructure')) {
      return Icons.construction_rounded;
    }

    if (title.contains('sanitation')) {
      return Icons.report_rounded;
    }

    if (title.contains('attendance')) {
      return Icons.groups_rounded;
    }

    return Icons.description_rounded;
  }

  Color _reportIconColor(NgoReport report) {
    final title =
    report.title.toLowerCase();

    if (title.contains('sanitation')) {
      return red;
    }

    if (title.contains('infrastructure')) {
      return green;
    }

    if (title.contains('water')) {
      return blue;
    }

    return blue;
  }

  Color _reportIconBackground(
      NgoReport report,
      ) {
    final title =
    report.title.toLowerCase();

    if (title.contains('sanitation')) {
      return lightRed;
    }

    if (title.contains('infrastructure')) {
      return lightGreen;
    }

    if (title.contains('water')) {
      return lightBlue;
    }

    return lightBlue;
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  // ============================================================
  // SUBMIT REPORT DIALOG
  // ============================================================

  void _showSubmitReportDialog() {
    _clearForm();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                MediaQuery.of(context)
                    .viewInsets
                    .bottom,
              ),
              child: Container(
                constraints:
                const BoxConstraints(
                  maxHeight: 760,
                ),
                decoration:
                const BoxDecoration(
                  color: background,
                  borderRadius:
                  BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child:
                SingleChildScrollView(
                  padding:
                  const EdgeInsets.fromLTRB(
                    18,
                    12,
                    18,
                    22,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration:
                            BoxDecoration(
                              color: borderColor,
                              borderRadius:
                              BorderRadius
                                  .circular(
                                10,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        Row(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            const Expanded(
                              child: Text(
                                'Submit a New Report',
                                maxLines: 1,
                                overflow:
                                TextOverflow
                                    .ellipsis,
                                style:
                                TextStyle(
                                  color: navy,
                                  fontSize: 17,
                                  fontWeight:
                                  FontWeight
                                      .w800,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                );
                              },
                              icon: const Icon(
                                Icons
                                    .close_rounded,
                                color: navy,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        _buildFormLabel(
                          'Report Title *',
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        TextFormField(
                          controller:
                          _titleController,
                          textInputAction:
                          TextInputAction.next,
                          validator: (value) {
                            if (value == null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return 'Please enter a report title.';
                            }

                            return null;
                          },
                          decoration:
                          _inputDecoration(
                            'Enter report title',
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Row(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Expanded(
                              child:
                              _buildDropdownField(
                                label:
                                'Category',
                                value:
                                _selectedCategory,
                                items: const [
                                  'General',
                                  'Attendance',
                                  'Infrastructure',
                                  'Sanitation',
                                  'Beneficiary',
                                  'Staff',
                                  'Finance',
                                  'Other',
                                ],
                                onChanged:
                                    (value) {
                                  if (value ==
                                      null) {
                                    return;
                                  }

                                  setSheetState(
                                        () {
                                      _selectedCategory =
                                          value;
                                    },
                                  );
                                },
                              ),
                            ),

                            const SizedBox(
                              width: 9,
                            ),

                            Expanded(
                              child:
                              _buildDropdownField(
                                label:
                                'Priority',
                                value:
                                _selectedPriority,
                                items: const [
                                  'Low',
                                  'Medium',
                                  'High',
                                  'Critical',
                                ],
                                onChanged:
                                    (value) {
                                  if (value ==
                                      null) {
                                    return;
                                  }

                                  setSheetState(
                                        () {
                                      _selectedPriority =
                                          value;
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        _buildFormLabel(
                          'Report Date',
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        InkWell(
                          onTap: () =>
                              _pickReportDate(
                                setSheetState,
                              ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            7,
                          ),
                          child: Container(
                            width:
                            double.infinity,
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration:
                            BoxDecoration(
                              color:
                              Colors.white,
                              borderRadius:
                              BorderRadius
                                  .circular(
                                7,
                              ),
                              border:
                              Border.all(
                                color:
                                borderColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons
                                      .calendar_month_rounded,
                                  size: 18,
                                  color:
                                  darkBlue,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Flexible(
                                  child: Text(
                                    _formatDate(
                                      _reportDate,
                                    ),
                                    maxLines: 1,
                                    overflow:
                                    TextOverflow
                                        .ellipsis,
                                    style:
                                    const TextStyle(
                                      color:
                                      navy,
                                      fontSize:
                                      11,
                                      fontWeight:
                                      FontWeight
                                          .w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        _buildFormLabel(
                          'Location / Project',
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        TextFormField(
                          controller:
                          _locationController,
                          textInputAction:
                          TextInputAction.next,
                          decoration:
                          _inputDecoration(
                            'Enter project or location',
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        _buildFormLabel(
                          'Description',
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        TextFormField(
                          controller:
                          _descriptionController,
                          maxLines: 3,
                          decoration:
                          _inputDecoration(
                            'Briefly describe the report...',
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        _buildFormLabel(
                          'Detailed Observations',
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        TextFormField(
                          controller:
                          _observationsController,
                          maxLines: 3,
                          decoration:
                          _inputDecoration(
                            'What did you observe?',
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        _buildFormLabel(
                          'Issues / Findings',
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        TextFormField(
                          controller:
                          _findingsController,
                          maxLines: 3,
                          decoration:
                          _inputDecoration(
                            'Mention issues or findings...',
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        _buildFormLabel(
                          'Recommended Action',
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        TextFormField(
                          controller:
                          _actionController,
                          maxLines: 3,
                          decoration:
                          _inputDecoration(
                            'What action do you recommend?',
                          ),
                        ),

                        const SizedBox(
                          height: 13,
                        ),

                        _buildFormLabel(
                          'Attachment',
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        ConstrainedBox(
                          constraints:
                          const BoxConstraints(
                            minHeight: 44,
                          ),
                          child: SizedBox(
                            width:
                            double.infinity,
                            child:
                            OutlinedButton.icon(
                              onPressed:
                                  () async {
                                await _pickAttachment();

                                setSheetState(
                                      () {},
                                );
                              },
                              icon: const Icon(
                                Icons
                                    .attach_file_rounded,
                                size: 20,
                              ),
                              label: Text(
                                _attachmentName ??
                                    'Attach file / photo (optional)',
                                maxLines: 1,
                                overflow:
                                TextOverflow
                                    .ellipsis,
                                style:
                                const TextStyle(
                                  fontSize:
                                  10.5,
                                  fontWeight:
                                  FontWeight
                                      .w700,
                                ),
                              ),
                              style:
                              OutlinedButton
                                  .styleFrom(
                                foregroundColor:
                                darkBlue,
                                backgroundColor:
                                lightBlue,
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal:
                                  12,
                                  vertical: 10,
                                ),
                                side: BorderSide
                                    .none,
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    7,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(
                            height: 9,
                          ),
                          Text(
                            _error!,
                            maxLines: 3,
                            overflow: TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              color: red,
                              fontSize: 10,
                              fontWeight:
                              FontWeight
                                  .w600,
                            ),
                          ),
                        ],

                        const SizedBox(
                          height: 17,
                        ),

                        ConstrainedBox(
                          constraints:
                          const BoxConstraints(
                            minHeight: 44,
                          ),
                          child: SizedBox(
                            width:
                            double.infinity,
                            child: Container(
                              decoration:
                              BoxDecoration(
                                gradient:
                                primaryGradient,
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  7,
                                ),
                              ),
                              child: Material(
                                color: Colors
                                    .transparent,
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  7,
                                ),
                                child: InkWell(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    7,
                                  ),
                                  onTap:
                                  _isSubmitting
                                      ? null
                                      : _handleSubmit,
                                  child: Padding(
                                    padding:
                                    const EdgeInsets
                                        .symmetric(
                                      horizontal:
                                      14,
                                      vertical: 10,
                                    ),
                                    child: Center(
                                      child:
                                      _isSubmitting
                                          ? const SizedBox(
                                        height:
                                        20,
                                        width:
                                        20,
                                        child:
                                        CircularProgressIndicator(
                                          strokeWidth:
                                          2.2,
                                          valueColor:
                                          AlwaysStoppedAnimation<
                                              Color>(
                                            Colors
                                                .white,
                                          ),
                                        ),
                                      )
                                          : const Text(
                                        'Submit Report',
                                        maxLines:
                                        1,
                                        overflow:
                                        TextOverflow
                                            .ellipsis,
                                        style:
                                        TextStyle(
                                          color: Colors
                                              .white,
                                          fontSize:
                                          12,
                                          fontWeight:
                                          FontWeight
                                              .w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // FORM HELPERS
  // ============================================================

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: navy,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        _buildFormLabel(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          items: items
              .map(
                (item) =>
                DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      color: navy,
                      fontSize: 10,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
          )
              .toList(),
          onChanged: onChanged,
          decoration:
          _inputDecoration('Select'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
      String hint,
      ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: greyText,
        fontSize: 11,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: blue,
          width: 1.3,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: red,
        ),
      ),
      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: red,
        ),
      ),
      errorStyle: const TextStyle(
        fontSize: 9,
      ),
    );
  }
}