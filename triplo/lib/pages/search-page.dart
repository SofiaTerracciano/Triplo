import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/diary.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/pages/challenges-page.dart';
import 'home-page.dart';
import 'user-page.dart';
import 'setting-page.dart';
import 'diary-page.dart';
import '../controller/diary.dart';
import '../controller/trekking.dart';
import '../controller/user.dart';

class SearchPage extends StatefulWidget {
  final void Function(Locale) onLocaleChanged;
  final DiaryController diaryController;
  final TrekkingController trekkingController;
  final UserController userController;

  const SearchPage({
    super.key,
    required this.onLocaleChanged,
    required this.diaryController,
    required this.trekkingController,
    required this.userController,
  });
  
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;

  List<Diary> randomDiaries = [];
  bool loading = true;

  //TextStyle for texts
  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

  // Initialize the controller, focus node and load random diary from
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();

    // Every time the focus changes, update the state
    _focusNode.addListener(() {
      setState(() {});
    });

    _loadRandomDiaries();
    randomDiaries.forEach((elemento) {
      print(elemento);
    });
  }

  Future<void> _loadRandomDiaries() async {
    final user = widget.userController.currentUser;
    if (user == null) return;

    final followingIds = user.following.map((u) => u.uid).toList();

    final diaries = await widget.diaryController
        .getRandomPublicDiariesFromFollowing(
          followingIds: followingIds,
          limit: 10,
        );

    setState(() {
      randomDiaries = diaries;
      loading = false;
    });
  }

  // Clean up the controller and focus node when the widget is disposed
  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = _focusNode.hasFocus;
    final bool hasText = _searchController.text.isNotEmpty;
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(local.search_page_title), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // Search box
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode, // To manage focus state
                    decoration: InputDecoration(
                      hintText: isFocused
                          ? ''
                          : local
                                .search_page_title, // It disappears when focused
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          hasText // Show X only if there's text
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear(); // Clear text
                                setState(() {});
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {}); // Update state to show/hide the X
                    },
                  ),
                ),

                // Cancel button
                if (isFocused) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      _searchController.clear(); // Clear text
                      _focusNode.unfocus(); // Dismiss keyboard
                      setState(() {}); // Reset state
                    },
                    child: Text(
                      local.cancel_button_label,
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                ],
              ],
            ),

            // Suggestion section (trekking path of your friends)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(top: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 element for each row
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.2, // To modify the ratio
                ),
                itemCount: randomDiaries.length,
                itemBuilder: (context, index) {
                  final diary = randomDiaries[index];

                  return FutureBuilder<Users?>(
                    future: widget.userController.getUserById(diary.userId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final user = snapshot.data!;
                      final username = user.username;

                      return InkWell(
                        // Animation on tap
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
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image of the trekking trip (presa dal db in base a quelle caricate nella diary page)
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: _DiaryCoverImage(
                                      diary: diary,
                                      diaryController: widget.diaryController,
                                      trekkingController:
                                          widget.trekkingController,
                                    ),
                                  ),
                                ),
                              ),

                              // Text
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Username
                                    Flexible(
                                      child: Text(
                                        username, // oppure username se lo hai
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    const SizedBox(width: 6),

                                    // Trekking name
                                    Flexible(
                                      child: Text(
                                        diary.trekkigName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
      ),

      // Drawer to control the navigation among pages
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
                      diaryController: widget.diaryController,
                      trekkingController: widget.trekkingController,
                      userController: widget.userController,
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
                      userController: widget.userController,
                      diaryController: widget.diaryController,
                      trekkingController: widget.trekkingController,
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
                      diaryController: widget.diaryController,
                      trekkingController: widget.trekkingController,
                      userController: widget.userController,
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
                      userController: widget.userController,
                      trekkingController: widget.trekkingController,
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
    );
  }
}

class _DiaryCoverImage extends StatelessWidget {
  final Diary diary;
  final DiaryController diaryController;
  final TrekkingController trekkingController;

  const _DiaryCoverImage({
    required this.diary,
    required this.diaryController,
    required this.trekkingController,
  });

  @override
  Widget build(BuildContext context) {
    /// If diary have an image, use this
    if (diary.photos.isNotEmpty) {
      return _StorageImage(
        path: diary.photos.first,
        diaryController: diaryController,
      );
    }

    /// else choose Trekking map photo
    final trekkingId = trekkingController.getTrekkingId(diary.trekkigName);

    if (trekkingId == null) {
      return _fallbackImage();
    }

    return FutureBuilder<Trekking?>(
      future: Future.value(trekkingController.getTrekkingById(trekkingId)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _loading();
        }

        final trekking = snapshot.data!;
        if (trekking.mapPhoto.isEmpty) {
          return _fallbackImage();
        }

        return _StorageImage(
          path: trekking.mapPhoto,
          diaryController: diaryController,
        );
      },
    );
  }

  Widget _loading() =>
      const Center(child: CircularProgressIndicator(strokeWidth: 2));

  Widget _fallbackImage() => Container(
    color: Colors.grey.shade200,
    alignment: Alignment.center,
    child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
  );
}

class _StorageImage extends StatelessWidget {
  final String path;
  final DiaryController diaryController;

  const _StorageImage({required this.path, required this.diaryController});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: diaryController.getDownloadUrlChild(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loading();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _brokenImage();
        }

        return Image.network(
          snapshot.data!,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _loading();
          },
          errorBuilder: (_, __, ___) => _brokenImage(),
        );
      },
    );
  }

  Widget _loading() =>
      const Center(child: CircularProgressIndicator(strokeWidth: 2));

  Widget _brokenImage() => Container(
    color: Colors.grey.shade200,
    alignment: Alignment.center,
    child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
  );
}
