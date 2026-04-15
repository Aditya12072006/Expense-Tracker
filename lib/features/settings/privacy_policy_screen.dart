import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _lastUpdated = 'April 15, 2026';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            'Last updated: $_lastUpdated',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 16),
          const _PolicySection(
            title: 'Overview',
            body:
                'Expense Tracker stores your transaction data locally on your device using local storage. We do not sell your personal data.',
          ),
          const _PolicySection(
            title: 'Data We Collect',
            body:
                'We collect and store transaction records that you add, such as amount, note, category, and date. Premium purchase state is also stored locally to unlock premium features.',
          ),
          const _PolicySection(
            title: 'Payments',
            body:
                'Premium purchases are processed using Razorpay. Payment processing is handled by Razorpay according to their privacy policy and terms.',
          ),
          const _PolicySection(
            title: 'How We Use Data',
            body:
                'Your data is used to show dashboards, charts, and transaction history inside the app. We use support email only when you contact us.',
          ),
          const _PolicySection(
            title: 'Data Storage and Security',
            body:
                'Your records are stored on-device. If you uninstall the app or use the Clear All App Data option, local data can be removed. Keep your device secured to protect your data.',
          ),
          const _PolicySection(
            title: 'Data Deletion',
            body:
                'You can delete all local data from Settings -> Clear All App Data at any time.',
          ),
          const _PolicySection(
            title: 'Contact',
            body:
                'For privacy questions, contact: aditya12072006@gmail.com',
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}
