import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/user.dart';
import 'package:triplo/l10n/app_localizations.dart';

class PairedWatchesPage extends StatefulWidget {
  const PairedWatchesPage({super.key});

  @override
  State<PairedWatchesPage> createState() => _PairedWatchesPageState();
}

class _PairedWatchesPageState extends State<PairedWatchesPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<UserController>().getConnectedWatches();
  }

  bool _remoteLogoutActive(Map<String, dynamic> watch) {
    return watch['remoteLogoutAt'] != null;
  }

  Future<void> _enableRemoteLogout(String watchId) async {
    final local = AppLocalizations.of(context)!;

    try {
      await context.read<UserController>().enableRemoteLogoutForWatch(watchId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(local.remote_logout_enabled)),
      );

      setState(_reload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${local.remote_logout_enable_error}: $e"),
        ),
      );
    }
  }

  Future<void> _clearRemoteLogout(String watchId) async {
    final local = AppLocalizations.of(context)!;

    try {
      await context.read<UserController>().clearRemoteLogoutForWatch(watchId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(local.remote_logout_cleared)),
      );

      setState(_reload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${local.remote_logout_clear_error}: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(local.connected_watches_title),
        actions: [
          IconButton(
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
            tooltip: local.refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "${local.error_loading_watches}:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final watches = snapshot.data ?? [];

          if (watches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  local.no_watches,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: watches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final watch = watches[index];
              final watchId = watch['watchId']?.toString() ?? '-';
              final remoteActive = _remoteLogoutActive(watch);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${local.watch_id}: $watchId",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      Text("${local.status}: ${watch['status'] ?? '-'}"),
                      Text("${local.platform}: ${watch['platform'] ?? '-'}"),

                      Text(
                        "${local.remote_logout}: "
                        "${remoteActive ? local.enabled : local.disabled}",
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: remoteActive
                                ? null
                                : () => _enableRemoteLogout(watchId),
                            child: Text(local.enable_remote_logout),
                          ),
                          ElevatedButton(
                            onPressed: remoteActive
                                ? () => _clearRemoteLogout(watchId)
                                : null,
                            child: Text(local.disable_remote_logout),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}