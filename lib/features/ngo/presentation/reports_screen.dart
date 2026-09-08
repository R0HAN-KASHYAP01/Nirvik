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

  Uint8List? _attachmentBytes;
  String? _attachmentName;

  bool _isSubmitting = false;
  bool _loadingReports = true;

  String? _error;

  List<NgoReport> _reports = [];

  int _selectedTab = 0;

  static const Color navy = Color(0xFF123E68);
  static const Color darkBlue = Color(0xFF0D4778);
  static const Color blue = Color(0xFF1769AA);

  static const Color background = Color(0xFFF4F8FB);
  static const Color lightBlue = Color(0xFFEAF4FB);

  static const Color green = Color(0xFF159447);
  static const Color lightGreen = Color(0xFFE5F7ED);

  static const Color red = Color(0xFFD94141);
  static const Color lightRed = Color(0xFFFDE8E8);

  static const Color greyText = Color(0xFF6B7785);
  static const Color borderColor = Color(0xFFDDE6ED);

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
    }
  }

  // ============================================================
  // PICK ATTACHMENT
  // ============================================================

  Future<void> _pickAttachment() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: [
      'pdf',
      'jpg',
      'jpeg',
      'png',
    ],
  );

  if (files.isEmpty) {
    return;
  }

  final file = files.first;
  final bytes = await file.readAsBytes();

  if (bytes.isEmpty) {
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
      _showError('User session not found. Please login again.');
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

      await NgoReportsService.instance.submitReport(
        user: user,
        title: _titleController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        attachmentPath: attachmentPath,
      );

      if (!mounted) return;

      _titleController.clear();
      _descriptionController.clear();

      setState(() {
        _attachmentBytes = null;
        _attachmentName = null;
      });

      Navigator.of(context).pop();

      _showSuccess('Report submitted successfully!');

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

  // ============================================================
  // SUCCESS
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
          content: Text(message),
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
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

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
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReports,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              14,
              10,
              14,
              24,
            ),
            children: [
              // ==================================================
              // FILTER TABS
              // ==================================================

              _buildTabs(),

              const SizedBox(height: 10),

              // ==================================================
              // SUBMIT NEW REPORT BUTTON
              // ==================================================

              _buildSubmitButton(),

              const SizedBox(height: 18),

              // ==================================================
              // RECENT REPORTS
              // ==================================================

              _buildRecentReports(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    final tabs = [
      'All',
      'My Reports',
      'Under Review',
      'Resolved',
    ];

    return SizedBox(
      height: 34,
      child: Row(
        children: List.generate(
          tabs.length,
          (index) {
            final selected = _selectedTab == index;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == tabs.length - 1 ? 0 : 5,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = index;
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? darkBlue
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? darkBlue
                            : borderColor,
                      ),
                    ),
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : navy,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // SUBMIT BUTTON
  // ============================================================

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: ElevatedButton.icon(
        onPressed: _showSubmitReportDialog,
        icon: const Icon(
          Icons.add_rounded,
          size: 20,
        ),
        label: const Text(
          'Submit a New Report',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: darkBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RECENT REPORTS
  // ============================================================

  Widget _buildRecentReports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Reports',
              style: TextStyle(
                color: navy,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),

            const Spacer(),

            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = 0;
                });
              },
              child: const Text(
                'View all',
                style: TextStyle(
                  color: blue,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 9),

        if (_loadingReports)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
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
        else if (_reports.isEmpty)
          _buildEmptyReports()
        else
          ..._reports.map(
            (report) => _buildReportCard(report),
          ),
      ],
    );
  }

  // ============================================================
  // EMPTY REPORTS
  // ============================================================

  Widget _buildEmptyReports() {
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
      child: const Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 36,
            color: greyText,
          ),

          SizedBox(height: 9),

          Text(
            'No reports yet',
            style: TextStyle(
              color: navy,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),

          SizedBox(height: 4),

          Text(
            'Reports you submit will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
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
      padding: const EdgeInsets.fromLTRB(
        10,
        10,
        8,
        9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------
          // REPORT ICON
          // ----------------------------------------------------

          Container(
            width: 34,
            height: 43,
            margin: const EdgeInsets.only(
              right: 10,
            ),
            decoration: BoxDecoration(
              color: _reportIconBackground(report),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _reportIcon(report),
              color: _reportIconColor(report),
              size: 21,
            ),
          ),

          // ----------------------------------------------------
          // REPORT CONTENT
          // ----------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                if (report.description != null &&
                    report.description!.isNotEmpty)
                  Text(
                    report.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: greyText,
                      fontSize: 9,
                      height: 1.25,
                    ),
                  ),

                const SizedBox(height: 5),

                // STATUS
                _buildStatusBadge(),

                const SizedBox(height: 5),

                // DATE + ATTACHMENT
                Row(
                  children: [
                    Text(
                      _formatDate(report.createdAt),
                      style: const TextStyle(
                        color: greyText,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    if (hasAttachment) ...[
                      const SizedBox(width: 8),

                      const Icon(
                        Icons.attach_file_rounded,
                        size: 12,
                        color: greyText,
                      ),

                      const SizedBox(width: 2),

                      const Text(
                        '1 attachment',
                        style: TextStyle(
                          color: greyText,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ----------------------------------------------------
          // ARROW
          // ----------------------------------------------------

          const Padding(
            padding: EdgeInsets.only(
              top: 25,
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
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: lightGreen,
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
  // REPORT ICON
  // ============================================================

  IconData _reportIcon(NgoReport report) {
    final title = report.title.toLowerCase();

    if (title.contains('water')) {
      return Icons.description_rounded;
    }

    if (title.contains('infrastructure')) {
      return Icons.description_rounded;
    }

    if (title.contains('sanitation')) {
      return Icons.report_rounded;
    }

    return Icons.description_rounded;
  }

  Color _reportIconColor(NgoReport report) {
    final title = report.title.toLowerCase();

    if (title.contains('sanitation')) {
      return red;
    }

    if (title.contains('infrastructure')) {
      return green;
    }

    return blue;
  }

  Color _reportIconBackground(NgoReport report) {
    final title = report.title.toLowerCase();

    if (title.contains('sanitation')) {
      return lightRed;
    }

    if (title.contains('infrastructure')) {
      return lightGreen;
    }

    return lightBlue;
  }

  // ============================================================
  // DATE
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
    _titleController.clear();
    _descriptionController.clear();

    _attachmentBytes = null;
    _attachmentName = null;
    _error = null;

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
                    MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
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
                        // --------------------------------------
                        // HANDLE
                        // --------------------------------------

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

                        // --------------------------------------
                        // TITLE
                        // --------------------------------------

                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Submit a New Report',
                                style: TextStyle(
                                  color: navy,
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.w800,
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

                        const SizedBox(height: 15),

                        // --------------------------------------
                        // TITLE FIELD
                        // --------------------------------------

                        const Text(
                          'Report Title',
                          style: TextStyle(
                            color: navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 6),

                        TextFormField(
                          controller: _titleController,
                          textInputAction:
                              TextInputAction.next,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Please enter a report title.';
                            }

                            return null;
                          },
                          decoration:
                              _inputDecoration(
                            'Enter report title',
                          ),
                        ),

                        const SizedBox(height: 13),

                        // --------------------------------------
                        // DESCRIPTION
                        // --------------------------------------

                        const Text(
                          'Description',
                          style: TextStyle(
                            color: navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 6),

                        TextFormField(
                          controller:
                              _descriptionController,
                          maxLines: 4,
                          decoration:
                              _inputDecoration(
                            'Describe the issue or report...',
                          ),
                        ),

                        const SizedBox(height: 13),

                        // --------------------------------------
                        // ATTACHMENT
                        // --------------------------------------

                        const Text(
                          'Attachment',
                          style: TextStyle(
                            color: navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 6),

                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _pickAttachment();

                              setSheetState(() {});
                            },
                            icon: const Icon(
                              Icons.attach_file_rounded,
                              size: 20,
                            ),
                            label: Text(
                              _attachmentName ??
                                  'Attach file / photo (optional)',
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                            style:
                                OutlinedButton.styleFrom(
                              foregroundColor: darkBlue,
                              backgroundColor:
                                  lightBlue,
                              side: BorderSide.none,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(7),
                              ),
                            ),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 9),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: red,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // --------------------------------------
                        // SUBMIT
                        // --------------------------------------

                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : _handleSubmit,
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor: darkBlue,
                              foregroundColor:
                                  Colors.white,
                              elevation: 0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(7),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor:
                                          AlwaysStoppedAnimation<
                                              Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Submit Report',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w800,
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
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration(String hint) {
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
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: blue,
          width: 1.3,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: red,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
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