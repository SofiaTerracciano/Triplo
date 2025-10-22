import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // per Clipboard
import 'home-page.dart';
import 'setting-page.dart';
import 'search-page.dart';

//DA CAPIRE LA COSA DEL POP

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  int _selectedIndex = 1;

  //TextStyle for texts
  static const TextStyle optionStyle = TextStyle(
    fontSize: 30,
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
      appBar: AppBar(title: Center(child: _widgetOptions[_selectedIndex])),

      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          //avatar + username column
          Container(
            width: 200,
            // padding on all sides
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 40, backgroundColor: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Username',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text('Livello: Esperto'),
              ],
            ),
          ),

          // statistics column
          Container(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Percorsi fatti',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatItem(label: 'Totali', value: '40'),
                    _StatItem(label: 'Pubblicati', value: '20'),
                    _StatItem(label: 'Privati', value: '20'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      /*body: Container(
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
      ),*/
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MyHomePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile', style: optionStyle,),
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
              title: const Text('Search', style: optionStyle,),
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
              title: const Text('Settings', style: optionStyle,),
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
