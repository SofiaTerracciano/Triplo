import 'package:flutter/material.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/home-page.dart';
import 'package:triplo/pages/search-page.dart';
import 'package:triplo/pages/setting-page.dart';
import 'package:triplo/pages/user-page.dart';

class Challenge {
  final String title;
  final String description;
  final String photoUrl;

  Challenge({
    required this.title,
    required this.description,
    required this.photoUrl,
  });
}

class ChallengesPage extends StatefulWidget {
  final void Function(Locale) onLocaleChanged;
  final TrekkingController trekkingController;
  final DiaryController diaryController;
  final UserController userController;

  const ChallengesPage({
    super.key,
    required this.onLocaleChanged,
    required this.diaryController,
    required this.trekkingController,
    required this.userController,
  });

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

  late List<Challenge> _challenges;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final local = AppLocalizations.of(context)!;

    _challenges = [
      Challenge(
        title: local.photo_title_challeng,
        description: local.photo_description_challeng,
        photoUrl: 'https://picsum.photos/200',
      ),
      Challenge(
        title: local.time_title_challeng,
        description: local.time_description_challeng,
        photoUrl: 'https://picsum.photos/200',
      ),
      Challenge(
        title: local.hi_title_challeng,
        description: local.hi_description_challeng,
        photoUrl: 'https://picsum.photos/200',
      ),
      Challenge(
        title: local.orientiring_title_challeng,
        description: local.orientiring_description_challeng,
        photoUrl: 'https://picsum.photos/200',
      ),
      Challenge(
        title: local.silent_walking_title_challeng,
        description: local.silent_walking_description_challeng,
        photoUrl: 'https://picsum.photos/200',
      ),
      Challenge(
        title: local.balance_title_challeng,
        description: local.balance_description_challeng,
        photoUrl: 'https://picsum.photos/200',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(local.challeng_title)),

      body: ListView.builder(
        itemCount: _challenges.length,
        itemBuilder: (context, index) {
          final challenge = _challenges[index];
          final isEven = index % 2 == 0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (!isEven) _buildImage(challenge.photoUrl),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        challenge.description,
                        style: const TextStyle(fontSize: 16),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),

                if (isEven) _buildImage(challenge.photoUrl),
              ],
            ),
          );
        },
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.greenAccent),
              child: Text(
                local.menu_title,
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: Text(local.home_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyHomePage(
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
                    builder: (_) => UserPage(
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
                    builder: (_) => SearchPage(
                      diaryController: widget.diaryController,
                      trekkingController: widget.trekkingController,
                      userController: widget.userController,
                      onLocaleChanged: widget.onLocaleChanged,
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
                    builder: (_) => SettingPage(
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
    );
  }

  Widget _buildImage(String url) {
    return Flexible(
      flex: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.network(
          url,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 100,
              height: 100,
              color: Colors.grey[300],
              child: const Icon(Icons.image, size: 40),
            );
          },
        ),
      ),
    );
  }
}
