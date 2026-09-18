// lib/services/auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart';

class AuthResult {
  final bool success;
  final AppUser? user;
  final String? errorMessage;

  const AuthResult.success(this.user)
      : success = true,
        errorMessage = null;

  const AuthResult.failure(this.errorMessage)
      : success = false,
        user = null;
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResult> login(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final authUser = res.user;

      if (authUser == null) {
        return const AuthResult.failure('Login failed.');
      }

      final user = await _loadFullProfile(
        authUser.id,
        authUser.email ?? email,
      );

      if (user == null) {
        await _client.auth.signOut();
        return const AuthResult.failure(
          'No profile found for this account.',
        );
      }

      // Mirror the same approval gate the web admin login enforces.
      if (user.status != 'approved') {
        await _client.auth.signOut();
        final message = switch (user.status) {
          'pending' =>
            'Your registration is still under review by the admin.',
          'rejected' =>
            'Your registration was rejected. Please contact your administrator.',
          _ => 'This account is not active.',
        };
        return AuthResult.failure(message);
      }

      return AuthResult.success(user);
    } on AuthException catch (e, stackTrace) {
      debugPrint('LOGIN AUTH ERROR: ${e.message}');
      debugPrint('LOGIN AUTH CODE: ${e.statusCode}');
      debugPrint('LOGIN AUTH STACK TRACE: $stackTrace');

      return AuthResult.failure(e.message);
    } on PostgrestException catch (e, stackTrace) {
      debugPrint('LOGIN DATABASE ERROR: ${e.message}');
      debugPrint('LOGIN DATABASE CODE: ${e.code}');
      debugPrint('LOGIN DATABASE DETAILS: ${e.details}');
      debugPrint('LOGIN DATABASE HINT: ${e.hint}');
      debugPrint('LOGIN DATABASE STACK TRACE: $stackTrace');

      return AuthResult.failure(e.message);
    } catch (e, stackTrace) {
      debugPrint('LOGIN ERROR: $e');
      debugPrint('LOGIN STACK TRACE: $stackTrace');

      return AuthResult.failure(
        'Login error: $e',
      );
    }
  }

  /// NOTE: registration now happens on the web app only (register/page.js).
  /// This is left only so nothing else in the app that references it breaks
  /// at compile time. It is not wired to any working table set — do not
  /// use it for the 5 real roles without updating it to match
  /// registrationConfig.js first.
  Future<AuthResult> signUp({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required UserRole role,
    String? department,
    String? designation,
    String? organizationName,
    String? registrationNumber,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );

      final authUser = res.user;

      if (authUser == null) {
        return const AuthResult.failure('Sign up failed.');
      }

      await _client.from('profiles').insert({
        'id': authUser.id,
        'full_name': fullName,
        'role': _roleToDb(role),
        'status': 'pending',
      });

      final user = await _loadFullProfile(authUser.id, email);

      return AuthResult.success(user);
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return const AuthResult.failure(
          'An account with this information already exists.',
        );
      }

      return AuthResult.failure(e.message);
    } catch (_) {
      return const AuthResult.failure(
        'Something went wrong. Please try again.',
      );
    }
  }

  Future<AuthResult> restoreSession() async {
    try {
      final session = _client.auth.currentSession;

      if (session == null) {
        return const AuthResult.failure(
          'No active session found.',
        );
      }

      final authUser = session.user;

      final user = await _loadFullProfile(
        authUser.id,
        authUser.email ?? '',
      );

      if (user == null) {
        return const AuthResult.failure(
          'No profile found for this account.',
        );
      }

      if (user.status != 'approved') {
        await _client.auth.signOut();
        return const AuthResult.failure(
          'This account is not currently active.',
        );
      }

      return AuthResult.success(user);
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } on PostgrestException catch (e) {
      return AuthResult.failure(e.message);
    } catch (_) {
      return const AuthResult.failure(
        'Unable to restore the current session.',
      );
    }
  }

  Future<AppUser?> _loadFullProfile(
    String id,
    String email,
  ) async {
    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (profile == null) {
      return null;
    }

    final role = _roleFromDb(
      profile['role'] as String,
    );

    Map<String, dynamic>? roleData;

    switch (role) {
      case UserRole.official:
        roleData = await _client
            .from('officials')
            .select()
            .eq('profile_id', id)
            .maybeSingle();
        break;

      case UserRole.inspector:
        roleData = await _client
            .from('inspectors')
            .select()
            .eq('profile_id', id)
            .maybeSingle();
        break;

      case UserRole.ngoInstitute:
        roleData = await _client
            .from('institute_reps')
            .select()
            .eq('profile_id', id)
            .maybeSingle();
        break;

      case UserRole.stateAdmin:
        roleData = await _client
            .from('state_administrators')
            .select()
            .eq('profile_id', id)
            .maybeSingle();
        break;

      case UserRole.districtAdmin:
        roleData = await _client
            .from('district_administrators')
            .select()
            .eq('profile_id', id)
            .maybeSingle();
        break;
    }

    return AppUser(
      id: id,
      name: profile['full_name'] as String,
      email: email,
      role: role,
      status: profile['status'] as String,
      department: roleData?['department'] as String?,
      designation: roleData?['designation'] as String?,
      registrationNumber: roleData?['registration_number'] as String?,
      organizationId: roleData?['organization_id'] as String?,
      district: roleData?['district'] as String?,   // NEW
      state: roleData?['state'] as String?,          // NEW
    );
  }

  Future<void> logout() => _client.auth.signOut();

  String _roleToDb(UserRole role) {
    switch (role) {
      case UserRole.official:
        return 'official';
      case UserRole.inspector:
        return 'inspector';
      case UserRole.ngoInstitute:
        return 'institute_rep';
      case UserRole.stateAdmin:
        return 'state_admin';
      case UserRole.districtAdmin:
        return 'district_admin';
    }
  }

  UserRole _roleFromDb(String value) {
    switch (value) {
      case 'official':
        return UserRole.official;
      case 'inspector':
        return UserRole.inspector;
      case 'institute_rep':
        return UserRole.ngoInstitute;
      case 'state_admin':
        return UserRole.stateAdmin;
      case 'district_admin':
        return UserRole.districtAdmin;
      default:
        throw Exception('Unknown role: $value');
    }
  }
}