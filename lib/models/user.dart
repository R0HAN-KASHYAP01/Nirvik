// lib/models/user.dart

enum UserRole {
  official,
  inspector,
  ngoInstitute, // maps to DB role 'institute_rep'
  stateAdmin,   // maps to DB role 'state_admin'
  districtAdmin, // maps to DB role 'district_admin'
}

class AppUser {
  final String id; // Supabase auth uid
  final String name;
  final String email;
  final UserRole role;
  final String status; // pending, approved, rejected
  final String? department;
  final String? designation;
  final String? registrationNumber;
  final String? organizationId;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.department,
    this.designation,
    this.registrationNumber,
    this.organizationId,
  });
}