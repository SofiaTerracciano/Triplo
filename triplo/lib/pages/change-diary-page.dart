import 'package:flutter/material.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/diary.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/pages/trekking-page.dart';
import 'package:triplo/pages/user-page.dart';
import 'package:triplo/pages/diary-page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ModifyDiaryPage extends StatefulWidget {
  final void Function(Locale) onLocaleChanged;
  final String trekkingId;
  final TrekkingController trekkingController;
  final UserController userController;
  final DiaryController diaryController;
  final String diaryId;

  ModifyDiaryPage({
    super.key,
    required this.onLocaleChanged,
    required this.trekkingId,
    required this.trekkingController,
    required this.userController,
    required this.diaryController,
    required this.diaryId,
  });

  @override
  ModifyDiaryPageState createState() => ModifyDiaryPageState();
}

class ModifyDiaryPageState extends State<ModifyDiaryPage> {
  final TextEditingController notesController = TextEditingController();
  final TextEditingController refreshmentController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  late Diary diaryPage;

  int? selectedDay;
  int? selectedMonth;
  int? selectedYear;

  int? selectedHour;
  int? selectedMinute;

  final List<File> images = [];
  late List<String> photos;
  List<String> addedPhotos = [];

  bool usedRefreshmentPoint = false;
  late String refreshmentText;

  late String notesText;
  bool isPublic = false;

  late List<String> friends;
  late List<String> challenges;
  late List<String> mood;

  final List<int> selectedIndexChallenge = [];
  final List<int> selectedIndexMood = [];

  @override
  void initState() {
    super.initState();
    diaryPage = widget.diaryController.getDiaryById(widget.diaryId)!;

    // DATE
    final diaryParts = diaryPage.date.split('/');
    selectedDay = int.parse(diaryParts[0]);
    selectedMonth = int.parse(diaryParts[1]);
    selectedYear = int.parse(diaryParts[2]);

    // DURATION
    selectedHour = (diaryPage.duration / 60).toInt();
    selectedMinute = (diaryPage.duration % 60).toInt();

    // 🔥 CLONI (IMPORTANTISSIMO)
    photos = List<String>.from(diaryPage.photos);
    friends = List<String>.from(diaryPage.friends);
    challenges = List<String>.from(diaryPage.challenges);
    mood = List<String>.from(diaryPage.mood);

    // TEXT
    notesText = diaryPage.notes;
    notesController.text = notesText;

    refreshmentText = diaryPage.refreshmentPoint;
    refreshmentController.text = refreshmentText;

    isPublic = diaryPage.isPublic;

    // CHALLENGES SELECTED
    final trekking = widget.trekkingController.getTrekkingById(widget.trekkingId)!;
    selectedIndexChallenge.addAll(
      trekking.challenges
          .asMap()
          .entries
          .where((e) => challenges.contains(e.value))
          .map((e) => e.key),
    );

    final List<String> availableMoods = [
      "😍",
      "😁",
      "🥰",
      "😅",
      "😎",
      "😞",
      "🤩",
    ];

    // MOOD SELECTED
    selectedIndexMood.addAll(
      availableMoods
          .asMap()
          .entries
          .where((e) => mood.contains(e.value))
          .map((e) => e.key),
    );
  }

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

    final validPhotos = photos.where((p) => p.isNotEmpty).toList();

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
                        ? local.friends_trekking_label //da mettere nel dizionario
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
                    title: Text(local.choose_friend_label),
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
                        labelText:
                            local.refreshment_point_trekking_label, //da mettere nel dizionario
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 1,
                      onChanged: (value) {refreshmentText = value;},
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
                              future: trekking.getDownloadUrl(challenge),
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
                    title: Text(
                      local.choose_challenge_label,
                    ),
                    children: [
                      SizedBox(
                        height: 260,
                        child: FutureBuilder(
                          future: Future.wait(
                            trekking
                                .getTrekkingById(widget.trekkingId)!
                                .challenges
                                .map((c) => trekking.getDownloadUrl(c)),
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
                                final challengeName = trekking
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
              /*Column(
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
                          images
                            ..clear()
                            ..addAll(pickedFiles.map((x) => File(x.path)));
                        });
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: Text(local.add_botton_label),
                  ),

                  const SizedBox(height: 8),

                  if (images.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (_, index) {
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.file(
                              images[index],
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
              ),*/

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

                  // Bottone per aggiungere nuove immagini
                  ElevatedButton.icon(
                    onPressed: () async {
                      final pickedFiles = await picker.pickMultiImage(
                        maxWidth: 800,
                        maxHeight: 800,
                      );
                      if (pickedFiles != null && pickedFiles.isNotEmpty) {
                        setState(() {
                          images.addAll(pickedFiles.map((x) => File(x.path)));
                        });
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: Text(local.add_botton_label),
                  ),

                  const SizedBox(height: 8),
                  

                  // Mostrare tutte le immagini (vecchie e nuove) con possibilità di rimuovere
                  if (photos.isNotEmpty || images.isNotEmpty) ...[
                    const SizedBox(height: 8),

                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: validPhotos.length + images.length,
                        itemBuilder: (_, index) {
                          final isExisting = index < validPhotos.length;

                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Stack(
                              children: [
                                if (isExisting)
                                  FutureBuilder<String?>(
                                    future: widget.diaryController
                                        .getDownloadUrlChild(validPhotos[index]),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: Center(
                                            child:
                                                CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        );
                                      }

                                      final url = snapshot.data;

                                      if (url == null || url.isEmpty) {
                                        return _photoPlaceholder();
                                      }

                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          url,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _photoPlaceholder(),
                                        ),
                                      );
                                    },
                                  )
                                else
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      images[index - validPhotos.length],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                // Bottone X in alto a destra
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () async {
                                        if (isExisting) {
                                          await widget.diaryController.deletePhotoFromDb(
                                            widget.diaryId,
                                            validPhotos[index],
                                          );
                                          setState(() {
                                            photos.remove(validPhotos[index]);
                                          });
                                        } else {
                                          setState(() {
                                            images.removeAt(index - validPhotos.length);
                                          });
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.close,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                  Text("${local.public_private_label}"),

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
                            if (!user.currentUser!.publicDiaryPages.contains(
                              diaryPage,
                            )) {
                              user.currentUser!.publicDiaryPages.add(diaryPage);
                              user.currentUser!.privateDiaryPages.remove(
                                diaryPage,
                              );
                            }
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
                            if (!user.currentUser!.privateDiaryPages.contains(
                              diaryPage,
                            )) {
                              user.currentUser!.privateDiaryPages.add(
                                diaryPage,
                              );
                              user.currentUser!.publicDiaryPages.remove(
                                diaryPage,
                              );
                            }
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
                              trekkingController: widget.trekkingController,
                              diaryController: widget.diaryController,
                              userController: widget.userController,
                              onLocaleChanged: widget.onLocaleChanged,
                            ),
                          ),
                        );
                        /*Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiaryPage(
                              onLocaleChanged: widget.onLocaleChanged,
                              trekkingController: widget.trekkingController,
                              userController: widget.userController,
                              diaryId: diary.diaryId,
                              diaryController: widget.diaryController,
                            ),
                          ),
                        );*/
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
                        addedPhotos = await diary.uploadDiaryImages(images);
                        photos.addAll(addedPhotos);
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
                          true,
                          diaryPage.diaryId,
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

Widget _photoPlaceholder() {
  return Container(
    width: 100,
    height: 100,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(
      Icons.image_not_supported,
      size: 40,
    ),
  );
}

