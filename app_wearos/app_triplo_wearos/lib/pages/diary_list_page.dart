import 'package:flutter/material.dart';
import '../model/diary.dart';
import 'diary_page.dart';

class DiaryListPage extends StatelessWidget {
  final String title;
  final List<Diary> diaries;

  const DiaryListPage({
    super.key,
    required this.title,
    required this.diaries,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: diaries.length,
        itemBuilder: (context, index) {

          final diary = diaries[index];

          return ListTile(
            title: Text(
              diary.trekkigName,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              diary.date,
              style: const TextStyle(color: Colors.white60),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 14,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiaryPage(
                    diary: diary,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}