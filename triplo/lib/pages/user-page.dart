import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter/src/material/icons.dart';
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

  // TextStyle for texts
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
    // TabController for tabs in the body (public, private, saved)
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: _widgetOptions[_selectedIndex],
          centerTitle: true, // Forced center the title
        ),

        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Avatar + username column
                Container(
                  width: 200,
                  // Padding on all sides
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(radius: 40, backgroundColor: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Username',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Livello: Esperto'),
                    ],
                  ),
                ),

                // Statistics column
                Container(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Percorsi fatti',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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

            SizedBox(height: 12),

            // Setting and share buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Setting button
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingPage(),
                          ),
                        );
                      },
                      child: const Text('Settings'),
                    ),
                  ],
                ),
                SizedBox(width: 7),
                // Copy URL button
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Funzione che fa copiare URL
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Marcipises Alert!'),
                              content: Text('Yout are on the marcipises 2!'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text('Share Profile'),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 23),
            // Tabs for public, private, saved paths
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.label_important)),
                Tab(icon: Icon(Icons.lock)),
                Tab(icon: Icon(Icons.bookmark)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView.builder(
                    itemCount:
                        10, //sarà dinamico -> numero di percorsi pubblici
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text('Public Path ${index + 1}'),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Marcipises Alert!'),
                                content: Text(
                                  'Yout are on the marcipises on public path!',
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('OK'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  ListView.builder(
                    itemCount: 10, //sarà dinamico -> numero di percorsi privati
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text('Private Path ${index + 1}'),
                        onTap: () {
                          // Azione al tap sul percorso privato
                        },
                      );
                    },
                  ),
                  ListView.builder(
                    itemCount: 10, //sarà dinamico -> numero di percorsi salvati
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text('Saved Path ${index + 1}'),
                        onTap: () {
                          // Azione al tap sul percorso salvato
                        },
                      );
                    },
                  ),
                ],
              ),
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
                    MaterialPageRoute(
                      builder: (context) => const SettingPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget for individual statistic item
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
