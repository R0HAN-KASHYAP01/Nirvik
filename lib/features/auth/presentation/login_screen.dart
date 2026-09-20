import 'package:flutter/material.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../services/auth_service.dart';
import '../../../services/session_service.dart';
import '../../../models/user.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.instance.login(
      _idController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success && result.user != null) {
      SessionService.instance.setUser(result.user!);

      final destination = switch (result.user!.role) {
        UserRole.official => AppRoutes.officialDashboard,
        UserRole.inspector => AppRoutes.inspectorDashboard,
        UserRole.ngoInstitute => AppRoutes.ngoDashboard,
        UserRole.stateAdmin => AppRoutes.stateAdminDashboard,
        UserRole.districtAdmin => AppRoutes.districtAdminDashboard,
      };

      Navigator.of(context).pushNamedAndRemoveUntil(
        destination,
        (route) => false,
      );
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? 'Login failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HeaderBanner(),

              Transform.translate(
                offset: const Offset(0, 5),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'Access your account to continue',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _PillTextField(
                          controller: _idController,
                          hint: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.mail_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email.';
                            }

                            if (!value.contains('@')) {
                              return 'Please enter a valid email.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 6),

                        _PillTextField(
                          controller: _passwordController,
                          hint: 'Password',
                          obscureText: _obscurePassword,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password.';
                            }

                            return null;
                          },
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),

                        PrimaryButton(
                          label: _isLoading ? 'Logging in...' : 'Login',
                          onPressed: _isLoading ? () {} : _handleLogin,
                        ),

                        const SizedBox(height: 8),

                        // Responsive action buttons.
                        // They wrap instead of overflowing on narrow screens.
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 330;

                            if (isNarrow) {
                              return Column(
                                children: [
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text('Forgot Password?'),
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text('Get Help'),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: TextButton(
                                    onPressed: () {},
                                    child: const Text(
                                      'Forgot Password?',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: TextButton(
                                    onPressed: () {},
                                    child: const Text(
                                      'Get Help',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed(AppRoutes.signup);
                            },
                            child: const Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Don't have an account? ",
                                  ),
                                  TextSpan(
                                    text: 'Sign up',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Responsive footer.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: AppColors.textSecondary.withValues(
                        alpha: 0.8,
                      ),
                    ),
                    Text(
                      'Secure  |  Transparent  |  Inclusive',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top banner: emblem, title/subtitle, and Parliament illustration.
class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      height: 520,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: 270,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.35,
              child: SizedBox(
                width: double.infinity,
                height: 240,
                child: Image.asset(
                  'assets/images/parliament.png',
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: Column(
              children: [
                Opacity(
                  opacity: 0.85,
                  child: Image.asset(
                    'assets/images/emblem.png',
                    height: 120,
                  ),
                ),
                const Text(
                  'Official Smart Monitoring &\nInspection System',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Department of Social Justice & Empowerment',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Text(
                  'Government of India',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill-shaped text field used only on this screen.
class _PillTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _PillTextField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    required this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          prefixIcon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),
      ),
    );
  }
}