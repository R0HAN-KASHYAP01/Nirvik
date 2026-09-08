
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../features/dashboard/data/risk_data_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  final repository = RiskDataRepository();

  print('========================================');
  print('SENTINAL RISK DATA REPOSITORY TEST');
  print('========================================');

  try {
    print('[1/3] Loading institutes from Supabase...');

    // getInstitutes() was removed from RiskDataRepository.
    // Load institute records directly using the Supabase client.
    final institutes = await Supabase.instance.client
        .from('ngo_institutes')
        .select('profile_id, institute_name')
        .order('created_at', ascending: true);

    print('Institutes found: ${institutes.length}');

    if (institutes.isEmpty) {
      print('');
      print('NO INSTITUTES FOUND');
      print('');
      print(
        'The repository cannot be tested because the '
        'ngo_institutes table returned no rows.',
      );
      print('');
      print('RISK DATA REPOSITORY TEST FINISHED');
      return;
    }

    final firstInstitute =
        Map<String, dynamic>.from(institutes.first);

    final profileId =
        firstInstitute['profile_id']?.toString();

    print('First institute profile_id: $profileId');

    if (profileId == null || profileId.isEmpty) {
      print('');
      print('ERROR: First institute has no profile_id.');
      print('');
      print('RISK DATA REPOSITORY TEST FAILED');
      return;
    }

    print('');
    print('[2/3] Loading project risk data...');

    final project =
        await repository.getProjectRiskData(profileId);

    if (project == null) {
      print('ERROR: Project could not be loaded.');
      print('');
      print('RISK DATA REPOSITORY TEST FAILED');
      return;
    }

    print('Project data loaded successfully.');
    print('Project keys: ${project.keys.toList()}');

    print('');
    print('[3/3] Loading complete project risk input...');

    final riskInput =
        await repository.getProjectRiskInput(profileId);

    print('Risk input generated successfully.');

    final projectInput = riskInput['project'];
    final inspectionsInput = riskInput['inspections'];

    if (projectInput is! Map<String, dynamic>) {
      print('ERROR: project is not a Map<String, dynamic>.');
      print('');
      print('RISK DATA REPOSITORY TEST FAILED');
      return;
    }

    if (inspectionsInput is! List) {
      print('ERROR: inspections is not a List.');
      print('');
      print('RISK DATA REPOSITORY TEST FAILED');
      return;
    }

    print('');
    print('Normalized Risk Input');
    print('---------------------');

    print('Project data: $projectInput');
    print('Inspections: ${inspectionsInput.length}');

    print('');
    print('Validating required Risk Engine fields...');

    // These are the project-level fields currently produced
    // by RiskDataRepository.
    //
    // risk_level is intentionally NOT required here because
    // ngo_institutes does not contain a risk_level column.
    final requiredProjectFields = <String>[
      'status',
      'total_assignments',
      'pending_assignments',
      'completed_assignments',
      'total_inspections',
      'completed_inspections',
      'high_risk_findings',
      'open_findings',
      'inspection_submission_count',
      'finding_count',
    ];

    final missingFields = requiredProjectFields
        .where(
          (field) => !projectInput.containsKey(field),
        )
        .toList();

    if (missingFields.isNotEmpty) {
      print(
        'ERROR: Missing project fields: $missingFields',
      );
      print('');
      print('RISK DATA REPOSITORY TEST FAILED');
      return;
    }

    print('All required project fields are present.');

    print('');
    print('Validating inspection records...');

    for (final item in inspectionsInput) {
      if (item is! Map<String, dynamic>) {
        print(
          'ERROR: An inspection record is not '
          'Map<String, dynamic>.',
        );
        print('');
        print('RISK DATA REPOSITORY TEST FAILED');
        return;
      }
    }

    print('Inspection records validated successfully.');

    print('');
    print('========================================');
    print('RISK DATA REPOSITORY TEST SUCCESSFUL');
    print('========================================');
  } catch (error) {
    print('');
    print('ERROR: $error');
    print('');
    print('========================================');
    print('RISK DATA REPOSITORY TEST FAILED');
    print('========================================');
  }
}

