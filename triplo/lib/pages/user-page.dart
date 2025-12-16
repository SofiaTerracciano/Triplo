import 'dart:io';

import 'package:flutter/material.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter/src/material/icons.dart';
import 'package:triplo/pages/challenges-page.dart';
import 'package:triplo/pages/trekking-page.dart';
import 'diary-page.dart';
import 'home-page.dart';
import 'setting-page.dart';
import 'search-page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/user.dart';
import '../controller/trekking.dart';
import '../controller/diary.dart';
import '../pages/users-list-page.dart';

class UserPage extends StatefulWidget {
  final void Function(Locale) onLocaleChanged;
  final TrekkingController trekkingController;
  final UserController userController;
  final DiaryController diaryController;

  const UserPage({
    super.key,
    required this.onLocaleChanged,
    required this.trekkingController,
    required this.userController,
    required this.diaryController,
  });

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  //Map<String, dynamic>? userData;
  //final user = Provider.of<UserController>(context).currentUser;

  final ImagePicker _picker = ImagePicker();
  //open image from phone
  Future<XFile?> _pickImage() async {
    return await _picker.pickImage(source: ImageSource.gallery);
  }

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
    final controller = Provider.of<UserController>(context);
    final user = controller.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off, size: 70, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "You are not logged in",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                "Please login to access your profile",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text("Go to Login"),
              ),
            ],
          ),
        ),
      );
    }

    final local = AppLocalizations.of(context)!;

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
                final controller = Provider.of<UserController>(
                  context,
                  listen: false,
                );

                await controller.logout();

                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),

        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Avatar + username column
                Container(
                  width: 200,
                  // Padding on all sides
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picked = await _pickImage();
                          if (picked == null) return;

                          final file = File(picked.path);

                          await controller.updateProfilePhoto(file);
                        },

                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              (user.photoProfile != null &&
                                  user.photoProfile!.isNotEmpty)
                              ? NetworkImage(user.photoProfile!)
                              : null,

                          backgroundColor: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        user.username,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      //if (user.)
                      Text('${local.level_label} : ${local.advanced_level}'),
                      //else
                      //else
                    ],
                  ),
                ),

                // Statistics column
                Container(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${user.name} ${user.surname}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {}, // do nothing
                            child: _StatItem(
                              label: local.totals_trekking_label,
                              value: '${user.publicDiaryPages.length + user.privateDiaryPages.length}',
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(context, MaterialPageRoute(
                                  builder: (_) => UsersList(
                                    onLocaleChanged: widget.onLocaleChanged,
                                    trekkingController: widget.trekkingController,
                                    userController: widget.userController,
                                    diaryController: widget.diaryController,
                                    listName: 'Followers',
                                  ),
                                ),);
                            },
                            child: _StatItem(
                              label: 'Follower',
                              value: '${user.followers.length}',
                            ),
                          ),
                          
                          GestureDetector( 
                            onTap: () {
                              Navigator.pushReplacement(context, MaterialPageRoute(
                                  builder: (_) => UsersList(
                                    onLocaleChanged: widget.onLocaleChanged,
                                    trekkingController: widget.trekkingController,
                                    userController: widget.userController,
                                    diaryController: widget.diaryController,
                                    listName: 'Following',
                                  ),
                                ),);
                            },
                            child: _StatItem(
                              label: 'Following',
                              value: '${user.following.length}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Setting and share buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Setting button
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingPage(
                              onLocaleChanged: widget.onLocaleChanged,
                              trekkingController: widget.trekkingController,
                              userController: widget.userController,
                              diaryController: widget.diaryController,
                            ),
                          ),
                        );
                      },
                      child: Text(local.settings_page_title),
                    ),
                  ],
                ),
                SizedBox(width: 7),
                // Copy URL button
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Funzione che fa copiare URL
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Marcipises Alert!'),
                              content: Text('Yout are on the marcipises 2!'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text(local.share_profile_button_label),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 23),
            // Tabs for public, private, saved paths
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.label_important)),
                Tab(icon: Icon(Icons.lock)),
                Tab(icon: Icon(Icons.bookmark)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab percorsi/diari pubblici
                  user.publicDiaryPages.isEmpty
                  ? const Center(child: Text("No public diary pages"))
                  : ListView.builder(
                      itemCount: user.publicDiaryPages.length,
                      itemBuilder: (context, index) {
                        final diary = user.publicDiaryPages[index];
                        return ListTile(
                          title: Text(diary.trekkigName), 
                          subtitle: Text(diary.date),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DiaryPage(
                                  diaryId: diary.diaryId,
                                  diaryController: widget.diaryController,
                                  userController: widget.userController,
                                  trekkingController: widget.trekkingController,
                                  onLocaleChanged: widget.onLocaleChanged,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                  // Tab percorsi/diari privati
                  user.privateDiaryPages.isEmpty
                    ? const Center(child: Text("No private diary pages"))
                    : ListView.builder(
                        itemCount: user.privateDiaryPages.length,
                        itemBuilder: (context, index) {
                          final diary = user.privateDiaryPages[index];
                          return ListTile(
                            title: Text(diary.trekkigName), // attenzione al nome della proprietà
                            subtitle: Text(diary.date),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DiaryPage(
                                    diaryId: diary.diaryId,
                                    diaryController: widget.diaryController,
                                    userController: widget.userController,
                                    trekkingController: widget.trekkingController,
                                    onLocaleChanged: widget.onLocaleChanged,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                  user.savedTrekkings.isEmpty
                  ? const Center(child: Text("No saved trekking"))
                  : ListView.builder(
                      itemCount: user.savedTrekkings.length,
                      itemBuilder: (context, index) {
                        final trekking = user.savedTrekkings[index];
                        return ListTile(
                          title: Text(trekking.name),
                          onTap: () {
                            final routeID = trekking.documentId;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TrekkingPage(
                                  trekkingId: routeID,
                                  trekkingController: widget.trekkingController,
                                  userController: widget.userController,
                                  diaryController: widget.diaryController,
                                  onLocaleChanged: widget.onLocaleChanged,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    )
                ],
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
                decoration: BoxDecoration(color: Colors.greenAccent),
                child: Text(
                  local.menu_title,
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: Text(local.home_page_title, style: optionStyle),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyHomePage(
                        onLocaleChanged: widget.onLocaleChanged,
                        trekkingController: widget.trekkingController,
                        userController: widget.userController,
                        diaryController: widget.diaryController,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(local.profile_page_title, style: optionStyle),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserPage(
                        onLocaleChanged: widget.onLocaleChanged,
                        trekkingController: widget.trekkingController,
                        userController: widget.userController,
                        diaryController: widget.diaryController,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: Text(local.search_page_title, style: optionStyle),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchPage(
                        onLocaleChanged: widget.onLocaleChanged,
                        trekkingController: widget.trekkingController,
                        userController: widget.userController,
                        diaryController: widget.diaryController,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(local.settings_page_title, style: optionStyle),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingPage(
                        onLocaleChanged: widget.onLocaleChanged,
                        trekkingController: widget.trekkingController,
                        userController: widget.userController,
                        diaryController: widget.diaryController,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events),
                title: Text(local.challeng_title, style: optionStyle),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChallengesPage(
                        onLocaleChanged: widget.onLocaleChanged,
                        trekkingController: widget.trekkingController,
                        userController: widget.userController,
                        diaryController: widget.diaryController,
                      ),
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
}

// Widget for individual statistic item
class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }
}
