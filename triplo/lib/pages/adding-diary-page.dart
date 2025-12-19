import 'package:flutter/material.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/pages/trekking-page.dart';
import 'package:triplo/pages/user-page.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/controller/diary.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
class AddingDiaryPage extends StatefulWidget {
  final String trekkingId;

  const AddingDiaryPage({
    super.key,
    required this.trekkingId,
  });

  @override
  AddingDiaryPageState createState() => AddingDiaryPageState();
}

class AddingDiaryPageState extends State<AddingDiaryPage> {
  final TextEditingController notesController = TextEditingController();
  final TextEditingController refreshmentController = TextEditingController();
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

  bool isPublic =
      false; 

  final List<String> friends = [];
  final List<int> selectedIndexFriends = [];

  final List<String> challenges = [];
  final List<int> selectedIndexChallenge = [];

  final List<String> mood = [];
  final List<int> selectedIndexMood = [];

  @override
  Widget build(BuildContext context) {
    final trekkingController = context.watch<TrekkingController>();
    final userController = context.watch<UserController>();
    final diaryController = context.watch<DiaryController>();

    final Trekking trekkingName = trekkingController.getTrekkingById(
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
                        ? local.friends_selected_label 
                        : userController.currentUser!.following
                              .where((u) => friends.contains(u.uid))
                              .map((u) => u.username)
                              .join(
                                ", ",
                              ), // visualizzati del tipo Friends: amico1, amico2, amico3
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 12),

                  ExpansionTile(
                    title: Text(local.choose_friend_label), 
                    children: [
                      SizedBox(
                        height: 220, // lista scrollabile
                        child: ListView.builder(
                          itemCount: userController.currentUser!.following.length, //da cambiare con following index
                          itemBuilder: (context, index) {
                            final followingUser =
                                userController.currentUser!.following[index]; 
                            final isSelected = friends.contains(
                              followingUser.uid,
                            );

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: followingUser.photoProfile != null &&
                                        followingUser.photoProfile!.isNotEmpty
                                    ? NetworkImage(followingUser.photoProfile!)
                                    : null,
                                child: followingUser.photoProfile == null ||
                                        followingUser.photoProfile!.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
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
                controller: notesController,
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
                      controller: refreshmentController,
                      decoration: InputDecoration(
                        labelText: local.notes_placeholder_trekking_label,
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 1,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Challenges
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

                  // Mostra immagini selezionate
                  challenges.isEmpty
                      ? Text(
                          local.challenge_selected_label, 
                          style: TextStyle(fontSize: 16),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: challenges.map((challenge) {
                            return FutureBuilder<String>(
                              future: trekkingController.getDownloadUrl(challenge),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                        ConnectionState.done &&
                                    snapshot.hasData) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      snapshot.data!,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                }
                                return const SizedBox(
                                  width: 70,
                                  height: 70,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 8),

                  // Challenges
                  ExpansionTile(
                    title: Text(local.choose_challenge_label), 
                    children: [
                      SizedBox(
                        height: 260,
                        child: FutureBuilder(
                          future: Future.wait(
                            trekkingController
                                .getTrekkingById(widget.trekkingId)!
                                .challenges
                                .map((c) => trekkingController.getDownloadUrl(c)),
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final urls = snapshot.data!;

                            return GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        4, // 4 per riga --> si crea uan cosa Nx4
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              itemCount: urls.length,
                              itemBuilder: (context, index) {
                                final challengeName = trekkingController
                                    .getTrekkingById(widget.trekkingId)!
                                    .challenges[index];

                                final imageUrl = urls[index];

                                final isSelected = selectedIndexChallenge
                                    .contains(index);

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedIndexChallenge.remove(index);
                                        challenges.remove(challengeName);
                                      } else {
                                        selectedIndexChallenge.add(index);
                                        challenges.add(challengeName);
                                      }
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color.fromARGB(
                                                255,
                                                155,
                                                241,
                                                158,
                                              )
                                            : Colors.grey,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                      ),
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
                        ? local.mood_selected_label
                        : mood.join(
                            ", ",
                          ), // mostra solo gli emoji separati da virgola
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 12),

                  ExpansionTile(
                    title: Text(local.choose_mood_label), 
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(local.public_private_label),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // PUBLIC
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPublic
                              ? const Color.fromARGB(255, 48, 48, 48)
                              : Colors.grey[300],
                          foregroundColor: isPublic
                              ? Colors.white
                              : Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: isPublic
                              ? 4
                              : 0, // ombra SOLO quando selezionato
                        ),
                        onPressed: () {
                          setState(() {
                            isPublic = true;
                          });
                        },
                        child: Text(local.public_botton_label),
                      ),

                      const SizedBox(width: 16),

                      // PRIVATE
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !isPublic
                              ? const Color.fromARGB(255, 48, 48, 48)
                              : Colors.grey[300],
                          foregroundColor: !isPublic
                              ? Colors.white
                              : Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: !isPublic
                              ? 4
                              : 0, // ombra SOLO quando selezionato
                        ), 
                        onPressed: () {
                          setState(() {
                            isPublic = false;
                          });
                        },
                        child: Text(local.private_botton_label),
                      ),
                    ],
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
                        photos = await diaryController.uploadDiaryImages(_images);
                        diaryController.addDiary(
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
                            builder: (context) => UserPage(),
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
