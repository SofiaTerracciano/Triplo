import 'package:flutter/material.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:triplo/pages/diary-page.dart';
import 'package:triplo/pages/user-list-page-public.dart';
import 'package:triplo/pages/users-list-page.dart';

import '../controller/user.dart';
import '../model/user.dart';
import '../model/diary.dart';
import '../model/trekking.dart';


/*class UserPagePublic extends StatefulWidget {
  final String userId;

  const UserPagePublic({
    super.key,
    required this.userId,
  });

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
      return Scaffold(
        appBar: AppBar(title: Text(local.profile_page_title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(local.profile_page_title)),
        body: const Center(child: Text("User not found")),
      );
    }

    // Shortcut
    final u = user!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("${u.username}"),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                // LOGICA DEL FOLLOW QUI
              },
            )
          ],
        ),

        body: Column(
          children: [

            Row(
              children: [
                // FOTO PROFILO
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: CircleAvatar(
                    radius: 40,

                    backgroundImage: (u.photoProfile != null && u.photoProfile!.isNotEmpty)
                        ? NetworkImage(u.photoProfile!)
                        : null,

                    child: (u.photoProfile == null || u.photoProfile!.isEmpty)
                        ? const Icon(Icons.person, size: 42)
                        : null,
                  ),

                ),

                // INFO UTENTE
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.username,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("Followers: ${u.followers.length}"),
                    Text("Following: ${u.following.length}"),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.public)),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // ----------- TAB 1: DIARI PUBBLICI -----------
                  _buildPublicDiaryTab(u),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PUBLIC DIARY LIST ---
  Widget _buildPublicDiaryTab(Users u) {
    final List<Diary> list = u.publicDiaryPages;

    if (list.isEmpty) {
      return const Center(child: Text("No public diaries"));
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final d = list[i];
        return ListTile(
          title: Text(d.trekkigName),
          subtitle: Text(d.date),
          onTap: () {
            // APRI DIARIO (se vuoi)
          },
        );
      },
    );
  }
}*/

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
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              // TODO: follow / unfollow
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Photo profile + username + level
                Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage:
                          u.photoProfile != null && u.photoProfile!.isNotEmpty
                              ? NetworkImage(u.photoProfile!)
                              : null,
                      backgroundColor: Colors.grey[300],
                      child: u.photoProfile == null || u.photoProfile!.isEmpty
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    // bisogna sistemare quando lo username è troppo lungo --> crea opverflow
                    Text(
                      u.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,                
                      overflow: TextOverflow.ellipsis, 
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${local.level_label}: ${local.advanced_level}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 20),

                // Name + statistics
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${u.name} ${u.surname}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,                
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          _StatItem(
                            label: local.totals_trekking_label,
                            value: '${u.publicDiaryPages.length}',
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UsersListPublic(listName: 'Followers', userId: u.uid),
                                ),
                              );
                            },
                            child: _StatItem(
                              label: 'Followers',
                              value: '${u.followers.length}', 
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UsersListPublic(listName: 'Following', userId: u.uid,),
                                ),
                              );
                            },
                            child: _StatItem(
                              label: 'Following',
                              value: '${u.following.length}', // non prende il valore corretto
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
            child: u.publicDiaryPages.isEmpty
                ? const Center(child: Text("No public diary pages"))
                : ListView.separated(
                    itemCount: u.publicDiaryPages.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final diary = u.publicDiaryPages[index];
                      return ListTile(
                        title: Text(diary.trekkigName),
                        subtitle: Text(diary.date),
                        trailing:
                            const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DiaryPage(
                                    diaryId: diary.diaryId
                                  ),
                            ),
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

        // 👇 ALTEZZA FISSA
        SizedBox(
          height: 32, // perfetto per 2 righe max
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