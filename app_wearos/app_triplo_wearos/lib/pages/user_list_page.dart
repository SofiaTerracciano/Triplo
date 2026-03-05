import 'package:app_triplo_wearos/pages/user-page-public.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/user.dart';

class UserListPage extends StatelessWidget {
  final String title;
  final List<String> uids;

  const UserListPage({
    super.key,
    required this.title,
    required this.uids,
  });

  @override
  Widget build(BuildContext context) {
    final userCtrl = context.read<UserController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: SafeArea(
        child: uids.isEmpty
            ? const Center(
          child: Text(
            "Nessun utente",
            style: TextStyle(color: Colors.white70),
          ),
        )
            : ListView.separated(
          padding: const EdgeInsets.all(10),
          itemCount: uids.length,
          separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.08)),
          itemBuilder: (context, index) {
            final uid = uids[index];

            return FutureBuilder(
              future: userCtrl.getUserById(uid),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return _UserListTile.loading();
                }
                final u = snap.data!;
                return _UserListTile(
                  username: u.username,
                  subtitle: (u.level ?? "").toString(),
                  photoUrl: (u.photoProfile ?? "").toString(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserPagePublic(uidOverride: uid),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  final String username;
  final String subtitle;
  final String photoUrl;
  final VoidCallback onTap;
  final bool isLoading;

  const _UserListTile({
    required this.username,
    required this.subtitle,
    required this.photoUrl,
    required this.onTap,
    this.isLoading = false,
  });

  factory _UserListTile.loading() => _UserListTile(
    username: "Caricamento…",
    subtitle: "",
    photoUrl: "",
    onTap: () {},
    isLoading: true,
  );

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.trim().isNotEmpty;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
                image: hasPhoto ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
              ),
              child: hasPhoto ? null : const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (!isLoading) const Icon(Icons.chevron_right, color: Colors.white54),
          ],

        ),
      ),
    );
  }
}