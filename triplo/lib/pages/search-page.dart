import 'package:flutter/material.dart';
import 'home-page.dart';
import 'user-page.dart';
import 'setting-page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  int _selectedIndex = 2;
  late final TextEditingController _searchController;

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

  //initState to initialize the controller
  @override
  void initState() {
    super.initState();
    //setting controller for TextField -> to acquire input
    _searchController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: _widgetOptions[_selectedIndex],
          centerTitle: true, //Forced center the title
      ),
      body: Container(
        alignment: Alignment.center,
        //TextField to insert search text
          child: Column(
            children: [Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder()
                  ),
                )
              ),
              //Button to trigger search action
              ElevatedButton(
                onPressed: () {
                  String insertedText = _searchController.text;
                  //pop up to be sure that TextField acquires the input string
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Search Text'),
                        content: Text('You searched for: $insertedText'),
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
                child: const Icon(Icons.search)
              )
            ]
          )
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
              title: const Text('Settings', style: optionStyle,),
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


