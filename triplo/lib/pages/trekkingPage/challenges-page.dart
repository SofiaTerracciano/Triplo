import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/GeowatchPage/Navigation.dart';
import 'package:triplo/pages/HomePage/home-page.dart';
import 'package:triplo/pages/SearchPage/search-page.dart';
import 'package:triplo/pages/SettingsPage/setting-page.dart';
import 'package:triplo/pages/UserProfilePage/user-page.dart';

import '../../controller/challenge.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  bool _loading = true;
  //Map<String, String> _downloadUrls = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChallenges();
    });
  }

  Future<void> _loadChallenges() async {
    await context.read<ChallengesController>().loadChallenges();
    if (!mounted) return;
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
    final challengesController = context.watch<ChallengesController>();
    final challenges = challengesController.allChallenges;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(local.challeng_title)),
      body: challenges.isEmpty
          ? Center(child: Text(local.no_challenge))
          : ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(overscroll: false),
              child: ListView.builder(
                itemCount: challenges.length,
                itemBuilder: (context, index) {
                  final challenge = challenges[index];

                  // Selezione lingua
                  final langIndex = getLanguageSelected(locale.languageCode);

                  final title = (challenge.title.length > langIndex)
                      ? challenge.title[langIndex]
                      : challenge.title.isNotEmpty
                      ? challenge.title[0]
                      : local.no_title;

                  final description = (challenge.description.length > langIndex)
                      ? challenge.description[langIndex]
                      : challenge.description.isNotEmpty
                      ? challenge.description[0]
                      : local.no_description;

                  final photoFuture = challengesController.getCachedImage(
                    challenge.photo,
                  );

                  final isEven = index % 2 == 0;

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isEven)
                          FutureBuilder<File?>(
                            future: photoFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              if (snapshot.hasError || snapshot.data == null) {
                                return _buildBrokenImage();
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
                          FutureBuilder<File?>(
                            future: photoFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              if (snapshot.hasError || snapshot.data == null) {
                                return _buildBrokenImage();
                              }

                              return _buildImage(snapshot.data!);
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
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
                Navigator.pop(context);
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
                  MaterialPageRoute(builder: (_) => CompassAltitudePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(File file) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 100,
        height: 100,
        child: Image.file(
          file,
          fit: BoxFit.contain,
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

  Widget _buildBrokenImage() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 100,
        height: 100,
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 40),
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
