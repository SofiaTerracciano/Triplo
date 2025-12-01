import 'package:flutter/material.dart';
import 'package:triplo/model/trekking.dart';
class AddingDiaryPage extends StatefulWidget {
  final Trekking trekking;
  final void Function(Locale) onLocaleChanged;

  const AddingDiaryPage({super.key, required this.trekking, required this.onLocaleChanged});

  @override
  AddingDiaryPageState createState() => AddingDiaryPageState();
}

class AddingDiaryPageState extends State<AddingDiaryPage> {
  // Esempio: controller di un TextField
  final TextEditingController diaryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add ${widget.trekking.name}"),
      ),
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
            )
          ],
        ),
      ),
    );
  }
}
