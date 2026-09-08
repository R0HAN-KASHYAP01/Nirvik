
import 'ai_attendance_service.dart';

/// Temporary integration test for the Sentinal Risk Engine.
///
/// This file is only used to verify:
///
/// Flutter
///   ↓
/// AiAttendanceService
///   ↓
/// FastAPI Risk API
///   ↓
/// Risk Engine
///
/// After successful verification, this test file can be removed
/// or replaced with the real application integration.
Future<void> testRiskApiIntegration() async {
  final service = AiAttendanceService();

  print('========================================');
  print('SENTINAL FLUTTER → RISK API TEST');
  print('========================================');

  try {
    print('[1/3] Checking Risk Engine health...');

    final healthy = await service.isRiskEngineHealthy();

    if (!healthy) {
      print('FAILED: Risk Engine is not healthy.');
      return;
    }

    print('SUCCESS: Risk Engine is healthy.');

    print('[2/3] Sending test project data...');

    final result = await service.calculateProjectRisk(
      attendance: <String, dynamic>{
        'total_tracked': 10,
        'staff': 2,
        'beneficiary': 7,
        'unknown': 1,
        'duration_seconds': 600,
        'observation_count': 120,
      },
      project: <String, dynamic>{
        'status': 'active',
        'risk_level': 'medium',
        'total_inspections': 10,
        'completed_inspections': 7,
        'pending_inspections': 3,
        'high_risk_findings': 1,
      },
      inspections: <Map<String, dynamic>>[
        <String, dynamic>{
          'risk_level': 'high',
          'status': 'completed',
        },
        <String, dynamic>{
          'risk_level': 'medium',
          'status': 'completed',
        },
        <String, dynamic>{
          'risk_level': 'low',
          'status': 'pending',
        },
      ],
    );

    print('SUCCESS: Risk API returned a response.');

    print('[3/3] Reading risk result...');

    print('Risk score : ${result['risk_score']}');
    print('Risk level : ${result['risk_level']}');
    print('Anomalies  : ${result['anomaly_count']}');

    print('Component scores:');
    print('  attendance : ${result['component_scores']?['attendance']}');
    print('  project    : ${result['component_scores']?['project']}');
    print('  inspection : ${result['component_scores']?['inspection']}');
    print('  anomalies  : ${result['component_scores']?['anomalies']}');

    print('Reasons:');

    final reasons = result['reasons'];

    if (reasons is List) {
      for (final reason in reasons) {
        print('  - $reason');
      }
    }

    print('========================================');
    print('FLUTTER → RISK API TEST SUCCESSFUL');
    print('========================================');
  } on AiAttendanceApiException catch (error) {
    print('FAILED: AI API error');
    print(error);
  } catch (error) {
    print('FAILED: Unexpected error');
    print(error);
  }
}

