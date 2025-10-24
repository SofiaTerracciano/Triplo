import 'package:flutter/material.dart';
import 'home-page.dart';
import 'user-page.dart';
import 'search-page.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  int _selectedIndex = 3;

  //TextStyle for texts
  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

  // Page titles for AppBar
  static const List<Widget> _widgetOptions = <Widget>[
    Text('Home', style: optionStyle),
    Text('Profile', style: optionStyle),
    Text('Search', style: optionStyle),
    Text('Settings', style: optionStyle),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _widgetOptions[_selectedIndex],
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
                        const Text(
                          'Username: ',
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
                        const Text(
                          'Password: ',
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
                        'assets/profile_placeholder.png',
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
                          child: const Text(
                            'Edit Profile Photo',
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
              const Text('Name: ', style: TextStyle(fontSize: 14)),
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
          /*const Padding(
            padding: EdgeInsets.only(left: 0, bottom: 8.0),
            child: Text(
              'name_placeholder', // da prendere dal database
              style: TextStyle(fontSize: 14),
            ),
          ),*/
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text('Surname: ', style: TextStyle(fontSize: 14)),
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
          /*const Padding(
            padding: EdgeInsets.only(left: 0, bottom: 8.0),
            child: Text(
              'surname_placeholder', // da prendere dal database
              style: TextStyle(fontSize: 14),
            ),
          ),*/
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text('Birthdate: ', style: TextStyle(fontSize: 14)),
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
          /*const Padding(
            padding: EdgeInsets.only(left: 0, bottom: 8.0),
            child: Text(
              '16/04/2002', // da prendere dal database
              style: TextStyle(fontSize: 14),
            ),
          ),*/
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text('Email: ', style: TextStyle(fontSize: 14)),
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
          /*const Padding(
            padding: EdgeInsets.only(left: 0, bottom: 8.0),
            child: Text(
              'email_placeholder', // da prendere dal database
              style: TextStyle(fontSize: 14),
            ),
          ),*/
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text('Language: ', style: TextStyle(fontSize: 14)),
              IconButton(
                onPressed: () async {
                  final selected = await showDialog<Locale>(
                    context: context,
                    builder: (context) => LanguageDialog(),
                  );

                  /*  if (selected != null) {
                  //onLanguageChanged(selected);
                  AlertDialog(
                    content: Text('Language changed to: ${selected.languageCode}'),
                  ); 
                }*/
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
          /*const Padding(
            padding: EdgeInsets.only(left: 0, bottom: 8.0),
            child: Text(
              'language_placeholder', // da prendere dal database
              style: TextStyle(fontSize: 14),
            ),
          ),*/
        ],
      ),

      //Drawer to control the navigation among pages
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.greenAccent),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home', style: optionStyle),
              selected: _selectedIndex == 0,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MyHomePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile', style: optionStyle),
              selected: _selectedIndex == 1,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const UserPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search', style: optionStyle),
              selected: _selectedIndex == 2,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings', style: optionStyle),
              selected: _selectedIndex == 3,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingPage()),
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
  LanguageDialog({super.key});

  final Map<String, Locale> languages = {
    'English': const Locale('en'),
    'Italian': const Locale('it'),
  };

  //TODO: implementare il cambio lingua effettivo nell'app

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Language'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            TextButton(
              child: const Text('English'),
              onPressed: () {
                AlertDialog(content: Text('Language changed to: english'));
                //locale -> to change the language of the app
                //Navigator.of(context).pop(const Locale('en'));
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              child: const Text('Italian'),
              onPressed: () {
                AlertDialog(content: Text('Language changed to: italian'));
                //Navigator.of(context).pop(const Locale('it'));
              },
            ),
          ],
        ),
      ),
    );
  }
}
