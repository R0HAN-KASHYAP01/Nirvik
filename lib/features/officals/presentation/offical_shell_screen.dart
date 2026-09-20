// lib/features/officials/presentation/official_shell_screen.dart
//
// New home for Official-specific work going forward. This re-exports
// the existing, working screen under features/dashboard/ rather than
// moving it, since other files (quick_action_card.dart,
// dashboard_header.dart, official_home_screen.dart, etc.) reference
// it by its current path and I haven't reviewed all of them yet.
// Add new official-only screens/widgets in this folder from now on;
// share the dashboard/official_*.dart files if you want a full,
// safe physical move later.

export '../../mosje_admin/presentation/official_shell_screen.dart';
