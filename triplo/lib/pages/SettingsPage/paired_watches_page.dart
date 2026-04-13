import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controller/user.dart';

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
    try {
      await context.read<UserController>().enableRemoteLogoutForWatch(watchId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Remote logout enabled.")),
      );
      setState(_reload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error enabling remote logout: $e")),
      );
    }
  }

  Future<void> _clearRemoteLogout(String watchId) async {
    try {
      await context.read<UserController>().clearRemoteLogoutForWatch(watchId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Remote logout cleared.")),
      );
      setState(_reload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error clearing remote logout: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connected watches"),
        actions: [
          IconButton(
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
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
                  "Error loading connected watches:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final watches = snapshot.data ?? [];

          if (watches.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "No currently connected watches found.",
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
                        "Watch ID: $watchId",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text("Status: ${watch['status'] ?? '-'}"),
                      Text("Platform: ${watch['platform'] ?? '-'}"),

                      Text(
                        "Remote logout: ${remoteActive ? 'enabled' : 'disabled'}",
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
                            child: const Text("Enable remote logout"),
                          ),
                          ElevatedButton(
                            onPressed: remoteActive
                                ? () => _clearRemoteLogout(watchId)
                                : null,
                            child: const Text("Disable remote logout"),
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