import 'package:flutter/material.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/diary.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/pages/loading-page.dart';
import 'package:triplo/pages/user-page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';

class ModifyDiaryPage extends StatefulWidget {
  final String trekkingId;
  final String diaryId;

  ModifyDiaryPage({super.key, required this.trekkingId, required this.diaryId});

  @override
  ModifyDiaryPageState createState() => ModifyDiaryPageState();
}

class ModifyDiaryPageState extends State<ModifyDiaryPage> {
  final _notesController = TextEditingController();
  final _refreshmentController = TextEditingController();
  final _picker = ImagePicker();

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
    final diaryController = context.read<DiaryController>();
    final trekkingController = context.read<TrekkingController>();
    final userController = context.read<UserController>();



    diaryPage = diaryController.getDiaryById(widget.diaryId)!;

    // Date
    final diaryParts = diaryPage.date.split('/');
    selectedDay = int.parse(diaryParts[0]);
    selectedMonth = int.parse(diaryParts[1]);
    selectedYear = int.parse(diaryParts[2]);

    // Duration
    selectedHour = (diaryPage.duration / 60).toInt();
    selectedMinute = (diaryPage.duration % 60).toInt();

    photos = List<String>.from(diaryPage.photos);
    friends = List<String>.from(diaryPage.friends);
    challenges = List<String>.from(diaryPage.challenges);
    mood = List<String>.from(diaryPage.mood);

    // Notes and Refreshment controller and text
    notesText = diaryPage.notes;
    _notesController.text = notesText;
    refreshmentText = diaryPage.refreshmentPoint;
    usedRefreshmentPoint = refreshmentText.isNotEmpty;
    _refreshmentController.text = refreshmentText;

    isPublic = diaryPage.isPublic;

    // Challenges selected
    final trekking = trekkingController.getTrekkingById(widget.trekkingId)!;
    selectedIndexChallenge.addAll(
      trekking.challenges
          .asMap()
          .entries
          .where((e) => challenges.contains(e.value))
          .map((e) => e.key),
    );

    // Mood available
    final List<String> availableMoods = [
      "😍",
      "😁",
      "🥰",
      "😅",
      "😎",
      "😞",
      "🤩",
    ];

    // Mood selected
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
    final trekkingController = context.watch<TrekkingController>();
    final userController = context.watch<UserController>();
    final diaryController = context.watch<DiaryController>();
    final Trekking trekkingName = trekkingController.getTrekkingById(
      widget.trekkingId,
    )!;
    final local = AppLocalizations.of(context)!;

    final List<int> days = List<int>.generate(31, (i) => i + 1);
    final List<int> months = List<int>.generate(12, (i) => i + 1);
    final int startYear =
    (selectedYear != null && selectedYear! > DateTime.now().year)
        ? selectedYear!
        : DateTime.now().year;

    final List<int> years = List<int>.generate(
      100,
          (i) => startYear - i,
    );
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

