// lib/features/district_admin/presentation/district_admin_theme.dart
//
// Colour system for the District Administrator screens, taken from the UI
// palette you supplied (deep government blue, pale-blue backgrounds, white
// cards, blue-tinted text, soft green / amber / red status colours).
//
// Change a colour here and every district-admin screen that uses it follows.

import 'package:flutter/material.dart';

abstract final class DistrictColors {
  // ---------- Primary blue ----------
  static const Color primary = Color(0xFF084482);
  static const Color primaryDark = Color(0xFF063A77);
  static const Color primaryMedium = Color(0xFF0B5AA0);
  static const Color primaryLight = Color(0xFFEAF4FD);

  // ---------- Backgrounds ----------
  static const Color background = Color(0xFFF1F7FC);
  static const Color sectionBackground = Color(0xFFF7FAFD);
  static const Color card = Color(0xFFFFFFFF);

  // ---------- Text ----------
  static const Color textPrimary = Color(0xFF173B63);
  static const Color textSecondary = Color(0xFF5F7285);
  static const Color textMuted = Color(0xFF8191A1);

  // ---------- Borders ----------
  static const Color borderLight = Color(0xFFDCE8F2);
  static const Color borderMedium = Color(0xFFC8D9E8);

  // ---------- Success ----------
  static const Color success = Color(0xFF20A866);
  static const Color successDark = Color(0xFF16834D);
  static const Color successLight = Color(0xFFE7F8EE);

  // ---------- Warning ----------
  static const Color warning = Color(0xFFF2A51A);
  static const Color warningDark = Color(0xFFC77B00);
  static const Color warningLight = Color(0xFFFFF3D9);

  // ---------- Danger ----------
  static const Color danger = Color(0xFFE84B4B);
  static const Color dangerDark = Color(0xFFC93636);
  static const Color dangerLight = Color(0xFFFDEAEA);

  // ---------- Info / purple / orange ----------
  static const Color info = Color(0xFF2486D9);
  static const Color infoLight = Color(0xFFE7F3FF);
  static const Color purple = Color(0xFF6654D9);
  static const Color purpleLight = Color(0xFFF0EDFF);
  static const Color orange = Color(0xFFF58220);
  static const Color orangeLight = Color(0xFFFFF0E3);

  // ---------- Gradients (CSS 135deg = top-left -> bottom-right) ----------

  /// Top bars, primary buttons, major blue elements.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B5AA0), Color(0xFF084482), Color(0xFF063A77)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Very soft pale-blue page background.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF7FAFD), Color(0xFFEFF7FD), Color(0xFFEAF4FD)],
  );

  /// Almost-white card.
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFBFDFF)],
  );

  /// Standard white card with a light blue border.
  static BoxDecoration cardDecoration({double radius = 12}) {
    return BoxDecoration(
      gradient: cardGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderLight),
    );
  }
}

/// Primary button: the main blue gradient with white text.
class DistrictGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const DistrictGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    return Opacity(
      opacity: enabled || loading ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: DistrictColors.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: 46,
              width: double.infinity,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}