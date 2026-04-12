import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/diary.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/pages/GeowatchPage/Navigation.dart';
import 'package:triplo/pages/trekkingPage/challenges-page.dart';
import 'package:triplo/pages/trekkingPage/trekking-page.dart';
import 'package:triplo/pages/UserProfilePage/user-page-public.dart';
import '../../enum/SearchMode.dart';
import '../../widgets_for_pages/filter/filter.dart';
import '../HomePage/home-page.dart';
import '../UserProfilePage/user-page.dart';
import '../SettingsPage/setting-page.dart';
import '../DiaryPage/diary-page.dart';
import '../../controller/diary.dart';
import '../../controller/trekking.dart';
import '../../controller/user.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  SearchMode _searchMode = SearchMode.users;
  bool _isSearching = false;
  List<Users> _userResults = [];
  List<Trekking> _trekkingResults = [];
  List<Diary> randomDiaries = [];
  bool loading = true;

  //TextStyle for texts
  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

  // Keep the state of the page alive when switching tabs
  @override
  bool get wantKeepAlive => true;

  // Initialize the controller, focus node and load random diary from
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      setState(() {});
    });

    if (SearchCache.randomDiaries != null) {
      randomDiaries = SearchCache.randomDiaries!;
      loading = false;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRandomDiaries();
      });
    }
  }

  // Clean up the controller and focus node when the widget is disposed
  @override
  void dispose() {
    SearchCache.randomDiaries = null;
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRandomDiaries() async {
    try {
      final userController = context.read<UserController>();
      final diaryController = context.read<DiaryController>();

      final user = userController.currentUser;

      // Se non sei loggato o non ancora caricato: NON bloccare la UI
      if (user == null) {
        if (!mounted) return;
        setState(() {
          randomDiaries = [];
          loading = false;
        });
        return;
      }

      final uid = user.uid;
      final followingIds = await userController.getFollowingIds(uid);

      final diaries = await diaryController.getRandomPublicDiariesFromFollowing(
        followingIds: followingIds,
        limit: 10,
      );

      SearchCache.randomDiaries = diaries;

      if (!mounted) return;
      setState(() {
        randomDiaries = diaries;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error loading random diaries: $e"); //coverage:ignore-line
      if (!mounted) return;
      setState(() {
        randomDiaries = [];
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = _focusNode.hasFocus;
    final bool hasText = _searchController.text.isNotEmpty;
    final local = AppLocalizations.of(context)!;
    super.build(context);

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
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        _runSearch(value);
                      } else {
                        setState(() {
                          _userResults.clear();
                          _trekkingResults.clear();
                        });
                      }
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
            const SizedBox(height: 8),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Filter(
                    mode: SearchMode.users,
                    selectedMode: _searchMode,
                    label: local.user_label,
                    onSelected: _onSearchModeChanged,
                  ),
                  const SizedBox(width: 8),
                  Filter(
                    mode: SearchMode.trekking,
                    selectedMode: _searchMode,
                    label: local.trekking_label,
                    onSelected: _onSearchModeChanged,
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),

      // Drawer to control the navigation among pages
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => UserPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(local.search_page_title, style: optionStyle),
              onTap: () {
                Navigator.pop(context);
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
    );
  }

  // Handle search mode change
  void _onSearchModeChanged(SearchMode mode) {
    setState(() {
      _searchMode = mode;
      _userResults.clear();
      _trekkingResults.clear();
      _isSearching = false;
    });

    // Re-run search if there's text
    if (_searchController.text.isNotEmpty &&
        (mode == SearchMode.users || mode == SearchMode.trekking)) {
      _runSearch(
        _searchController.text
      );
    }
  }

  // Run search based on the current search mode
  /*Future<void> _runSearch(String query) async {
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    final userController = context.read<UserController>();
    final trekkingController = context.read<TrekkingController>();

    _userResults.clear();
    _trekkingResults.clear();

    if (_searchMode == SearchMode.users) {
      _userResults = await userController.searchUsers(query);
    }

    if (_searchMode == SearchMode.trekking) {
      _trekkingResults =
          await trekkingController.searchTrekking(query);
    }

    setState(() => _isSearching = false);
  }*/

  int _searchToken = 0;

  Future<void> _runSearch(String query) async {
    if (query.isEmpty) return;

    final int currentToken = ++_searchToken;

    setState(() => _isSearching = true);

    final userController = context.read<UserController>();
    final trekkingController = context.read<TrekkingController>();

    try {
      if (_searchMode == SearchMode.users) {
        _userResults = await userController.searchUsers(query);
      } else if (_searchMode == SearchMode.trekking) {
        _trekkingResults =
        await trekkingController.searchTrekking(query);
      }
    } catch (e) { 
      debugPrint("Search error: $e"); //coverage:ignore-line
    }

    if (currentToken == _searchToken && mounted) {
      setState(() => _isSearching = false);
    }
  }

  // Build grid of random diaries
  Widget _buildRandomDiaryGrid() {
    final userController = context.read<UserController>();
    final diaryController = context.read<DiaryController>();
    final trekkingController = context.read<TrekkingController>();

    return GridView.builder(
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
          future: userController.getUserById(diary.userId),
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
                    builder: (context) => DiaryPage(diaryId: diary.diaryId),
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
                    // Image of the trekking trip or first photo of the diary
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
                            diaryController: diaryController,
                            trekkingController: trekkingController,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Username
                          Flexible(
                            child: Text(
                              username,
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
    );
  }

  // Build the main body based on the search mode and results
  Widget _buildBody() {
    final local = AppLocalizations.of(context)!;
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      if (randomDiaries.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              local.no_friends,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        );
      }
      return _buildRandomDiaryGrid();
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchMode == SearchMode.users) {
      if (_userResults.isEmpty) {
        return Center(child: Text(local.no_user_found_label));
      }

      return ListView.builder(
        itemCount: _userResults.length,
        itemBuilder: (context, index) {
          final u = _userResults[index];

          return ListTile(
            leading: (u.photoProfile == null || u.photoProfile!.isEmpty)
                ? const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person),
                  )
                : CircleAvatar(backgroundImage: NetworkImage(u.photoProfile!)),
            title: Text(u.username),
            subtitle: Text(u.email),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserPagePublic(userId: u.uid),
                ),
              );
            },
          );
        },
      );
    }

    if (_searchMode == SearchMode.trekking) {
      if (_trekkingResults.isEmpty) {
        return Center(child: Text (local.no_trekking_found_label));
      }

      return ListView.builder(
        itemCount: _trekkingResults.length,
        itemBuilder: (context, index) {
          final trekking = _trekkingResults[index];
          return ListTile(
            leading: Icon(
              Icons.terrain, 
              color: trekking.difficulty_level == "easy"
                  ? Colors.lightBlue
                  : trekking.difficulty_level == "intermediate"
                      ? Colors.red
                      : const Color.fromARGB(255, 135, 1, 162)),
            title: Text(trekking.name),
            subtitle: Text(
              trekking.difficulty_level == "easy"
                  ? local.beginner_level
                  : trekking.difficulty_level == "intermediate"
                      ? local.intermediate_level
                      : local.advanced_level,
              style: TextStyle(
                color: (trekking.difficulty_level == "easy"
                    ? Colors.lightBlue
                    : trekking.difficulty_level == "intermediate"
                        ? Colors.red
                        : const Color.fromARGB(255, 135, 1, 162))
                    .withOpacity(0.7), 
                fontSize: 14,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrekkingPage(trekkingId: trekking.documentId),
                ),
              );
            },
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}

// Widget to display the cover image of a diary --> it chooses the first photo of the diary
// if available,otherwise it falls back to the trekking map photo
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

    //  else choose Trekking map photo
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

  // Loading indicator widget
  Widget _loading() =>
      const Center(child: CircularProgressIndicator(strokeWidth: 2));

  // Fallback image widget in case no image is available
  Widget _fallbackImage() => Container(
    color: Colors.grey.shade200,
    alignment: Alignment.center,
    child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
  );
}

// Widget to load and display an image from storage
class _StorageImage extends StatelessWidget {
  final String path;
  final DiaryController diaryController;

  const _StorageImage({required this.path, required this.diaryController});

  @override
  Widget build(BuildContext context) {
    final cachedUrl = ImageUrlCache.get(path);

    if (cachedUrl != null) {
      return _buildImage(cachedUrl);
    }

    return FutureBuilder<String?>(
      future: diaryController.getDownloadUrlChild(path),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _loading();
        }

        final url = snapshot.data!;
        ImageUrlCache.set(path, url);

        return _buildImage(url);
      },
    );
  }

  Widget _buildImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => _brokenImage(),
    );
  }

  Widget _loading() =>
      const Center(child: CircularProgressIndicator(strokeWidth: 2));

  Widget _brokenImage() => Container(
    color: Colors.grey.shade200,
    alignment: Alignment.center,
    child: const Icon(Icons.broken_image, size: 40),
  );
}

// Cache for search page data
class SearchCache {
  static List<Diary>? randomDiaries;
}

// Simple in-memory cache for image URLs
class ImageUrlCache {
  static final Map<String, String> _cache = {};

  static String? get(String path) => _cache[path];
  static void set(String path, String url) => _cache[path] = url;
}