    final validPhotos = photos.where((p) => p.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(title: Text(trekkingName.name), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Date picker
              _section(
                context,
                local.date_trekking_label,
                Icons.calendar_today,
                _rowDropdown([
                  _dropdown(
                    selectedDay!,
                    days,
                    (v) => setState(() => selectedDay = v),
                  ),
                  _dropdown(
                    selectedMonth!,
                    months,
                    (v) => setState(() => selectedMonth = v),
                  ),
                  _dropdown(
                    selectedYear!,
                    years,
                    (v) => setState(() => selectedYear = v),
                  ),
                ]),
              ),

              const SizedBox(height: 8),
              // Duration picker
              _section(
                context,
                local.duration_trekking_label,
                Icons.timer,
                _rowDropdown([
                  _dropdown(
                    selectedHour!,
                    hours,
                    (v) => setState(() => selectedHour = v),
                    pad: true,
                  ),
                  _dropdown(
                    selectedMinute!,
                    minutes,
                    (v) => setState(() => selectedMinute = v),
                    pad: true,
                  ),
                ]),
              ),

              const SizedBox(height: 8),
              // Friends
              _section(
                context,
                local.friends_trekking_label,
                Icons.group,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview friends selected
                    friends.isEmpty
                        ? Text(
                            local
                                .friends_selected_label, // "No friends selected"
                            style: const TextStyle(fontSize: 14),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: userController.currentUser!.following
                                .where((u) => friends.contains(u.uid))
                                .map(
                                  (u) => Chip(
                                    avatar: CircleAvatar(
                                      backgroundImage:
                                          (u.photoProfile?.isNotEmpty ?? false)
                                          ? NetworkImage(u.photoProfile!)
                                          : null,
                                      child: (u.photoProfile?.isEmpty ?? true)
                                          ? const Icon(Icons.person, size: 14)
                                          : null,
                                    ),
                                    label: Text(u.username),
                                    onDeleted: () {
                                      setState(() => friends.remove(u.uid));
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                    // Selection of friends
                    const SizedBox(height: 8),
                    ExpansionTile(
                      title: Text(
                        local.choose_friend_label,
                        style: const TextStyle(fontSize: 14)
                      ),
                      children: userController.currentUser!.following.map((u) {
                        final selected = friends.contains(u.uid);
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundImage:
                                (u.photoProfile?.isNotEmpty ?? false)
                                ? NetworkImage(u.photoProfile!)
                                : null,
                            child: (u.photoProfile?.isEmpty ?? true)
                                ? const Icon(Icons.person, size: 18)
                                : null,
                          ),
                          title: Text(
                            u.username,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                          ),
                          onTap: () => setState(() {
                            selected
                                ? friends.remove(u.uid)
                                : friends.add(u.uid);
                          }),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              // Notes
              _section(
                context,
                local.notes_trekking_label,
                Icons.notes,
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: _input(local.notes_placeholder_trekking_label),
                ),
              ),

              const SizedBox(height: 8),
              // Refreshment
              _section(
                context,
                local.refuge_trekking_label,
                Icons.restaurant,
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: Text(local.yes_botton_label),
                          selected: usedRefreshmentPoint,
                          onSelected: (_) =>
                              setState(() => usedRefreshmentPoint = true),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(local.no_botton_label),
                          selected: !usedRefreshmentPoint,
                          onSelected: (_) =>
                              setState(() => usedRefreshmentPoint = false),
                        ),
                      ],
                    ),
                    if (usedRefreshmentPoint) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _refreshmentController,
                        style: const TextStyle(fontSize: 14),
                        decoration: _input(
                          local.refreshment_point_trekking_label,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 8),
              // Challenges
              trekkingName.challenges.isNotEmpty 
                ?  _section(
                    context,
                    local.challenges_trekking_label,
                    Icons.flag,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Preview challenge selected
                        challenges.isEmpty
                            ? Text(
                                local.challenge_selected_label,
                                style: const TextStyle(fontSize: 14),
                              )
                            : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: challenges.map((challenge) {
                                return FutureBuilder<String>(
                                  future: trekkingController.getDownloadUrl(challenge),
                                  builder: (_, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      );
                                    }

                                    return Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            snapshot.data!,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        ),

                                        // Delete button
                                        Positioned.fill(
                                          child: Center(
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  final index =
                                                      trekkingName.challenges.indexOf(challenge);
                                                  challenges.remove(challenge);
                                                  selectedIndexChallenge.remove(index);
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.6),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                        const SizedBox(height: 8),
                        // Challenge selection
                        ExpansionTile(
                          title: Text(
                            local.choose_challenge_label,
                            style: const TextStyle(fontSize: 14),
                          ),
                          children: [
                            SizedBox(
                              height: 260,
                              child: FutureBuilder<List<String>>(
                                future: Future.wait(
                                  trekkingName.challenges.map(
                                    (c) => trekkingController.getDownloadUrl(c),
                                  ),
                                ),
                                builder: (_, snapshot) {
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
                                          crossAxisCount: 4,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                        ),
                                    itemCount: urls.length,
                                    itemBuilder: (_, index) {
                                      final challengeName =
                                          trekkingName.challenges[index];
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
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.green
                                                  : Colors.grey,
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(
                                              urls[index],
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
                  )
                : SizedBox.shrink(),
             
              const SizedBox(height: 8),
              // Mood
              _section(
                context,
                local.mood_trekking_label,
                Icons.mood,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview mood selected
                    mood.isEmpty
                        ? Text(
                            local.mood_selected_label,
                            style: const TextStyle(fontSize: 14),
                          )
                        : Wrap(
                            spacing: 8,
                            children: mood
                                .map(
                                  (m) => Chip(
                                    label: Text(
                                      m,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    onDeleted: () {
                                      setState(() => mood.remove(m));
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                    const SizedBox(height: 8),
                    ExpansionTile(
                      initiallyExpanded: mood.isEmpty,
                      title: Text(local.choose_mood_label),
                      children: List.generate(availableMoods.length, (i) {
                        final emoji = availableMoods[i];
                        final selected = mood.contains(emoji);

                        return ListTile(
                          dense: true,
                          leading: Text(
                            emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          title: Text(
                            availableMoodsLabels[i],
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                          ),
                          onTap: () {
                            setState(() {
                              selected ? mood.remove(emoji) : mood.add(emoji);
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              // Photos
              _section(
                context,
                local.photos_trekking_label,
                Icons.photo,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview images selected
                    if (validPhotos.isNotEmpty || images.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: validPhotos.length + images.length,
                          itemBuilder: (_, index) {
                            final isExisting = index < validPhotos.length;

                            return Padding(
                              padding: const EdgeInsets.all(4),
                              child: Stack(
                                children: [
                                  // Image display
                                  isExisting
                                      ? FutureBuilder<String?>(
                                          future: diaryController
                                              .getDownloadUrlChild(
                                                validPhotos[index],
                                              ),
                                          builder: (_, snapshot) {
                                            if (!snapshot.hasData) {
                                              return const SizedBox(
                                                width: 100,
                                                height: 100,
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              );
                                            }

                                            final url = snapshot.data;

                                            if (url == null || url.isEmpty) {
                                              return _photoPlaceholder();
                                            }

                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.file(
                                            images[index - validPhotos.length],
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),

                                  // Delete button
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () async {
                                        if (isExisting) {
                                          await diaryController
                                              .deletePhotoFromDb(
                                                widget.diaryId,
                                                validPhotos[index],
                                              );
                                          setState(() {
                                            photos.remove(validPhotos[index]);
                                          });
                                        } else {
                                          setState(() {
                                            images.removeAt(
                                              index - validPhotos.length,
                                            );
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
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
                    const SizedBox(height: 8,),
                    // Add photo button
                    Center(
                      child: 
                        ElevatedButton.icon(
                          onPressed: () async {
                            final pickedFiles = await _picker.pickMultiImage(
                              maxWidth: 800,
                              maxHeight: 800,
                            );
                            if (pickedFiles.isNotEmpty) {
                              setState(() {
                                images.addAll(pickedFiles.map((x) => File(x.path)));
                              });
                            }
                          },
                          icon: const Icon(Icons.add_photo_alternate, size: 18),
                          label: Text(local.add_botton_label),
                        ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              // Public/Private botton
              _section(
                context,
                local.public_private_label,
                Icons.lock,
                Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Public
                        _toggle(local.public_botton_label, isPublic, () {
                          setState(() {
                            isPublic = true;

                            final user = userController.currentUser!;

                            // Add to public if not present
                            if (!user.publicDiaryPages.any(
                              (d) => d.diaryId == diaryPage.diaryId,
                            )) {
                              user.publicDiaryPages.add(diaryPage);
                            }

                            // Remove from private
                            user.privateDiaryPages.removeWhere(
                              (d) => d.diaryId == diaryPage.diaryId,
                            );
                          });
                        }),

                        const SizedBox(width: 8),

                        // Private
                        _toggle(local.private_botton_label, !isPublic, () {
                          setState(() {
                            isPublic = false;

                            final user = userController.currentUser!;

                            // Add to private if not present
                            if (!user.privateDiaryPages.any(
                              (d) => d.diaryId == diaryPage.diaryId,
                            )) {
                              user.privateDiaryPages.add(diaryPage);
                            }

                            // Remove from public
                            user.publicDiaryPages.removeWhere(
                              (d) => d.diaryId == diaryPage.diaryId,
                            );
                          });
                        }),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              // Save/Cancel botton
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(local.cancel_button_label),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      child: Text(local.save_botton_label),
                      onPressed: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoadingPage(),
                          ),
                        );
                        // Saved new notes and refreshment point
                        notesText = _notesController.text;
                        if (usedRefreshmentPoint) {
                          refreshmentText = _refreshmentController.text;
                        } else {
                          refreshmentText = "";
                        }

                        String castedDate =
                            "${selectedDay.toString().padLeft(2, '0')} / "
                            "${selectedMonth.toString().padLeft(2, '0')} / "
                            "${selectedYear.toString()}";
                        double summedDuation =
                            selectedHour!.toDouble() * 60 +
                            selectedMinute!.toDouble();
                        addedPhotos = await diaryController.uploadDiaryImages(
                          images,
                        );
                        photos.addAll(addedPhotos);

                        diaryController.currentUser = userController.currentUser!;
                        await diaryController.addDiary(
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
                          MaterialPageRoute(builder: (context) => UserPage()),
                        );
                      },

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

  // Section card widget
  Widget _section(BuildContext context, String title, IconData icon, Widget c) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            c,
          ],
        ),
      ),
    );
  }

  // Row of dropdowns
  Widget _rowDropdown(List<Widget> children) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: children
          .map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: e,
            ),
          )
          .toList(),
    );
  }

  // Dropdown widget
  Widget _dropdown(
    int value,
    List<int> items,
    ValueChanged<int> onChanged, {
    bool pad = false,
  }) {
    return DropdownButton<int>(
      value: value,
      onChanged: (v) => onChanged(v!),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(pad ? e.toString().padLeft(2, '0') : e.toString()),
            ),
          )
          .toList(),
    );
  }

  // Input decoration
  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );

  // Toggle button widget
  Widget _toggle(String label, bool active, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        backgroundColor: active ? const Color(0xFF303030) : Colors.grey[300],
        foregroundColor: active ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: active ? 3 : 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  // Image picker for multiple images
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

  // Placeholder widget for failed image loading
  Widget _photoPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_not_supported, size: 40),
    );
  }
}