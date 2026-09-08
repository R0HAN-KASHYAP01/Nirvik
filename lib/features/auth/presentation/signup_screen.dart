import 'package:flutter/material.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/auth_service.dart';
import '../../../models/user.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();
  final _organizationController = TextEditingController();
  final _registrationController = TextEditingController();

  UserRole _role = UserRole.official;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    _organizationController.dispose();
    _registrationController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'Please agree to the Terms & Conditions and Privacy Policy.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.instance.signUp(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      role: _role,
      department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
      designation: _designationController.text.trim().isEmpty ? null : _designationController.text.trim(),
      organizationName: _organizationController.text.trim().isEmpty ? null : _organizationController.text.trim(),
      registrationNumber: _registrationController.text.trim().isEmpty ? null : _registrationController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } else {
      setState(() => _errorMessage = result.errorMessage ?? 'Sign up failed.');
    }
  }

  Widget _roleOption({required UserRole value, required String label}) {
    final selected = _role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 15, color: AppColors.primary),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Rounded, borderless "pill" field style used only on this screen.
  InputDecorationTheme get _fieldTheme => InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: _fieldTheme,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Account')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Account Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),

                  AppTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name.' : null,
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.mail_outline),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter your email.';
                      if (!v.contains('@')) return 'Please enter a valid email.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    label: 'Phone Number (optional)',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please enter a password.';
                      if (v.length < 6) return 'Password must be at least 6 characters.';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  const Text('I am a', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _roleOption(value: UserRole.official, label: 'Government\nOfficial'),
                      _roleOption(value: UserRole.inspector, label: 'PMU /\nInspector'),
                      _roleOption(value: UserRole.ngoInstitute, label: 'NGO /\nInstitute'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_role == UserRole.official) ...[
                    AppTextField(
                      label: 'Department (e.g. Dept. of Social Justice & Empowerment)',
                      controller: _departmentController,
                      prefixIcon: const Icon(Icons.apartment_outlined),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Department is required.' : null,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Designation (e.g. Deputy Director)',
                      controller: _designationController,
                      prefixIcon: const Icon(Icons.badge_outlined),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Designation is required.' : null,
                    ),
                  ],

                  if (_role == UserRole.inspector) ...[
                    AppTextField(
                      label: 'PMU Department / Unit (e.g. Project Monitoring Unit)',
                      controller: _departmentController,
                      prefixIcon: const Icon(Icons.apartment_outlined),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Department is required.' : null,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Designation (optional, e.g. Program Officer)',
                      controller: _designationController,
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ],

                  if (_role == UserRole.ngoInstitute) ...[
                    AppTextField(
                      label: 'Organization / NGO Name (e.g. Prayas Foundation)',
                      controller: _organizationController,
                      prefixIcon: const Icon(Icons.corporate_fare_outlined),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Organization name is required.' : null,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Registration Number (optional, e.g. NGO/2019/00123)',
                      controller: _registrationController,
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // --- Terms agreement ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                              children: [
                                TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                                TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  PrimaryButton(
                    label: _isLoading ? 'Creating account...' : 'Sign Up',
                    onPressed: _isLoading ? () {} : _handleSignup,
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}