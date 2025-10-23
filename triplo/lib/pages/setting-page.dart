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

  //Page titles for AppBar
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
        centerTitle: true, //Forced center the title
      ),

      body: ListView(
        padding: const EdgeInsets.all(25.0),
        children: [
          // profile info + avatar
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // left column: username + password
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

              //const SizedBox(width: 2), // spazio tra le colonne

              // right column: avatar + edit photo
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/profile_placeholder.png'),
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
                            style: TextStyle(
                              fontSize: 12),
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
            
          ),
          Row(

          ),
          Row(

          ),
          Row(
            
          ),
          Row(
            
          ),
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
              title: const Text('Home', style: optionStyle,),
              selected: _selectedIndex == 0,
              onTap: () {
                Navigator.pushReplacement(context, 
                  MaterialPageRoute(builder: (context) => const MyHomePage())
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile', style: optionStyle,),
              selected: _selectedIndex == 1,
              onTap: () {
                Navigator.pushReplacement(context, 
                  MaterialPageRoute(builder: (context) => const UserPage())
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search', style: optionStyle,),
              selected: _selectedIndex == 2,
              onTap: () {
                Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const SearchPage())
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings',style: optionStyle,),
              selected: _selectedIndex == 3,
              onTap: () {
                Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const SettingPage())
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

