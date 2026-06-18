import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/GeowatchPage/Navigation.dart';
import 'package:triplo/pages/trekkingPage/challenges-page.dart';
import 'package:triplo/pages/trekkingPage/trekking-page.dart';
import '../../controller/diary.dart';
import '../../controller/trekking.dart';
import '../../model/diary.dart';
import '../../model/trekking.dart';
import '../../model/user.dart';
import '../DiaryPage/diary-page.dart';
import '../HomePage/home-page.dart';
import '../SettingsPage/setting-page.dart';
import '../SearchPage/search-page.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/user.dart';
import 'users-list-page.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<TrekkingController>().loadTrekking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final userController = context.watch<UserController>();

    if (userController.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = userController.currentUser;

    if (user == null) {
      return Scaffold(
        key: const Key('userPageNotLogged'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off, size: 70, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                local.not_logged_title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                local.not_logged_subtitle,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                key: const Key('goToLoginButton'),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text(local.go_to_login_button),
              ),
            ],
          ),
        ),
      );
    }

    Color levelColor;
    String levelText;

    switch (user.level) {
      case 'Beginner':
        levelColor = Colors.lightBlue;
        levelText = local.beginner_level;
        break;
      case 'Intermediate':
        levelColor = Colors.red;
        levelText = local.intermediate_level;
        break;
      case 'Advanced':
        levelColor = const Color.fromARGB(255, 135, 1, 162);
        levelText = local.advanced_level;
        break;
      default:
        levelColor = Colors.black;
        levelText = '';
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        key: const Key('userPage'),
        appBar: AppBar(


          title: Text(local.profile_page_title),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final userController = context.read<UserController>();
                await userController.logout();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),

        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage:
                              user.photoProfile != null &&
                                  user.photoProfile!.isNotEmpty
                              ? NetworkImage(user.photoProfile!)
                              : null,
                          backgroundColor: Colors.grey[300],
                          child:
                              user.photoProfile == null ||
                                  user.photoProfile!.isEmpty
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.username,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(text: '${local.level_label}: '),
                              TextSpan(
                                text: levelText,
                                style: TextStyle(color: levelColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${user.name} ${user.surname}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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
                              future: _loadAllDiaries(context, user.uid),
                              builder: (context, snap) {
                                return _StatItem(
                                  label: local.totals_trekking_label,
                                  value: '${snap.data?.length ?? 0}',
                                );
                              },
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        UsersList(listName: local.follower),
                                  ),
                                ).then(
                                  (_) => setState(() {}),
                                ); 
                              },
                              child: FutureBuilder<List<Users>>(
                                future: context
                                    .read<UserController>()
                                    .getFollowers(user.uid),
                                builder: (context, snap) {
                                  return _StatItem(
                                    label: local.follower,
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
                                    builder: (_) =>
                                        UsersList(listName: local.following),
                                  ),
                                ).then(
                                  (_) => setState(() {}),
                                ); 
                              },
                              child: FutureBuilder<List<Users>>(
                                future: context
                                    .read<UserController>()
                                    .getFollowing(user.uid),
                                builder: (context, snap) {
                                  return _StatItem(
                                    label: local.following,
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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => SettingPage()),
                        );
                      },
                      child: Text(local.settings_page_title),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: Text(local.share_profile_button_label),
                      onPressed: () {
                        final renderBox =
                            context.findRenderObject() as RenderBox?;
                        if (renderBox == null) return;

                        Share.share(
                          '${local.watch_profile_dialog_level}\nhttps://triplo.app/user/${user.username}',
                          sharePositionOrigin:
                              renderBox.localToGlobal(Offset.zero) &
                              renderBox.size,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.label_important)),
                Tab(icon: Icon(Icons.lock)),
                Tab(icon: Icon(Icons.bookmark)),
              ],
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(overscroll: false),
                child: TabBarView(
                  children: [
                    FutureBuilder<List<Diary>>(
                      future: context.read<DiaryController>().getPublicDiaries(
                        user.uid,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final diaries = snapshot.data ?? [];
                        if (diaries.isEmpty) {
                          return Center(
                            child: Text(local.no_public_diary_label),
                          );
                        }
                        return ListView.builder(
                          itemCount: diaries.length,
                          itemBuilder: (context, index) {
                            final diary = diaries[index];
                            return ListTile(
                              title: Text(diary.trekkigName),
                              subtitle: Text(diary.date),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DiaryPage(diaryId: diary.diaryId),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    FutureBuilder<List<Diary>>(
                      future: context.read<DiaryController>().getPrivateDiaries(
                        user.uid,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final diaries = snapshot.data ?? [];
                        if (diaries.isEmpty) {
                          return Center(
                            child: Text(local.no_private_diary_label),
                          );
                        }
                        return ListView.builder(
                          itemCount: diaries.length,
                          itemBuilder: (context, index) {
                            final diary = diaries[index];
                            return ListTile(
                              title: Text(diary.trekkigName),
                              subtitle: Text(diary.date),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DiaryPage(diaryId: diary.diaryId),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    FutureBuilder<List<Trekking>>(
                      future: context
                          .read<TrekkingController>()
                          .getSavedTrekkings(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final trekkings = snapshot.data ?? [];
                        if (trekkings.isEmpty) {
                          return Center(
                            child: Text(local.no_saved_trekking_label),
                          );
                        }
                        return ListView.builder(
                          itemCount: trekkings.length,
                          itemBuilder: (context, index) {
                            final trekking = trekkings[index];
                            return ListTile(
                              title: Text(trekking.name),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TrekkingPage(
                                      trekkingId: trekking.documentId,
                                    ),
                                  ),
                                );

                                if (!mounted) return;
                                setState(() {});
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: const SizedBox.shrink(),
              ),
              ListTile(
                leading: Icon(
                  Icons.home,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(local.home_page_title, style: optionStyle),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MyHomePage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(local.profile_page_title, style: optionStyle),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(local.search_page_title, style: optionStyle),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(local.settings_page_title, style: optionStyle),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SettingPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.emoji_events,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(local.challeng_title, style: optionStyle),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ChallengesPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.explore,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(local.navigation_page_title, style: optionStyle),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CompassAltitudePage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Diary>> _loadAllDiaries(BuildContext context, String uid) async {
    final diaryController = context.read<DiaryController>();
    final publicDiaries = await diaryController.getPublicDiaries(uid);
    final privateDiaries = await diaryController.getPrivateDiaries(uid);
    return [...publicDiaries, ...privateDiaries];
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 32,
          width: 70,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      ],
    );
  }
}
