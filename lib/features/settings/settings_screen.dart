import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/storage/hive_boxes.dart';
import '../settings/providers/currency_provider.dart';
import '../subscription/providers/subscription_provider.dart';
import '../transactions/models/expense_transaction.dart';
import '../transactions/providers/transaction_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String _ownerName = 'Aditya Kumar Yadav';
  static const String _supportEmail = 'aditya12072006@gmail.com';
  static const String _appName = 'Expense Tracker';

  Future<String> _exportTransactionsToCsv(
    List<ExpenseTransaction> transactions,
  ) async {
    final now = DateTime.now();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final fileBaseName = 'expense_tracker_export_$stamp';
    final buffer = StringBuffer();
    buffer.writeln('id,title,type,category,amount,date_iso');

    String escapeCsv(String value) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }

    for (final tx in transactions) {
      buffer.writeln(
        [
          escapeCsv(tx.id),
          escapeCsv(tx.title),
          tx.type.name,
          escapeCsv(tx.category),
          tx.amount.toStringAsFixed(2),
          tx.date.toIso8601String(),
        ].join(','),
      );
    }

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      // Android 10 (SDK 29) and above use scoped storage, no permission needed for Downloads.
      // Below 10, we need WRITE_EXTERNAL_STORAGE.
      if (androidInfo.version.sdkInt < 29) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission required');
        }
      }
    }

    // Android 11+ (SDK 30+) often restricts direct folder access.
    // To ensure the user finds the file, we use Share.shareXFiles.
    // This allows the user to select 'Save to Drive', 'Send to WhatsApp', 
    // or 'Save to device/Downloads' explicitly.
    final xFile = XFile.fromData(
      bytes,
      name: '$fileBaseName.csv',
      mimeType: 'text/csv',
    );
    await Share.shareXFiles([xFile], text: 'Exported Transactions');

    // Also attempt saving for backup
    final savedPath = await FileSaver.instance.saveFile(
      name: fileBaseName,
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );

    return savedPath;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final service = ref.watch(subscriptionServiceProvider);
    final transactions = ref.watch(transactionsProvider);
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
            subtitle: Text('${transactions.length} records ready to export'),
            onTap: () async {
              if (transactions.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No transactions available to export.'),
                  ),
                );
                return;
              }

              String path;
              try {
                path = await _exportTransactionsToCsv(transactions);
              } catch (e) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().contains('permission')
                          ? 'Permission denied. Could not save file.'
                          : 'CSV export failed. Please try again.',
                    ),
                  ),
                );
                return;
              }

              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 6),
                  content: Text(
                    path.isEmpty
                        ? 'CSV exported successfully. Check your Downloads folder.'
                        : 'CSV exported successfully to:\n$path',
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restore_rounded),
            title: const Text('Restore Premium Purchase'),
            subtitle: const Text('Re-check local Razorpay premium status'),
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
            subtitle: const Text(_supportEmail),
            onTap: () async {
              final emailUri = Uri(
                scheme: 'mailto',
                path: _supportEmail,
                queryParameters: {
                  'subject': 'Expense Tracker Support Request',
                },
              );
              await launchUrl(emailUri);
            },
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.person_outline_rounded),
            title: Text('Developer'),
            subtitle: Text(_ownerName),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: const Text('How your data is used and stored'),
            onTap: () => context.push('/privacy-policy'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('App Info'),
            subtitle: const Text('Version, package id, and build details'),
            onTap: () => context.push('/app-info'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Open Source Licenses'),
            subtitle: const Text('Licenses used by this app'),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: _appName,
                applicationVersion: 'Version available in App Info',
                applicationLegalese:
                    'Developed and maintained by $_ownerName. Support: $_supportEmail',
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Colors.red.shade300,
            ),
            title: const Text('Clear All App Data'),
            subtitle: const Text('Deletes transactions and local settings'),
            onTap: () async {
              final shouldClear = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('Clear all app data?'),
                        content: const Text(
                          'This will permanently remove your local transactions, premium status, and settings on this device.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(dialogContext).pop(true),
                            child: const Text('Clear Data'),
                          ),
                        ],
                      );
                    },
                  ) ??
                  false;

              if (!shouldClear) {
                return;
              }

              try {
                await ref
                    .read(transactionsProvider.notifier)
                    .clearAllTransactions();
                await Hive.box<dynamic>(HiveBoxes.settings).clear();
                ref.invalidate(currencyProvider);
              } catch (_) {
                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not clear app data. Please try again.'),
                  ),
                );
                return;
              }

              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All local app data has been cleared.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
