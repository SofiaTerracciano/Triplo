import 'package:flutter/material.dart';
import 'package:app_triplo_wearos/model/diary.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart'; 
import 'diary_page.dart';

class DiaryListPage extends StatelessWidget {
  final String title;
  final List<Diary> diaries;

  const DiaryListPage({super.key, required this.title, required this.diaries});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                children: [
                  // Mappiamo i diari come card cliccabili
                  ...diaries.map((diary) => Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: Icon(Icons.terrain, size: 16, color: primaryColor),
                      title: Text(
                        diary.trekkigName,
                        style: const TextStyle(
                          fontSize: 11, 
                          fontWeight: FontWeight.bold
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        diary.date,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DiaryPage(diary: diary),
                          ),
                        );
                      },
                    ),
                  )).toList(),

                  const SizedBox(height: 12),

                  // Back button - Stesso stile della UserListPage
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        minimumSize: const Size(0, 30), 
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        local.back_label, 
                        style: const TextStyle(fontSize: 11)
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}