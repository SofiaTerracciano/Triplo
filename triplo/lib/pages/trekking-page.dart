import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:flutter/src/material/icons.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/pages/adding-diary-page.dart';
import '../controller/trekking.dart';
import '../controller/user.dart';
import '../controller/diary.dart';
import 'adding-diary-page.dart';

class TrekkingPage extends StatefulWidget {
  final TrekkingController trekkingController;
  final UserController userController;
  final DiaryController diaryController;
  final String trekkingId;
  final void Function(Locale) onLocaleChanged;

  TrekkingPage({
    super.key,
    required this.trekkingController,
    required this.userController,
    required this.diaryController,
    required this.trekkingId,
    required this.onLocaleChanged,
  });

  @override
  _TrekkingPageState createState() => _TrekkingPageState();
}

class _TrekkingPageState extends State<TrekkingPage> {
  // Icons for the bookmark button (unsaved and saved) --> 0:not saved, 1:saved
  final List<Icon> icons = [Icon(Icons.bookmark_border), Icon(Icons.bookmark)];

  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final trekking = widget.trekkingController.getTrekkingById(
      widget.trekkingId,
    )!;
    //final user = widget.userController.currentUser!;
    //per evitare di fare il login ogni volta, carico un user di test
    //final user = widget.userController.getUserById('Aqcz7x94WnPJNYpb48CtuzMbsMj1')!;

