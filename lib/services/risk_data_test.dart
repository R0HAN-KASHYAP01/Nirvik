
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
    print('[1/4] Loading institutes from Supabase...');

    final institutes = await repository.getInstitutes();

    print('Institutes found: ${institutes.length}');

    if (institutes.isEmpty) {
      print('');
      print('NO INSTITUTES FOUND');
      print('');
      print(
        'The repository is working, but the ngo_institutes '
        'table returned no rows.',
      );
      print('');
      print('RISK DATA REPOSITORY TEST FINISHED');
      return;
    }

    final firstInstitute = institutes.first;

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
    print('[2/4] Loading project risk data...');

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
    print('[3/4] Loading complete project risk input...');

    final riskInput =
        await repository.getProjectRiskInput(profileId);

    if (riskInput == null) {
      print('ERROR: Risk input could not be generated.');
      print('');
      print('RISK DATA REPOSITORY TEST FAILED');
      return;
    }

    print('Risk input generated successfully.');

    final projectInput =
        riskInput['project'];

    final inspectionsInput =
        riskInput['inspections'];

    final assignmentsInput =
        riskInput['assignments'];

    final findingsInput =
        riskInput['findings'];

    print('');
    print('Normalized Risk Input');
    print('---------------------');

    print(
      'Project data: '
      '${projectInput is Map ? projectInput : 'invalid'}',
    );

    print(
      'Inspections: '
      '${inspectionsInput is List ? inspectionsInput.length : 0}',
    );

    print(
      'Assignments: '
      '${assignmentsInput is List ? assignmentsInput.length : 0}',
    );

    print(
      'Findings: '
      '${findingsInput is List ? findingsInput.length : 0}',
    );

    print('');
    print('[4/4] Validating required Risk Engine fields...');

    final projectMap =
        projectInput is Map
            ? Map<String, dynamic>.from(projectInput)
            : <String, dynamic>{};

    final requiredProjectFields = <String>[
      'status',
      'risk_level',
      'total_inspections',
      'completed_inspections',
      'pending_inspections',
      'high_risk_findings',
    ];

    final missingFields = requiredProjectFields
        .where(
          (field) => !projectMap.containsKey(field),
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

    if (inspectionsInput is! List) {
      print('ERROR: inspections is not a List.');
      print('');
      print('RISK DATA REPOSITORY TEST FAILED');
      return;
    }

    print('All required project fields are present.');
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

