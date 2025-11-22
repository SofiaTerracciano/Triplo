import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/l10n/app_localizations_de.dart';
import 'package:triplo/l10n/app_localizations_it.dart';
import 'package:triplo/l10n/app_localizations_en.dart';
import 'package:triplo/l10n/app_localizations_fr.dart';
import 'package:triplo/l10n/app_localizations_es.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter/src/material/icons.dart';
import 'home-page.dart';
import 'setting-page.dart';
import 'search-page.dart';

//DA CAPIRE LA COSA DEL POP

class UserPage extends StatefulWidget {
  const UserPage({super.key, required this.onLocaleChanged});
  final void Function(Locale) onLocaleChanged;

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

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    // TabController for tabs in the body (public, private, saved)
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(local.profile_page_title),
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
                        local.username_label,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('${local.level_label} : ${local.advanced_level}'),
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
                        local.done_trekking_label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatItem(label: local.totals_trekking_label, value: '40'),
                          _StatItem(label: local.published_trekking_label, value: '20'),
                          _StatItem(label: local.private_trekking_label, value: '20'),
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
                            builder: (context) => SettingPage(
                              onLocaleChanged: widget.onLocaleChanged,
                            ),
                          ),
                        );
                      },
                      child: Text(local.settings_page_title),
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
                      child: Text(local.share_profile_button_label),
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
                        title: Text('${local.published_trekking_label}  ${index + 1}'),
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
                        title: Text('${local.private_trekking_label} ${index + 1}'),
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
                        title: Text('${local.save_trekking_button_label} ${index + 1}'),
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
                    MaterialPageRoute(builder: (context) => MyHomePage(onLocaleChanged: widget.onLocaleChanged)),
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
                    MaterialPageRoute(builder: (context) =>  UserPage(onLocaleChanged: widget.onLocaleChanged)),
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
                    MaterialPageRoute(builder: (context) => SearchPage(onLocaleChanged: widget.onLocaleChanged)),
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
                    MaterialPageRoute(builder: (context) => SettingPage(onLocaleChanged: widget.onLocaleChanged)),
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

  const _StatItem({
    required this.label, 
    required this.value
  });

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
