/*import 'package:flutter/material.dart';
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
  List<String> photos = [];

  bool usedRefreshmentPoint = false;
  String refreshmentText = '';

  String notesText = '';

  bool isPublic = false;

  final List<String> friends = [];
  final List<int> selectedIndexFriends = [];

  final List<String> challenges = [];
  final List<int> selectedIndexChallenge = [];

  final List<String> mood = [];
  final List<int> selectedIndexMood = [];

  @override
  Widget build(BuildContext context) {
    final Trekking trekkingName = widget.trekkingController.getTrekkingById(
      widget.trekkingId,
    )!;
    final local = AppLocalizations.of(context)!;

    final List<int> days = List<int>.generate(31, (i) => i + 1);
    final List<int> months = List<int>.generate(12, (i) => i + 1);
    final List<int> years = List<int>.generate(
      100,
      (i) => 2025 - i,
    ); // ultimi 100 anni
    final List<int> hours = List<int>.generate(24, (i) => i); // 0–23
    final List<int> minutes = List<int>.generate(60, (i) => i); // 0–59

    final List<String> availableMoods = [
      "😍",
      "😁",
      "🥰",
      "😅",
      "😎",
      "😞",
      "🤩",
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
              // Date 
              Text("${local.date_trekking_label}:"),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Day
                  DropdownButton<int>(
                    hint: Text(local.day_trekking_label),
                    value: selectedDay,
                    onChanged: (value) {
                      setState(() => selectedDay = value);
                    },
                    items: days
                        .map((day) => DropdownMenuItem(
                              value: day,
                              child: Text(day.toString()),
                            ))
                        .toList(),
                  ),

                  SizedBox(width: 16),

                  // Month
                  DropdownButton<int>(
                    hint: Text(local.month_trekking_label),
                    value: selectedMonth,
                    onChanged: (value) {
                      setState(() => selectedMonth = value);
                    },
                    items: months
                        .map((month) => DropdownMenuItem(
                              value: month,
                              child: Text(month.toString()),
                            ))
                        .toList(),
                  ),

                  SizedBox(width: 16),

                  // Year
                  DropdownButton<int>(
                    hint: Text(local.year_trekking_label),
                    value: selectedYear,
                    onChanged: (value) {
                      setState(() => selectedYear = value);
                    },
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
              // Duration
              Text("${local.duration_trekking_label}:"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hours
                  DropdownButton<int>(
                    hint: Text(local.hours_trekking_label),
                    value: selectedHour,
                    onChanged: (value) {
                      setState(() {
                        selectedHour = value;
                      });
                    },
                    items: hours
                        .map((hour) => DropdownMenuItem(
                              value: hour,
                              child: Text(hour.toString().padLeft(2, '0')),
                            ))
                        .toList(),
                  ),

                  const SizedBox(width: 16),

                  // Minutes
                  DropdownButton<int>(
                    hint: Text(local.minutes_trekking_label),
                    value: selectedMinute,
                    onChanged: (value) {
                      setState(() {
                        selectedMinute = value;
                      });
                    },
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
              // Friends
              Text(local.friends_trekking_label),
              Expanded(
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
                              if (selectedIndexFriends.contains(index)) {
                                selectedIndexFriends.remove(index);
                                friends.remove(followingUser.uid);
                              } else {
                                selectedIndexFriends.add(index);
                                friends.add(followingUser.uid);
                              }
                            });
                          },
                          child: Container(
                            color: selectedIndexFriends.contains(index)
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.transparent,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: photoUrl.isEmpty ? Icon(Icons.person) : null,
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
              // Notes
              Text(local.notes_trekking_label),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: local.notes_placeholder_trekking_label,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.text_fields),
                ),
                onChanged: (value) {
                  notesText = value;
                },
              ),
              const SizedBox(height: 8),
              // Refreshment
              Text(local.refreshment_point_available_trekking_label),
              Expanded(
                child: Column(
                  children: [
                    Text(local.refreshment_point_trekking_label),
                    SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Yes botton
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              usedRefreshmentPoint = true;
                              TextField(
                                controller: textController,
                                decoration: InputDecoration(
                                  hintText:
                                      local.notes_placeholder_trekking_label,
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.text_fields),
                                ),
                                onChanged: (value) {
                                  refreshmentText = value;
                                },
                              );
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: usedRefreshmentPoint
                                  ? Colors.blue
                                  : Colors.grey[300],
                            ),
                            child: Text(
                              local.yes_botton_label,
                              style: TextStyle(
                                color: usedRefreshmentPoint
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 16),

                        // No botton
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              usedRefreshmentPoint = false;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: !usedRefreshmentPoint
                                  ? Colors.blue
                                  : Colors.grey[300],
                            ),
                            child: Text(
                              local.no_botton_label,
                              style: TextStyle(
                                color: !usedRefreshmentPoint
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Challenges
              Text(local.challenges_trekking_label),
              Expanded(
                child: ListView.builder(
                  itemCount:
                      trekking
                          .getTrekkingById(widget.trekkingId)!
                          .challenges
                          .isNotEmpty
                      ? trekking
                            .getTrekkingById(widget.trekkingId)!
                            .challenges
                            .length
                      : 0,
                  itemBuilder: (context, index) {
                    final challenge = trekking
                        .getTrekkingById(widget.trekkingId)!
                        .challenges[index];
                    return FutureBuilder<String>(
                      future: trekking.getDownloadUrl(challenge),
                      builder: (context, snapshot) {
                        String photoUrl = "";
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          photoUrl = snapshot.data!;
                        }

                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (selectedIndexChallenge.contains(index)) {
                                selectedIndexChallenge.remove(index);
                                challenges.remove(challenge);
                              } else {
                                selectedIndexChallenge.add(index);
                                challenges.add(challenge);
                              }
                            });
                          },
                          child: Container(
                            color: selectedIndexChallenge.contains(index)
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.transparent,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: photoUrl.isEmpty ? Icon(Icons.person) : null,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Mood
              Text(local.mood_trekking_label),
              Column(
                children: [
                  Text(local.mood_trekking_label),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: availableMoods.length,
                      itemBuilder: (context, index) {
                        final emoji = availableMoods[index];
                        final label =
                            availableMoodsLabels[index]; // lista dei testi corrispondenti

                        final isSelected = selectedIndexMood.contains(index);

                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedIndexMood.remove(index);
                                mood.remove(emoji);
                              } else {
                                selectedIndexMood.add(index);
                                mood.add(emoji);
                              }
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            color: isSelected
                                ? Colors.blue.withOpacity(0.3)
                                : Colors.transparent,
                            child: Row(
                              children: [
                                Text(emoji, style: TextStyle(fontSize: 24)),
                                SizedBox(width: 12),
                                Text(label, style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Photos
              Text(local.photos_trekking_label),
              ElevatedButton.icon(
                onPressed: () async {
                  await pickImages(picker, _images);
                },
                icon: Icon(Icons.photo_library),
                label: Text(local.add_botton_label),
              ),
              SizedBox(height: 8),
              // Anteprima immagini
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

              const SizedBox(height: 8),
              // Public/Private botton
              Expanded(
                child: Column(
                  children: [
                    Text(local.public_private_label),
                    SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Public botton
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isPublic = true;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
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

                        // Private botton
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isPublic = false;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
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
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Add/Cancel botton
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrekkingPage(
                              trekkingId: trekkingName.documentId,
                              trekkingController: widget.trekkingController,
                              diaryController: widget.diaryController,
                              userController: widget.userController,
                              onLocaleChanged: widget.onLocaleChanged,
                            ),
                          ),
                        );
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
                            selectedHour!.toDouble() * 60 +
                            selectedMinute!.toDouble();
                        photos = await diary.uploadDiaryImages(_images);
                        widget.diaryController.addDiary(
                          trekkingName.name,
                          isPublic,
                          castedDate,
                          summedDuation,
                          friends,
                          photos,
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
      )
    );
  }

  Future<void> pickImages(ImagePicker picker, List<File> images) async {
    final List<XFile>? pickedFiles = await picker.pickMultiImage(
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        images = pickedFiles.map((xfile) => File(xfile.path)).toList();
      });
    }
  }
}*/

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
  final ImagePicker picker = ImagePicker();

  int? selectedDay = 1;
  int? selectedMonth = 1;
  int? selectedYear = 2000;

  int? selectedHour = 0;
  int? selectedMinute = 0;

  final List<File> _images = [];
  List<String> photos = [];

  bool usedRefreshmentPoint = false;
  String refreshmentText = '';

  String notesText = '';

  bool isPublic = false;

  final List<String> friends = [];
  final List<int> selectedIndexFriends = [];

  final List<String> challenges = [];
  final List<int> selectedIndexChallenge = [];

  final List<String> mood = [];
  final List<int> selectedIndexMood = [];

  @override
  Widget build(BuildContext context) {
    final Trekking trekkingName = widget.trekkingController.getTrekkingById(
      widget.trekkingId,
    )!;
    final local = AppLocalizations.of(context)!;

    final List<int> days = List<int>.generate(31, (i) => i + 1);
    final List<int> months = List<int>.generate(12, (i) => i + 1);
    final List<int> years = List<int>.generate(
      100,
      (i) => 2025 - i,
    ); // ultimi 100 anni
    final List<int> hours = List<int>.generate(24, (i) => i); // 0–23
    final List<int> minutes = List<int>.generate(60, (i) => i); // 0–59

    final List<String> availableMoods = [
      "😍",
      "😁",
      "🥰",
      "😅",
      "😎",
      "😞",
      "🤩",
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
              // Date
              Text("${local.date_trekking_label}:"),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Day
                  DropdownButton<int>(
                    hint: Text(local.day_trekking_label),
                    value: selectedDay,
                    onChanged: (value) {
                      setState(() => selectedDay = value);
                    },
                    items: days
                        .map(
                          (day) => DropdownMenuItem(
                            value: day,
                            child: Text(day.toString()),
                          ),
                        )
                        .toList(),
                  ),

                  SizedBox(width: 16),

                  // Month
                  DropdownButton<int>(
                    hint: Text(local.month_trekking_label),
                    value: selectedMonth,
                    onChanged: (value) {
                      setState(() => selectedMonth = value);
                    },
                    items: months
                        .map(
                          (month) => DropdownMenuItem(
                            value: month,
                            child: Text(month.toString()),
                          ),
                        )
                        .toList(),
                  ),

                  SizedBox(width: 16),

                  // Year
                  DropdownButton<int>(
                    hint: Text(local.year_trekking_label),
                    value: selectedYear,
                    onChanged: (value) {
                      setState(() => selectedYear = value);
                    },
                    items: years
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Duration
              Text("${local.duration_trekking_label}:"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hours
                  DropdownButton<int>(
                    hint: Text(local.hours_trekking_label),
                    value: selectedHour,
                    onChanged: (value) {
                      setState(() {
                        selectedHour = value;
                      });
                    },
                    items: hours
                        .map(
                          (hour) => DropdownMenuItem(
                            value: hour,
                            child: Text(hour.toString().padLeft(2, '0')),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(width: 16),

                  // Minutes
                  DropdownButton<int>(
                    hint: Text(local.minutes_trekking_label),
                    value: selectedMinute,
                    onChanged: (value) {
                      setState(() {
                        selectedMinute = value;
                      });
                    },
                    items: minutes
                        .map(
                          (min) => DropdownMenuItem(
                            value: min,
                            child: Text(min.toString().padLeft(2, '0')),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Friends
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${local.friends_trekking_label}: ",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    friends.isEmpty
                        ? "Nessun amico selezionato" //da mettere nel dizionario
                        : user.currentUser!.following
                              .where((u) => friends.contains(u.uid))
                              .map((u) => u.username)
                              .join(
                                ", ",
                              ), // visualizzati del tipo Friends: amico1, amico2, amico3
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 12),

                  ExpansionTile(
                    title: Text("Seleziona amici"), // da mettere nel dizionario
                    children: [
                      SizedBox(
                        height: 220, // lista scrollabile
                        child: ListView.builder(
                          itemCount: user.currentUser!.following.length,
                          itemBuilder: (context, index) {
                            final followingUser =
                                user.currentUser!.following[index];
                            final isSelected = friends.contains(
                              followingUser.uid,
                            );

                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  followingUser.username[0].toUpperCase(),
                                ),
                              ),
                              title: Text(followingUser.username),
                              trailing: Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                              ),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    friends.remove(followingUser.uid);
                                  } else {
                                    friends.add(followingUser.uid);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),
              // Notes
              Text("${local.notes_trekking_label}: "),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: local.notes_placeholder_trekking_label,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.text_fields),
                ),
                onChanged: (value) {
                  notesText = value;
                },
              ),
              const SizedBox(height: 8),
              // Refreshment
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${local.refuge_trekking_label}: ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: usedRefreshmentPoint,
                        onChanged: (val) {
                          setState(() {
                            usedRefreshmentPoint = val!;
                          });
                        },
                      ),
                      Text(local.yes_botton_label),
                      const SizedBox(width: 20),
                      Radio<bool>(
                        value: false,
                        groupValue: usedRefreshmentPoint,
                        onChanged: (val) {
                          setState(() {
                            usedRefreshmentPoint = val!;
                          });
                        },
                      ),
                      Text(local.no_botton_label),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (usedRefreshmentPoint)
                    TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        labelText:
                            "Descrivi il refreshment point", //da mettere nel dizionario
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 1,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${local.challenges_trekking_label}: ",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    challenges.isEmpty
                        ? "Nessuna challenge selezionata" //da mettere nel dizionario
                        : challenges.join(", "), // lista separata da virgola
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 8),

                  ExpansionTile(
                    title: Text(
                      "Seleziona challenges",
                    ), // da mettere nel dizionario
                    children: [
                      SizedBox(
                        height: 220, // altezza della lista scrollabile
                        child: ListView.builder(
                          itemCount: trekking
                              .getTrekkingById(widget.trekkingId)!
                              .challenges
                              .length,
                          itemBuilder: (context, index) {
                            final challenge = trekking
                                .getTrekkingById(widget.trekkingId)!
                                .challenges[index];

                            return FutureBuilder<String>(
                              future: trekking.getDownloadUrl(challenge),
                              builder: (context, snapshot) {
                                String photoUrl = "";
                                if (snapshot.connectionState ==
                                        ConnectionState.done &&
                                    snapshot.hasData) {
                                  photoUrl = snapshot.data!;
                                }

                                final isSelected = selectedIndexChallenge
                                    .contains(index);

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedIndexChallenge.remove(index);
                                        challenges.remove(challenge);
                                      } else {
                                        selectedIndexChallenge.add(index);
                                        challenges.add(challenge);
                                      }
                                    });
                                  },
                                  child: Container(
                                    color: isSelected
                                        ? Colors.grey.withOpacity(0.3)
                                        : Colors.transparent,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: photoUrl.isNotEmpty
                                            ? NetworkImage(photoUrl)
                                            : null,
                                        child: photoUrl.isEmpty
                                            ? Icon(Icons.image)
                                            : null,
                                      ),
                                      trailing: isSelected
                                          ? Icon(
                                              Icons.check_circle,
                                              color: Colors.blue,
                                            )
                                          : Icon(Icons.circle_outlined),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Mood
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${local.mood_trekking_label}: ",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    mood.isEmpty
                        ? "Nessun mood selezionato" // da mettere nel dizionario
                        : mood.join(
                            ", ",
                          ), // mostra solo gli emoji separati da virgola
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 12),

                  ExpansionTile(
                    title: Text("Seleziona mood"), // da mmettere nel dizionario
                    children: [
                      SizedBox(
                        height: 220, // altezza della lista scrollabile
                        child: ListView.builder(
                          itemCount: availableMoods.length,
                          itemBuilder: (context, index) {
                            final emoji = availableMoods[index];
                            final label = availableMoodsLabels[index];
                            final isSelected = selectedIndexMood.contains(
                              index,
                            );

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedIndexMood.remove(index);
                                    mood.remove(emoji);
                                  } else {
                                    selectedIndexMood.add(index);
                                    mood.add(emoji);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                color: isSelected
                                    ? Colors.blue.withOpacity(0.3)
                                    : Colors.transparent,
                                child: Row(
                                  children: [
                                    Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      label,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Photos
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${local.photos_trekking_label}: ",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: () async {
                      final pickedFiles = await picker.pickMultiImage(
                        maxWidth: 800,
                        maxHeight: 800,
                      );
                      if (pickedFiles.isNotEmpty) {
                        setState(() {
                          _images
                            ..clear()
                            ..addAll(pickedFiles.map((x) => File(x.path)));
                        });

                        photos = await widget.diaryController.uploadDiaryImages(
                          _images,
                        );
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: Text(local.add_botton_label),
                  ),

                  const SizedBox(height: 8),

                  if (_images.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
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
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // Public/Private botton
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text("${local.public_private_label}: "),
                        SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Public botton
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isPublic = true;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: isPublic
                                      ? Colors.blue
                                      : Colors.grey[300],
                                ),
                                child: Text(
                                  local.public_botton_label,
                                  style: TextStyle(
                                    color: isPublic
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: 16),

                            // Private botton
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isPublic = false;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: !isPublic
                                      ? Colors.blue
                                      : Colors.grey[300],
                                ),
                                child: Text(
                                  local.private_botton_label,
                                  style: TextStyle(
                                    color: !isPublic
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Add/Cancel botton
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrekkingPage(
                              trekkingId: trekkingName.documentId,
                              trekkingController: widget.trekkingController,
                              diaryController: widget.diaryController,
                              userController: widget.userController,
                              onLocaleChanged: widget.onLocaleChanged,
                            ),
                          ),
                        );
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
                            selectedHour!.toDouble() * 60 +
                            selectedMinute!.toDouble();
                        photos = await diary.uploadDiaryImages(_images);
                        widget.diaryController.addDiary(
                          trekkingName.name,
                          isPublic,
                          castedDate,
                          summedDuation,
                          friends,
                          photos,
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
        images = pickedFiles.map((xfile) => File(xfile.path)).toList();
      });
    }
  }
}
