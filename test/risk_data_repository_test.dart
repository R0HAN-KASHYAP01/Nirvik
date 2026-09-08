
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../lib/core/config/supabase_config.dart';
import '../lib/features/dashboard/data/risk_data_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'RiskDataRepository can load project risk data from Supabase',
    () async {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      );

      final repository = RiskDataRepository();

      print('\n==============================================');
      print('SENTINAL RISK DATA REPOSITORY TEST');
      print('==============================================');

      print('\n[1/3] Loading institutes from Supabase...');

      // getInstitutes() no longer exists in RiskDataRepository.
      // Fetch an institute directly to obtain a valid profile_id
      // for repository testing.
      final institutes = await Supabase.instance.client
          .from('ngo_institutes')
          .select('profile_id, institute_name')
          .order('created_at', ascending: true);

      print('Institutes found: ${institutes.length}');

      expect(
        institutes,
        isNotEmpty,
        reason: 'No NGO institutes were found in Supabase.',
      );

      final firstInstitute =
          Map<String, dynamic>.from(institutes.first);

      final instituteProfileId =
          firstInstitute['profile_id']?.toString();

      expect(
        instituteProfileId,
        isNotNull,
        reason: 'The first institute has no profile_id.',
      );

      expect(
        instituteProfileId,
        isNotEmpty,
        reason: 'The first institute has an empty profile_id.',
      );

      print('Selected institute: $instituteProfileId');

      print('\n[2/3] Loading project data...');

      final projectData =
          await repository.getProjectRiskData(
        instituteProfileId!,
      );

      expect(
        projectData,
        isNotNull,
        reason: 'Project risk data could not be loaded.',
      );

      print('Project data loaded successfully.');
      print('Project data: $projectData');

      print('\n[3/3] Building complete risk input...');

      final riskInput =
          await repository.getProjectRiskInput(
        instituteProfileId,
      );

      expect(
        riskInput,
        isA<Map<String, dynamic>>(),
        reason: 'Complete project risk input could not be built.',
      );

      final input = riskInput;

      expect(
        input['project'],
        isA<Map<String, dynamic>>(),
      );

      expect(
        input['inspections'],
        isA<List<dynamic>>(),
      );

      final project =
          input['project'] as Map<String, dynamic>;

      final inspections =
          input['inspections'] as List<dynamic>;

      print('\nProject input:');
      print(project);

      print('\nInspection records: ${inspections.length}');

      print('\nValidating required project fields...');

      // risk_level is deliberately NOT checked here.
      //
      // Current architecture:
      // ngo_institutes -> project data
      // inspection submissions -> historical risk_level
      // Risk Engine -> current risk_score / risk_level
      expect(
        project.containsKey('status'),
        isTrue,
      );

      expect(
        project.containsKey('total_assignments'),
        isTrue,
      );

      expect(
        project.containsKey('pending_assignments'),
        isTrue,
      );

      expect(
        project.containsKey('completed_assignments'),
        isTrue,
      );

      expect(
        project.containsKey('total_inspections'),
        isTrue,
      );

      expect(
        project.containsKey('completed_inspections'),
        isTrue,
      );

      expect(
        project.containsKey('high_risk_findings'),
        isTrue,
      );

      expect(
        project.containsKey('open_findings'),
        isTrue,
      );

      expect(
        project.containsKey('inspection_submission_count'),
        isTrue,
      );

      expect(
        project.containsKey('finding_count'),
        isTrue,
      );

      expect(
        inspections.every(
          (item) => item is Map<String, dynamic>,
        ),
        isTrue,
      );

      print('Required fields validated successfully.');

      print('\n==============================================');
      print('RISK DATA REPOSITORY TEST SUCCESSFUL');
      print('==============================================');
    },
  );
}

