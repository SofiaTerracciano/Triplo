import 'package:app_triplo_wearos/pages/UserProfilePage/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart'; 
import '../../controller/user.dart';
import '../../model/user.dart';

class UserListPage extends StatelessWidget {
  final String title;
  final List<String> uids;

  const UserListPage({super.key, required this.title, required this.uids});

  @override
  Widget build(BuildContext context) {
    final userCtrl = context.read<UserController>();
    final primaryColor = Theme.of(context).colorScheme.primary;
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                children: [
                  ...uids.map((uid) => FutureBuilder<Users?>(
                    future: userCtrl.getUserById(uid),
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox(height: 50);
                      final user = snap.data!;

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundImage: (user.photoProfile?.isNotEmpty ?? false)
                                ? NetworkImage(user.photoProfile!)
                                : null,
                            child: (user.photoProfile?.isEmpty ?? true)
                                ? Icon(Icons.person, size: 14, color: primaryColor)
                                : null,
                          ),
                          title: Text(
                            user.username,
                            style: const TextStyle(
                              fontSize: 11, 
                              fontWeight: FontWeight.bold
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserPage(uidOverride: user.uid),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  )).toList(),

                  const SizedBox(height: 12),

                  // Back button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        minimumSize: const Size(0, 30), 
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        local.back_label, 
                        style: const TextStyle(fontSize: 11)
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}