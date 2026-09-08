import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/project.dart';

/// Repository responsible for loading project/institute data
/// from Supabase.
///
/// Current database source:
/// ngo_institutes
///
/// The repository converts Supabase rows into the existing
/// Project model used by the Projects UI.
class ProjectsRepository {
  ProjectsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetch all registered projects/institutes.
  ///
  /// The current ngo_institutes table does not contain every
  /// field required by the Project model, so fields that are
  /// not available are given safe defaults.
  Future<List<Project>> getProjects() async {
    final response = await _client
        .from('ngo_institutes')
        .select()
        .order('created_at', ascending: false);

    final rows = response as List<dynamic>;

    return rows
        .whereType<Map<String, dynamic>>()
        .map(_mapRowToProject)
        .toList();
  }

  /// Fetch one project/institute by Supabase profile ID.
  Future<Project?> getProjectById(String profileId) async {
    final response = await _client
        .from('ngo_institutes')
        .select()
        .eq('profile_id', profileId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return _mapRowToProject(response);
  }

  /// Convert a Supabase ngo_institutes row into the existing
  /// Project model.
  Project _mapRowToProject(Map<String, dynamic> row) {
    final profileId = row['profile_id']?.toString();

    final id = _stringValue(
      row['registration_number'],
      fallback: profileId ?? 'Unknown',
    );

    final name = _stringValue(
      row['institute_name'],
      fallback: 'Unnamed Institute',
    );

    final type = _stringValue(
      row['category'],
      fallback: row['scheme_type']?.toString() ?? 'Institute',
    );

    final location = _buildLocation(row);

    final riskLevel = _parseRiskLevel(row['risk_level']);

    final status = _parseProjectStatus(row['status']);

    final lastInspectionDate = _parseDate(
      row['updated_at'] ?? row['created_at'],
    );

    return Project(
      id: id,

      // Preserve the real Supabase identity separately from
      // the display/registration identifier.
      profileId: profileId,

      name: name,
      type: type,
      location: location,
      status: status,
      riskLevel: riskLevel,
      lastInspectionDate: lastInspectionDate,

      // ngo_institutes currently does not store project-incharge
      // details directly.
      inchargeName: 'Not available',
      inchargeRole: 'Project Incharge',
      inchargePhone: 'Not available',
      inchargeEmail: 'Not available',

      // Inspection counts are not directly available from
      // ngo_institutes.
      totalInspections: 0,
      completedInspections: 0,
      pendingInspections: 0,
      highRiskFindings: 0,

      recentInspections: const [],
    );
  }

  /// Build a readable location from address and coordinates.
  String _buildLocation(Map<String, dynamic> row) {
    final address = row['address']?.toString().trim();

    if (address != null && address.isNotEmpty) {
      return address;
    }

    final latitude = row['latitude'];
    final longitude = row['longitude'];

    if (latitude != null && longitude != null) {
      return '$latitude, $longitude';
    }

    return 'Location not available';
  }

  /// Parse risk level safely.
  ///
  /// ngo_institutes currently does not define risk_level,
  /// therefore this normally falls back to low.
  RiskLevel _parseRiskLevel(dynamic value) {
    final risk = value?.toString().toLowerCase();

    switch (risk) {
      case 'high':
        return RiskLevel.high;
      case 'medium':
        return RiskLevel.medium;
      case 'low':
      default:
        return RiskLevel.low;
    }
  }

  /// Parse project status safely.
  ///
  /// ngo_institutes currently does not define status,
  /// therefore this normally falls back to active.
  ProjectStatus _parseProjectStatus(dynamic value) {
    final status = value?.toString().toLowerCase();

    switch (status) {
      case 'under_review':
      case 'under review':
      case 'review':
        return ProjectStatus.underReview;
      case 'active':
      default:
        return ProjectStatus.active;
    }
  }

  /// Convert a value into a non-empty string.
  String _stringValue(dynamic value, {required String fallback}) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return fallback;
    }

    return text;
  }

  /// Parse a database date safely.
  DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value != null) {
      final parsed = DateTime.tryParse(value.toString());

      if (parsed != null) {
        return parsed;
      }
    }

    return DateTime.now();
  }
}