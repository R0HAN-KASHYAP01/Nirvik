
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

      print('\n[1/4] Loading institutes from Supabase...');

      final institutes = await repository.getInstitutes();

      print('Institutes found: ${institutes.length}');

      expect(
        institutes,
        isNotEmpty,
        reason: 'No NGO institutes were found in Supabase.',
      );

      final firstInstitute = institutes.first;

      final instituteProfileId =
          firstInstitute['profile_id']?.toString() ??
          firstInstitute['id']?.toString();

      expect(
        instituteProfileId,
        isNotNull,
        reason: 'The first institute has no profile_id or id.',
      );

      print('Selected institute: $instituteProfileId');

      print('\n[2/4] Loading project data...');

      final projectData =
          await repository.getProjectRiskData(instituteProfileId!);

      expect(
        projectData,
        isNotNull,
        reason: 'Project risk data could not be built.',
      );

      print('Project data loaded successfully.');

      print('\n[3/4] Building complete risk input...');

      final riskInput =
          await repository.getProjectRiskInput(instituteProfileId);

      expect(
        riskInput,
        isNotNull,
        reason: 'Complete project risk input could not be built.',
      );

      final input = riskInput!;

      expect(input['attendance'], isA<Map<String, dynamic>>());
      expect(input['project'], isA<Map<String, dynamic>>());
      expect(input['inspections'], isA<List<dynamic>>());

      final attendance =
          input['attendance'] as Map<String, dynamic>;

      final project =
          input['project'] as Map<String, dynamic>;

      final inspections =
          input['inspections'] as List<dynamic>;

      print('Attendance input:');
      print(attendance);

      print('\nProject input:');
      print(project);

      print('\nInspection records: ${inspections.length}');

      print('\n[4/4] Validating required project fields...');

      expect(project.containsKey('status'), isTrue);
      expect(project.containsKey('risk_level'), isTrue);
      expect(project.containsKey('total_inspections'), isTrue);
      expect(project.containsKey('completed_inspections'), isTrue);
      expect(project.containsKey('pending_inspections'), isTrue);
      expect(project.containsKey('high_risk_findings'), isTrue);

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
