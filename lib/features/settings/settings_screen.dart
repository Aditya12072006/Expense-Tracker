import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../settings/providers/currency_provider.dart';
import '../subscription/providers/subscription_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final service = ref.watch(subscriptionServiceProvider);
    final displayCurrency = currency.symbol.isEmpty ? r'$' : currency.symbol;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.attach_money_rounded),
            title: const Text('Currency'),
            subtitle: Text('Default: $displayCurrency'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export Data to CSV'),
            subtitle: const Text('Coming soon'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV export is coming soon.')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restore_rounded),
            title: const Text('Restore Premium Purchase'),
            subtitle: const Text('Re-check local Lemon Squeezy premium status'),
            onTap: () async {
              final restored = await service.restorePremiumPurchase();
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    restored
                        ? 'Premium access is active.'
                        : 'No active premium purchase found.',
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.support_agent_rounded),
            title: const Text('Contact Support'),
            subtitle: const Text('help@expensetracker.app'),
            onTap: () async {
              final emailUri = Uri(
                scheme: 'mailto',
                path: 'help@expensetracker.app',
                queryParameters: {
                  'subject': 'ExpenseTracker Support',
                },
              );
              await launchUrl(emailUri);
            },
          ),
        ],
      ),
    );
  }
}
