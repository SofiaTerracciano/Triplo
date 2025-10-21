import 'package:flutter/material.dart';
import 'package:triplo/pages/home-page.dart';
import 'package:triplo/pages/setting-page.dart';
import 'package:triplo/pages/search-page.dart';

//DA CAPIRE LA COSA DEL POP

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  int _selectedIndex = 1;

  static const TextStyle optionStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );

  static const List<Widget> _widgetOptions = <Widget>[
    Text('Home', style: optionStyle),
    Text('Profile', style: optionStyle),
    Text('Search', style: optionStyle),
    Text('Settings', style: optionStyle),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: _widgetOptions[_selectedIndex]),),
      body: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row( 
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/user_avatar.png'),
                    )
                  ]
                ),
                Row(
                  children: [
                    Text("Username") //effettivamente il nome utente
                  ]
                )
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("Percorsi fatti") 
                  ]
                ),
                
                Row(
                  children: [
                    Column(
                      children: [
                        Text("Totali"), 
                      ]
                    ),
                    Column(
                      children: [
                        Text("Pubblici"), 
                      ]
                    ),
                    Column(
                      children: [
                        Text("Privati"), 
                      ]
                    ),
                  ]
                ),
                
                Row(
                  children: [
                    Column(
                      children: [
                        Text("40"), //numero di percorsi totali
                      ]
                    ),
                    Column(
                      children: [
                        Text("20"), //numero di percorsi pubblicati
                      ]
                    ),
                    Column(
                      children: [
                        Text("20"), //numero di percorsi tenuti privati
                      ]
                    ),
                  ]
                )
              ],
            ),
          ],
        ),
      ),
      
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: _selectedIndex == 0,
              onTap: () {
                Navigator.pushReplacement(context, 
                  MaterialPageRoute(builder: (context) => const MyHomePage())
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              selected: _selectedIndex == 1,
              onTap: () {
                Navigator.pushReplacement(context, 
                  MaterialPageRoute(builder: (context) => const UserPage())
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search'),
              selected: _selectedIndex == 2,
              onTap: () {
                Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const SearchPage())
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
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
