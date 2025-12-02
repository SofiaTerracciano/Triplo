import 'package:flutter/material.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/controller/diary.dart';

class AddingDiaryPage extends StatefulWidget {
  final void Function(Locale) onLocaleChanged;
  final String trekkingId;
  final TrekkingController trekkingController;
  final UserController userController;
  final DiaryController diaryController;

  const AddingDiaryPage({
    super.key,
    required this.onLocaleChanged,
    required this.trekkingId,
    required this.trekkingController,
    required this.userController,
    required this.diaryController,
  });

  @override
  AddingDiaryPageState createState() => AddingDiaryPageState();
}

class AddingDiaryPageState extends State<AddingDiaryPage> {
  // Esempio: controller di un TextField
  final TextEditingController diaryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Trekking trekking = widget.trekkingController.getTrekkingById(
      widget.trekkingId,
    )!;
    return Scaffold(
      appBar: AppBar(title: Text("Add ${trekking.name}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Write your diary entry:"),
            const SizedBox(height: 12),
            TextField(
              controller: diaryController,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Type here...",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final text = diaryController.text;
                // TODO: Gestisci salvataggio
                print("Diary entry: $text");
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
