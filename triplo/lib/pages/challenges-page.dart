import 'package:flutter/material.dart';
import 'package:triplo/controller/API.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/home-page.dart';
import 'package:triplo/pages/search-page.dart';
import 'package:triplo/pages/setting-page.dart';
import 'package:triplo/pages/user-page.dart';

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
  late ChallengesController _challengesController;
  bool _loading = true;
  Map<String, String> _downloadUrls = {};

  @override
  void initState() {
    super.initState();
    _challengesController = ChallengesController();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    await _challengesController.loadChallenges();
    setState(() {
      _loading = false;
    });
  }

  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final challenges = _challengesController.allChallenges;

    return Scaffold(
      appBar: AppBar(title: Text(local.challeng_title)),
      body: challenges.isEmpty
          ? Center(child: Text("No challenges available"))
          : ListView.builder(
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final challenge = challenges[index];

                // Selezione lingua
                final langIndex = getLanguageSelected(locale.languageCode);

                // Selezione titolo e descrizione in base alla lingua
                final title = (challenge.title.length > langIndex)
                    ? challenge.title[langIndex]
                    : challenge.title.isNotEmpty
                    ? challenge.title[0]
                    : "No title";

                final description = (challenge.description.length > langIndex)
                    ? challenge.description[langIndex]
                    : challenge.description.isNotEmpty
                    ? challenge.description[0]
                    : "No description";

                // Future per scaricare immagine da Firebase Storage
                final photoFuture =
                    _downloadUrls.containsKey(challenge.documentId)
                    ? Future.value(_downloadUrls[challenge.documentId]!)
                    : _challengesController
                          .getDownloadUrl(challenge.photo)
                          .then((url) {
                            _downloadUrls[challenge.documentId] = url;
                            return url;
                          });

                final isEven = index % 2 == 0;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isEven)
                        FutureBuilder<String>(
                          future: photoFuture,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox(
                                width: 100,
                                height: 100,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _buildImage(snapshot.data!);
                          },
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              softWrap: true,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: const TextStyle(fontSize: 16),
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                      if (isEven)
                        FutureBuilder<String>(
                          future: photoFuture,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox(
                                width: 100,
                                height: 100,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _buildImage(snapshot.data!);
                          },
                        ),
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 100,
        height: 100,
        child: Image.network(
          url,
          fit: BoxFit.contain, // mantiene l'immagine intera senza tagli
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

int getLanguageSelected(String code) {
  switch (code) {
    case 'de':
      return 0;
    case 'en':
      return 1;
    case 'es':
      return 2;
    case 'fr':
      return 3;
    case 'it':
      return 4;

    default:
      return 1;
  }
}
