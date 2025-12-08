import 'package:flutter/material.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/pages/trekking-page.dart';
import 'package:triplo/pages/user-page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  final TextEditingController textController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  int? selectedDay = 1;
  int? selectedMonth = 1;
  int? selectedYear = 2000;

  int? selectedHour = 0;
  int? selectedMinute = 0;

  final List<File> _images = [];
  final List<String> photos = [];

  bool usedRefreshmentPoint = false;
  bool isPublic = false;

  String notesText = '';
  String refreshmentText = '';

  final List<String> friends = [];
  final List<int> selectedIndex = [];

  final List<String> challenges = [];
  final List<int> selectedIndexChallenge = [];

  final List<String> mood = [];
  final List<int> selectedIndexMood = [];

  @override
  Widget build(BuildContext context) {
    final Trekking trekkingName =
        widget.trekkingController.getTrekkingById(widget.trekkingId)!;
    final local = AppLocalizations.of(context)!;

    final List<int> days = List<int>.generate(31, (i) => i + 1);
    final List<int> months = List<int>.generate(12, (i) => i + 1);
    final List<int> years = List<int>.generate(100, (i) => 2025 - i);
    final List<int> hours = List<int>.generate(24, (i) => i);
    final List<int> minutes = List<int>.generate(60, (i) => i);

    final List<String> availableMoods = [
      "😍", "😁", "🥰", "😅", "😎", "😞", "🤩",
    ];
    final List<String> availableMoodsLabels = [
      local.mood_love_label,
      local.mood_happy_label,
      local.mood_relaxed_label,
      local.mood_tired_label,
      local.mood_proud_label,
      local.mood_sad_label,
      local.mood_excited_label,
    ];

    final user = widget.userController;
    final diary = widget.diaryController;
    final trekking = widget.trekkingController;

    return Scaffold(
      appBar: AppBar(title: Text(trekkingName.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DATA
              Text("${local.date_trekking_label}:"),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<int>(
                    hint: Text(local.day_trekking_label),
                    value: selectedDay,
                    onChanged: (value) => setState(() => selectedDay = value),
                    items: days
                        .map((day) => DropdownMenuItem(
                              value: day,
                              child: Text(day.toString()),
                            ))
                        .toList(),
                  ),
                  SizedBox(width: 16),
                  DropdownButton<int>(
                    hint: Text(local.month_trekking_label),
                    value: selectedMonth,
                    onChanged: (value) => setState(() => selectedMonth = value),
                    items: months
                        .map((month) => DropdownMenuItem(
                              value: month,
                              child: Text(month.toString()),
                            ))
                        .toList(),
                  ),
                  SizedBox(width: 16),
                  DropdownButton<int>(
                    hint: Text(local.year_trekking_label),
                    value: selectedYear,
                    onChanged: (value) => setState(() => selectedYear = value),
                    items: years
                        .map((year) => DropdownMenuItem(
                              value: year,
                              child: Text(year.toString()),
                            ))
                        .toList(),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              // DURATA
              Text("${local.duration_trekking_label}:"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<int>(
                    hint: Text(local.hours_trekking_label),
                    value: selectedHour,
                    onChanged: (value) => setState(() => selectedHour = value),
                    items: hours
                        .map((hour) => DropdownMenuItem(
                              value: hour,
                              child: Text(hour.toString().padLeft(2, '0')),
                            ))
                        .toList(),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    hint: Text(local.minutes_trekking_label),
                    value: selectedMinute,
                    onChanged: (value) =>
                        setState(() => selectedMinute = value),
                    items: minutes
                        .map((min) => DropdownMenuItem(
                              value: min,
                              child: Text(min.toString().padLeft(2, '0')),
                            ))
                        .toList(),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              // FRIENDS
              Text(local.friends_trekking_label),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  itemCount: user.currentUser!.following.length,
                  itemBuilder: (context, index) {
                    final followingUser = user.currentUser!.following[index];
                    final username = followingUser.username;

                    return FutureBuilder<String>(
                      future: user.getDownloadUrl(followingUser.photoProfile!),
                      builder: (context, snapshot) {
                        String photoUrl = "";
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          photoUrl = snapshot.data!;
                        }

                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (selectedIndex.contains(index)) {
                                selectedIndex.remove(index);
                                friends.remove(followingUser.uid);
                              } else {
                                selectedIndex.add(index);
                                friends.add(followingUser.uid);
                              }
                            });
                          },
                          child: Container(
                            color: selectedIndex.contains(index)
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.transparent,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child:
                                    photoUrl.isEmpty ? Icon(Icons.person) : null,
                              ),
                              title: Text(username),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),
              // NOTES
              Text(local.notes_trekking_label),
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: local.notes_placeholder_trekking_label,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.text_fields),
                ),
                onChanged: (value) => notesText = value,
              ),

              const SizedBox(height: 8),
              // PHOTO PICKER
              Text(local.photos_trekking_label),
              ElevatedButton.icon(
                onPressed: () async {
                  await pickImages(picker, _images);
                },
                icon: Icon(Icons.photo_library),
                label: Text(local.add_botton_label),
              ),
              const SizedBox(height: 8),
              _images.isNotEmpty
                  ? SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        itemBuilder: (_, index) {
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.file(
                              _images[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    )
                  : Container(),

              const SizedBox(height: 16),
              // PUBLIC / PRIVATE BUTTONS
              Text(local.public_private_label),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => isPublic = true),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: isPublic ? Colors.blue : Colors.grey[300],
                      ),
                      child: Text(
                        local.public_botton_label,
                        style: TextStyle(
                          color: isPublic ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => setState(() => isPublic = false),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: !isPublic ? Colors.blue : Colors.grey[300],
                      ),
                      child: Text(
                        local.private_botton_label,
                        style: TextStyle(
                          color: !isPublic ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              // SAVE BUTTON
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(local.cancel_button_label),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        String castedDate =
                            "${selectedDay.toString().padLeft(2, '0')} / "
                            "${selectedMonth.toString().padLeft(2, '0')} / "
                            "${selectedYear.toString()}";
                        double summedDuation =
                            selectedHour!.toDouble() * 60 + selectedMinute!.toDouble();
                        final uploadedUrls =
                            await diary.uploadDiaryImages(_images);

                        widget.diaryController.addDiary(
                          trekkingName.name,
                          isPublic,
                          castedDate,
                          summedDuation,
                          friends,
                          uploadedUrls,
                          challenges,
                          refreshmentText,
                          mood,
                          notesText,
                          false,
                          '',
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserPage(
                              onLocaleChanged: widget.onLocaleChanged,
                              trekkingController: widget.trekkingController,
                              userController: widget.userController,
                              diaryController: widget.diaryController,
                            ),
                          ),
                        );
                      },
                      child: Text(local.save_botton_label),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> pickImages(ImagePicker picker, List<File> images) async {
    final List<XFile>? pickedFiles = await picker.pickMultiImage(
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        images.clear();
        images.addAll(pickedFiles.map((xfile) => File(xfile.path)));
      });
    }
  }
}