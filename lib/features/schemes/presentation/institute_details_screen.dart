import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../models/institute.dart';
import 'widgets/institute_status_chip.dart';

class InstituteDetailsScreen extends StatelessWidget {
  final Institute institute;
  const InstituteDetailsScreen({super.key, required this.institute});

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatDateTime(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final period = d.hour >= 12 ? 'PM' : 'AM';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${_formatDate(d)}, $hour:$minute $period';
  }

  String _formatCurrency(double amount) {
    final rounded = amount.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < rounded.length; i++) {
      final posFromEnd = rounded.length - i;
      buffer.write(rounded[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write(',');
    }
    return '₹ ${buffer.toString()}';
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  value,
                  softWrap: true,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastInspection = institute.lastInspection;

    return Scaffold(
      appBar: AppBar(title: const Text('Institute Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Institute "logo" placeholder.
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_outlined, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        institute.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        institute.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      InstituteStatusChip(status: institute.status),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const SectionHeader(title: 'Overview'),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _infoRow(context, Icons.category_outlined, 'Category', institute.category),
                  _infoRow(context, Icons.place_outlined, 'Location', institute.location),
                  _infoRow(context, Icons.event_available_outlined, 'Registered On', _formatDate(institute.registrationDate)),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const SectionHeader(title: 'Contact'),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _infoRow(context, Icons.person_outline, 'Contact Person', institute.contactPerson),
                  _infoRow(context, Icons.call_outlined, 'Phone', institute.contactPhone),
                  _infoRow(context, Icons.email_outlined, 'Email', institute.contactEmail),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const SectionHeader(title: 'Funds'),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(context, Icons.account_balance_wallet_outlined, 'Allocated', _formatCurrency(institute.fundsAllocated)),
                  _infoRow(context, Icons.payments_outlined, 'Utilized', _formatCurrency(institute.fundsUtilized)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: institute.utilizationFraction,
                      minHeight: 8,
                      backgroundColor: AppColors.border,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(institute.utilizationFraction * 100).toStringAsFixed(0)}% utilized',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const SectionHeader(title: 'Last Inspection'),
            const SizedBox(height: 10),
            if (lastInspection == null)
              AppCard(
                child: Text(
                  'No inspections have been recorded for this institute yet.',
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(context, Icons.event_outlined, 'Date & Time', _formatDateTime(lastInspection.dateTime)),
                    _infoRow(context, Icons.badge_outlined, 'Inspector', lastInspection.inspectorName),
                    _infoRow(context, Icons.flag_outlined, 'Status', lastInspection.status),
                    const SizedBox(height: 4),
                    Text('Report Summary', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      lastInspection.reportSummary,
                      softWrap: true,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}