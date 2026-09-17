// lib/utils/scheme_catalog.dart

class SchemeInfo {
  final String code;
  final String category;
  final String label;

  const SchemeInfo({
    required this.code,
    required this.category,
    required this.label,
  });
}

const List<Map<String, String>> _categoryList = [
  {'value': 'educational', 'label': 'Educational'},
  {'value': 'economic_development', 'label': 'Economic Development'},
  {'value': 'social_empowerment', 'label': 'Social Empowerment'},
];

const List<SchemeInfo> schemes = [
  SchemeInfo(code: 'post_matric_scholarship_sc', category: 'educational', label: 'Post-Matric Scholarship – SC'),
  SchemeInfo(code: 'pre_matric_scholarship_sc_others', category: 'educational', label: 'Pre-Matric Scholarship – SC & Others'),
  SchemeInfo(code: 'pm_yasasvi', category: 'educational', label: 'PM YASASVI'),
  SchemeInfo(code: 'shreyas_sc', category: 'educational', label: 'SHREYAS – SC'),
  SchemeInfo(code: 'seed', category: 'economic_development', label: 'SEED'),
  SchemeInfo(code: 'visvas_obc', category: 'economic_development', label: 'VISVAS – OBC'),
  SchemeInfo(code: 'namaste', category: 'economic_development', label: 'NAMASTE'),
  SchemeInfo(code: 'pm_daksh', category: 'economic_development', label: 'PM-DAKSH'),
  SchemeInfo(code: 'pm_ajay', category: 'social_empowerment', label: 'PM-AJAY'),
  SchemeInfo(code: 'pcr_poa_strengthening', category: 'social_empowerment', label: 'Strengthening Machinery for PCR/PoA Acts'),
  SchemeInfo(code: 'avyay', category: 'social_empowerment', label: 'AVYAY'),
  SchemeInfo(code: 'smile', category: 'social_empowerment', label: 'SMILE'),
];

String schemeLabel(String? code) {
  if (code == null) return '—';
  return schemes.firstWhere(
        (s) => s.code == code,
    orElse: () => SchemeInfo(code: code, category: '', label: code),
  ).label;
}

String categoryLabel(String? value) {
  if (value == null) return '—';
  final match = _categoryList.firstWhere(
        (c) => c['value'] == value,
    orElse: () => {'value': value, 'label': value},
  );
  return match['label']!;
}