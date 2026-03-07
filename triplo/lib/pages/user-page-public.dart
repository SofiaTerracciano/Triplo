import 'package:flutter/material.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:triplo/pages/diary-page.dart';
import 'package:triplo/pages/user-list-page-public.dart';
import '../controller/diary.dart';
import '../controller/user.dart';
import '../model/diary.dart';
import '../model/user.dart';

class UserPagePublic extends StatefulWidget {
  final String userId;

  const UserPagePublic({super.key, required this.userId});

  @override
  State<UserPagePublic> createState() => _UserPagePublicState();
}

class _UserPagePublicState extends State<UserPagePublic> {
  Users? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userController = context.read<UserController>();
    final u = await userController.getUserById(widget.userId);

    if (!mounted) return;

    setState(() {
      user = u;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not found")),
      );
    }

    final u = user!;

    return Scaffold(
      appBar: AppBar(
        title: Text(u.username),
        centerTitle: true,
        actions: [
          FutureBuilder<bool>(
            future: context.read<UserController>().isFollowing(u.uid),
            builder: (context, snapshot) {

              final isFollowing = snapshot.data ?? false;

              return IconButton(
                icon: Icon(
                  isFollowing ? Icons.person_remove : Icons.person_add,
                ),
                onPressed: () async {
                  final controller = context.read<UserController>();

                  if (isFollowing) {
                    await controller.unfollowUser(u.uid);
                  } else {
                    await controller.followUser(u.uid);
                  }

                  setState(() {}); // refresh UI
                },
              );
            },
          ),
        ],
      ),

      body: Column(
          children: [
            // Top page --> general info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colonna Avatar + username + level
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        // Avatar 
                        CircleAvatar(
                            radius: 36,
                            backgroundImage: u.photoProfile != null &&
                                    u.photoProfile!.isNotEmpty
                                ? NetworkImage(u.photoProfile!)
                                : null,
                            backgroundColor: Colors.grey[300],
                            child: u.photoProfile == null || u.photoProfile!.isEmpty
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                        // Username + level
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                u.username,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${local.level_label}: ${u.level}',
                          style:
                              const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),
                  // Colonna Nome + stats
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${u.name} ${u.surname}',
                                textAlign: TextAlign.center,
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FutureBuilder<List<Diary>>(
                              future: context.read<DiaryController>().getPublicDiaries(u.uid),
                              builder: (context, pubSnap) {

                                return FutureBuilder<List<Diary>>(
                                  future: context.read<DiaryController>().getPrivateDiaries(u.uid),
                                  builder: (context, privSnap) {

                                    final pub = pubSnap.data?.length ?? 0;
                                    final priv = privSnap.data?.length ?? 0;

                                    return _StatItem(
                                      label: local.totals_trekking_label,
                                      value: '${pub + priv}',
                                    );
                                  },
                                );
                              },
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UsersListPublic(
                                      listName: 'Followers',
                                      userId: u.uid,
                                    ),
                                  ),
                                );
                              },
                              child: FutureBuilder<List<Users>>(
                                future: context.read<UserController>().getFollowers(u.uid),
                                builder: (context, snap) {
                                  return _StatItem(
                                    label: 'Follower',
                                    value: '${snap.data?.length ?? 0}',
                                  );
                                },
                              ),
                            ),

                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UsersListPublic(
                                      listName: 'Following',
                                      userId: u.uid,
                                    ),
                                  ),
                                );
                              },
                              child: FutureBuilder<List<Users>>(
                                future: context.read<UserController>().getFollowing(u.uid),
                                builder: (context, snap) {
                                  return _StatItem(
                                    label: 'Following',
                                    value: '${snap.data?.length ?? 0}',
                                  );
                                },
                              ),

                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const Divider(),

          // Public diary
            Expanded(
              child: FutureBuilder<List<Diary>>(
                future: context
                    .read<DiaryController>()
                    .getPublicDiaries(u.uid),
                builder: (context, snapshot) {

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final diaries = snapshot.data ?? [];

                  if (diaries.isEmpty) {
                    return Center(child: Text(local.no_public_diary_label));
                  }

                  return ListView.separated(
                    itemCount: diaries.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final diary = diaries[index];

                      return ListTile(
                        title: Text(diary.trekkigName),
                        subtitle: Text(diary.date),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DiaryPage(diaryId: diary.diaryId),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

          ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),

        SizedBox(
          height: 32,
          width: 70,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}