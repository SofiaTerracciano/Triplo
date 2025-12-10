import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/challenges.dart';
import 'home-page.dart';
import 'user-page.dart';
import 'search-page.dart';
import '../controller/trekking.dart';
import '../controller/user.dart';
import '../controller/diary.dart';

class SettingPage extends StatefulWidget {
  final void Function(Locale) onLocaleChanged;
  final TrekkingController trekkingController;
  final UserController userController;
  final DiaryController diaryController;

  const SettingPage({
    super.key, 
    required this.onLocaleChanged,
    required this.trekkingController,
    required this.userController,
    required this.diaryController,
  });

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  //TextStyle for texts
  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(local.settings_page_title),
        centerTitle: true, // Forced center the title
      ),

      body: ListView(
        padding: const EdgeInsets.all(25.0),
        children: [
          // Profile info + avatar
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column: username + password
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username + edit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          local.username_label,
                          style: TextStyle(fontSize: 14),
                        ),
                        IconButton(
                          onPressed: () {
                            // to do modifica username
                          },
                          icon: const Icon(Icons.edit, size: 16),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 0, bottom: 8.0),
                      child: Text(
                        'username_placeholder', // da prendere dal database
                        style: TextStyle(fontSize: 14),
                      ),
                    ),

                    // Password + edit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          local.password_label,
                          style: TextStyle(fontSize: 14),
                        ),
                        IconButton(
                          onPressed: () {
                            // to do modifica password
                          },
                          icon: const Icon(Icons.edit, size: 16),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 0, bottom: 8.0),
                      child: Text(
                        '***********', // numero di * uguale alla lunghezza della password
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              // Right column: avatar + edit photo
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(
                        'images/prova.jpeg',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            // to do modifica foto profilo
                          },
                          child: Text(
                            local.edit_profile_photo_button_label,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Altri campi come nome, cognome, email, nascita, lingua .
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                local.name_field_label, 
                style: TextStyle(fontSize: 14)
              ),
              IconButton(
                onPressed: () {
                  // to do modifica name
                },
                icon: const Icon(Icons.edit, size: 16),
              ),
              const Spacer(),
              Text(
                'name_placeholder',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                local.surname_field_label, 
                style: TextStyle(fontSize: 14)
              ),
              IconButton(
                onPressed: () {
                  // to do modifica surname
                },
                icon: const Icon(Icons.edit, size: 16),
              ),
              const Spacer(),
              Text(
                'surname_placeholder',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                local.birthdate_field_label, 
                style: TextStyle(fontSize: 14)
              ),
              IconButton(
                onPressed: () {
                  // to do modifica bithdate
                },
                icon: const Icon(Icons.edit, size: 16),
              ),
              const Spacer(),
              Text(
                'birthdate_placeholder',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                local.email_label, 
                style: TextStyle(fontSize: 14)
              ),
              IconButton(
                onPressed: () {
                  // to do modifica email
                },
                icon: const Icon(Icons.edit, size: 16),
              ),
              const Spacer(),
              Text(
                'email_palceholder',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                local.language_field_label, 
                style: TextStyle(fontSize: 14)
              ),
              IconButton(
                onPressed: (){
                  showDialog(
                    context: context,
                    builder: (context) => LanguageDialog(
                      onLocaleSelected: (locale) {
                        widget.onLocaleChanged(locale);
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.edit, size: 16),
              ),
              const Spacer(),
              Text(
                //però dovrebbe essere dinamico in base alla lingua selezionata
                'language_placeholder',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
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
              title: Text(
                local.home_page_title, 
                style: optionStyle
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage(onLocaleChanged: widget.onLocaleChanged, trekkingController: widget.trekkingController, userController: widget.userController, diaryController: widget.diaryController,)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(
                local.profile_page_title, 
                style: optionStyle
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) =>  UserPage(onLocaleChanged: widget.onLocaleChanged, userController: widget.userController, trekkingController: widget.trekkingController, diaryController: widget.diaryController,)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(
                local.search_page_title, 
                style: optionStyle
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SearchPage(onLocaleChanged: widget.onLocaleChanged, trekkingController: widget.trekkingController, userController: widget.userController, diaryController: widget.diaryController)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(
                local.settings_page_title, 
                style: optionStyle
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SettingPage(onLocaleChanged: widget.onLocaleChanged, trekkingController: widget.trekkingController, userController: widget.userController, diaryController: widget.diaryController,)),
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

// Popup dialog to select the language
class LanguageDialog extends StatelessWidget {
  final void Function(Locale) onLocaleSelected;

  const LanguageDialog({
    super.key, 
    required this.onLocaleSelected
  });

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(local.language_selection_label),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _langTile(context, "🇬🇧", "English", const Locale('en')),
          _langTile(context, "🇮🇹", "Italiano", const Locale('it')),
          _langTile(context, "🇪🇸", "Español", const Locale('es')),
          _langTile(context, "🇩🇪", "Deutsch", const Locale('de')),
          _langTile(context, "🇫🇷", "Français", const Locale('fr')),
        ],
      ),
    );
  }

  Widget _langTile(
    BuildContext context,
    String flag,
    String name,
    Locale locale,
  ) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 22)),
      title: Text(name),
      onTap: () {
        onLocaleSelected(locale);
        Navigator.pop(context);
      },
    );
  }
}