    return Scaffold(
      appBar: AppBar(
        title: Text(trekking.name),
        centerTitle: true, // Forced center the title
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddingDiaryPage(
                    trekkingId: trekking.documentId,
                    trekkingController: widget.trekkingController,
                    diaryController: widget.diaryController,
                    userController: widget.userController,
                    onLocaleChanged: widget.onLocaleChanged,
                  ),
                ),
              );
            },
          ),

          FutureBuilder<Users?>(
            future: widget.userController.getUserById('Aqcz7x94WnPJNYpb48CtuzMbsMj1'), 
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SizedBox.shrink(); // Oppure loader
              }

              final user = snapshot.data!;

              final isSaved = user.savedTrekkings.any(
                (t) => t.documentId == trekking.documentId,
              );

              return isSaved
                  ? IconButton(
                      icon: icons[1],
                      onPressed: () {
                        setState(() {
                          widget.userController.removeTrekkingFromSaved(
                            trekking.documentId,
                          );
                        });
                      },
                    )
                  : IconButton(
                      icon: icons[0],
                      onPressed: () {
                        setState(() {
                          widget.userController.addTrekkingToSaved(
                            trekking.documentId,
                          );
                        });
                      },
                    );
            },
          )

          /*if (user.savedTrekkings.any((t) => t.documentId == trekking.documentId,)) ...[
            IconButton(
              icon: icons[1],
              onPressed: () {
                setState(() {
                  widget.userController.removeTrekkingFromSaved(
                    trekking.documentId,
                  );
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: icons[0],
              onPressed: () {
                setState(() {
                  widget.userController.addTrekkingToSaved(trekking.documentId);
                });
              },
            ),
          ],*/
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //placeholder dell'immagine del percorso (facciamo lo screen)
              Row(),
              Row(
                children: [
                  Text(
                    "${trekking.name}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    "${local.starting_point_trekking_label}: ${trekking.starting_point_name}",
                  ),
                ],
              ),
              Row(
                children: [
                  Text("${local.level_label}: ${trekking.difficulty_level}"),
                ],
              ),
              Row(
                children: [
                  Text(
                    "${local.distance_trekking_label}: ${trekking.distance} km",
                  ),
                ],
              ),
              Row(
                children: [
                  if (trekking.estimated_time < 60)
                    Text(
                      "${local.estimated_time_trekking_label}: ${trekking.estimated_time} ${local.minutes_trekking_label}",
                    ),
                  if (trekking.estimated_time >= 60)
                    if (trekking.estimated_time % 60 == 0) ...[
                      if (trekking.estimated_time / 60 == 1) ...[
                        Text(
                          "${local.estimated_time_trekking_label}: ${trekking.estimated_time / 60} ${local.hour_trekking_label}",
                        ),
                      ] else ...[
                        Text(
                          "${local.estimated_time_trekking_label}: ${trekking.estimated_time / 60} ${local.hours_trekking_label}",
                        ),
                      ],
                    ] else ...[
                      if (trekking.estimated_time / 60 == 1) ...[
                        Text(
                          "${local.estimated_time_trekking_label}: ${trekking.estimated_time / 60} ${local.hour_trekking_label} ${trekking.estimated_time % 60} ${local.minutes_trekking_label}",
                        ),
                      ] else ...[
                        Text(
                          "${local.estimated_time_trekking_label}: ${trekking.estimated_time / 60} ${local.hours_trekking_label} ${trekking.estimated_time % 60} ${local.minutes_trekking_label}",
                        ),
                      ],
                    ],
                ],
              ),
              Row(
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '${local.elevaition_gain_trekking_label}: ${trekking.elevation_gain} m',
                          style: TextStyle(color: Colors.black),
                        ),
                        if (trekking.upGain)
                          WidgetSpan(child: Icon(Icons.arrow_upward, size: 16)),
                        if (trekking.downGain)
                          WidgetSpan(
                            child: Icon(Icons.arrow_downward, size: 16),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    "${local.ending_point_trekking_label}: ${trekking.ending_point_name}",
                  ),
                ],
              ),
              //immagine ending point
              Row(),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (locale.languageCode == 'de')
                          Text(
                            "${local.info_trekking_label}: ${trekking.info[0]}",
                          ),
                        if (locale.languageCode == 'en')
                          Text(
                            "${local.info_trekking_label}: ${trekking.info[1]}",
                          ),
                        if (locale.languageCode == 'es')
                          Text(
                            "${local.info_trekking_label}: ${trekking.info[2]}",
                          ),
                        if (locale.languageCode == 'fr')
                          Text(
                            "${local.info_trekking_label}: ${trekking.info[3]}",
                          ),
                        if (locale.languageCode == 'it')
                          Text(
                            "${local.info_trekking_label}: ${trekking.info[4]}",
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (locale.languageCode == 'de')
                          Text(
                            "${local.description_trekking_label}: ${trekking.description[0]}",
                          ),
                        if (locale.languageCode == 'en')
                          Text(
                            "${local.description_trekking_label}: ${trekking.description[1]}",
                          ),
                        if (locale.languageCode == 'es')
                          Text(
                            "${local.description_trekking_label}: ${trekking.description[2]}",
                          ),
                        if (locale.languageCode == 'fr')
                          Text(
                            "${local.description_trekking_label}: ${trekking.description[3]}",
                          ),
                        if (locale.languageCode == 'it')
                          Text(
                            "${local.description_trekking_label}: ${trekking.description[4]}",
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (trekking.refreshment_point != '') ...[
                    Text(
                      "${local.refreshment_point_trekking_label}: ${trekking.refreshment_point}",
                    ),
                  ] else ...[
                    Text(
                      "${local.refreshment_point_trekking_label}: ${local.refreshment_point_available_trekking_label}",
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Text("${local.pic_nic_area_trekking_label}:"),
                  if (trekking.pic_nic_area)
                    Icon(Icons.table_restaurant, color: Colors.grey, size: 16)
                  else
                    Icon(Icons.close, size: 16),
                ],
              ),
              Row(
                children: [
                  Text("${local.family_friendly_trekking_label}:"),
                  if (trekking.family_firendly)
                    Icon(Icons.family_restroom, color: Colors.grey, size: 16)
                  else
                    Icon(Icons.close, size: 16),
                ],
              ),
              if (trekking.challenges.isNotEmpty) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${local.challenges_trekking_label}:"),
                    SizedBox(
                      height: 50, // altezza della riga immagini
                      child: FutureBuilder<List<String>>(
                        future: widget.trekkingController.getDownloadUrls(
                          trekking.challenges,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Text('Errore: ${snapshot.error}');
                          } else {
                            List<String> urls = snapshot.data!;
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: urls.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: Image.network(
                                    urls[index],
                                    fit: BoxFit.contain,
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  "${local.challenges_trekking_label}: ${local.challenges_available_trekking_label}",
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
