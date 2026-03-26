import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter/src/material/icons.dart';
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
  String level = '';
  /*
  Future<String?> uploadProfilePicture(File image) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child(uid)
        .child('$uid.jpg');

    try {
      await ref.putFile(image);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Errore upload: $e');
      return null;
    }
  }
 */
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<TrekkingController>().loadTrekking();
    });
  }

  Future<void> _loadDiaries() async {
    final diaryController = context.read<DiaryController>();
    final userController = context.read<UserController>();
    final currentUserId = userController.currentUser!.uid;
    
    // Load both public and private diaries for the current user
    await diaryController.loadPublicDiary(currentUserId);
    await diaryController.loadPrivateDiary(currentUserId);

  }

  /*
  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    setState(() {
      userData = doc.data();
    });
  }

  Future<void> _saveProfileURL(String url) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'photoURL': url});
*/
  // Aggiorno i dati mostrati nella UI
  /*
    setState(() {
      user.photoProfile != null
          ? NetworkImage(user.photoProfile!)
          : null    });
   */

  // TextStyle for texts
  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final userController = context.watch<UserController>();
    
    if (userController.isLoading) { 
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(), 
        ),
      );
    }
    final user = userController.currentUser;
    _loadDiaries();
    Color levelColor;
    String levelText;

    if (userController.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }


    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off, size: 70, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                local.not_logged_title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                local.not_logged_subtitle,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
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

    // TabController for tabs in the body (public, private, saved)
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(local.profile_page_title),
          centerTitle: true, // Forced center the title
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                final userController = context.read<UserController>();

                await userController.logout();

                Navigator.pushReplacementNamed(context, '/login');
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
                  // Column for photo + username + level
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        // Photo
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
                        // Username
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
                  // Column for name + stats
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + surname
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
                        // Stats: total diaries, followers, following
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // TOTAL DIARIES
                            FutureBuilder<List<Diary>>(
                              future: context
                                  .read<DiaryController>()
                                  .getPublicDiaries(user.uid),
                              builder: (context, pubSnap) {
                                return FutureBuilder<List<Diary>>(
                                  future: context
                                      .read<DiaryController>()
                                      .getPrivateDiaries(user.uid),
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

                            // FOLLOWERS
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        UsersList(listName: local.follower),
                                  ),
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
                            // FOLLOWING
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        UsersList(listName: local.following),
                                  ),
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
            // Buttons for settings and share profile
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Settings button
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
                  // Share profile button
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: Text(local.share_profile_button_label),
                      onPressed: () {
                        final renderBox =
                            context.findRenderObject() as RenderBox?;
                        if (renderBox == null) return;

                        // Share profile link --> it return https://triplo.app/user/username
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
            // Tabs for public, private diaries and saved trekking
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
                    // 1. PUBLIC DIARY
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

                    // 2. PRIVATE DIARY
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

                    // 3. SAVED TREKKING
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TrekkingPage(
                                      trekkingId: trekking.documentId,
                                    ),
                                  ),
                                );
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
        //Drawer to control the navigation among pages
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
                    MaterialPageRoute(builder: (context) => MyHomePage()),
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
                    MaterialPageRoute(builder: (context) => SearchPage()),
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
                    MaterialPageRoute(builder: (_) => ChallengesPage()),
                  );
                },
              ),
              // Navigation page
              ListTile(
                leading: Icon(
                  Icons.explore,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(local.navigation_page_title, style: optionStyle),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => CompassAltitudePage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget for displaying a single statistic item
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
