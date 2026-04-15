import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  static const String _developerName = 'Aditya Kumar Yadav';
  static const String _supportEmail = 'aditya12072006@gmail.com';

  Future<PackageInfo> _loadPackageInfo() {
    return PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Info')),
      body: FutureBuilder<PackageInfo>(
        future: _loadPackageInfo(),
        builder: (context, snapshot) {
          final info = snapshot.data;

          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (info == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Unable to load app information.'),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _InfoTile(label: 'App Name', value: info.appName),
              _InfoTile(label: 'Package Name', value: info.packageName),
              _InfoTile(label: 'Version Name', value: info.version),
              _InfoTile(label: 'Build Number', value: info.buildNumber),
              _InfoTile(
                label: 'Combined Version',
                value: '${info.version}+${info.buildNumber}',
              ),
              const _InfoTile(label: 'Developer', value: _developerName),
              const _InfoTile(label: 'Support Email', value: _supportEmail),
            ],
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(label),
          subtitle: Text(value),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
