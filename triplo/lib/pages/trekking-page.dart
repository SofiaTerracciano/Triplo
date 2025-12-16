import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  final titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  final labelStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600, // semibold
    color: Colors.black87,
  );

  final valueStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: const Color.fromARGB(255, 0, 0, 0),
  );

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final trekking = widget.trekkingController.getTrekkingById(
      widget.trekkingId,
    )!;

    final user = widget.userController.currentUser!;

    // To calculate the trekking durantion time
    String formattedTime;
    if (trekking.estimated_time < 60) {
      formattedTime =
          "${trekking.estimated_time} ${local.minutes_trekking_label}";
    } else {
      if (trekking.estimated_time % 60 == 0) {
        if (trekking.estimated_time / 60 == 1) {
          formattedTime =
              "${trekking.estimated_time ~/ 60} ${local.hour_trekking_label}";
        } else {
          formattedTime =
              "${trekking.estimated_time ~/ 60} ${local.hours_trekking_label}";
        }
      } else {
        if (trekking.estimated_time / 60 == 1) {
          formattedTime =
              "${trekking.estimated_time ~/ 60} ${local.hour_trekking_label} ${trekking.estimated_time % 60} ${local.minutes_trekking_label}";
        } else {
          formattedTime =
              "${trekking.estimated_time ~/ 60} ${local.hours_trekking_label} ${trekking.estimated_time % 60} ${local.minutes_trekking_label}";
        }
      }
    }

    final bool isSaved = user.savedTrekkings.any((t) => t.documentId == trekking.documentId);

    return Scaffold(
      appBar: AppBar(
        title: Text(trekking.name),
        centerTitle: true, // Forced center the title
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.pushReplacement(
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

          IconButton(
            icon: isSaved ? icons[1] : icons[0],
            onPressed: () async {
              if (isSaved) {
                await widget.userController.removeTrekkingFromSaved(
                  trekking.documentId,
                );
              } else {
                await widget.userController.addTrekkingToSaved(
                  trekking.documentId,
                );
              }

              setState(() {}); // ricostruisce l'AppBar
            },
          ),
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
              // Trekking name
              Row(
                children: [
                  Text(
                    trekking.name, 
                    style: titleStyle
                  )
                ]
              ),
              SizedBox(height: 3,),
              // Starting point
              Row(
                children: [
                  Text(
                    "${local.starting_point_trekking_label}: ",
                    style: labelStyle,
                  ),
                  Expanded(
                    child: Text(
                      trekking.starting_point_name,
                      style: valueStyle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3,),
              // Difficulty
              Row(
                children: [
                  Text(
                    "${local.level_label}: ", 
                    style: labelStyle
                  ),
                  Expanded(
                    child: Text(
                      trekking.difficulty_level,
                      style: valueStyle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3,),
              // Distance
              Row(
                children: [
                  Text(
                    "${local.distance_trekking_label}: ", 
                    style: labelStyle
                  ),
                  Expanded(
                    child: Text(
                      "${trekking.distance} km", 
                      style: valueStyle
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3,),
              // Estimated time
              Row(
                children: [
                  Text(
                    "${local.estimated_time_trekking_label}: ",
                    style: labelStyle,
                  ),
                  Expanded(
                    child: Text(
                      formattedTime, 
                      style: valueStyle
                    )
                  ),
                ],
              ),
              SizedBox(height: 3,),
              // Elevation gain
              Row(
                children: [
                  Text(
                    "${local.elevaition_gain_trekking_label}: ",
                    style: labelStyle,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${trekking.elevation_gain} m",
                          style: valueStyle,
                        ),
                        if (trekking.upGain)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.arrow_upward, size: 16, color: Colors.black),
                          ),
                        if (trekking.downGain)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.arrow_downward, size: 16, color: Colors.black),
                          ),
                      ]
                    )
                  ),
                ],
              ),
              SizedBox(height: 3,),
              // Ending point 
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${local.ending_point_trekking_label}: ",
                      style: labelStyle,
                    ),
                    TextSpan(
                      text: trekking.ending_point_name,
                      style: valueStyle,
                    )
                  ]
                )
              ),
              // Ending point image
              Row(),
              SizedBox(height: 3,),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${local.info_trekking_label}: ",
                      style: labelStyle,
                    ),
                    TextSpan(
                      text: trekking.info[getLanguageSelected(locale.languageCode)],
                      style: valueStyle,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3,),
              // Description 
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${local.description_trekking_label}: ",
                      style: labelStyle,
                    ),
                    TextSpan(
                      text: trekking.description[getLanguageSelected(locale.languageCode)],
                      style: valueStyle,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 3,),
              // Refreshment point 
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${local.refreshment_point_trekking_label}: ",
                      style: labelStyle,
                    ),
                    if (trekking.refreshment_point != '') ...[
                      TextSpan(
                        text: trekking.refreshment_point,
                        style: valueStyle,
                      ),
                    ] else ...[
                      TextSpan(
                        text: local.refreshment_point_available_trekking_label,
                        style: valueStyle,
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 3,),
              // Pic nic area
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${local.pic_nic_area_trekking_label}: ",
                      style: labelStyle,
                    ),
                    if (trekking.refreshment_point != '') ...[
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(Icons.table_restaurant, color: Colors.black, size: 16),
                      )
                    ] else ...[
                      TextSpan(
                        text: local.pic_nic_area_available_trekking_label,
                        style: valueStyle,
                      ),
                    ],
                  ],
                ),
              ),
          
              SizedBox(height: 3,),
              // Family friendly
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${local.family_friendly_trekking_label}: ",
                      style: labelStyle,
                    ),
                    if (trekking.family_firendly)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(Icons.family_restroom, color: Colors.black, size: 16),
                      )
                    else
                      TextSpan(
                        text: local.family_friendly_available_trekking_label, 
                        style: labelStyle,
                      ),
                  ],
                ),
              ),

              SizedBox(height: 3,),
              // Challenges
              if (trekking.challenges.isNotEmpty) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${local.challenges_trekking_label}:", 
                      style: labelStyle
                    ),
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
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "${local.challenges_trekking_label}: ",
                        style: labelStyle,
                      ),
                      TextSpan(
                        text: local.challenges_available_trekking_label,
                        style: valueStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

int getLanguageSelected(String code) {
  switch (code) {
    case 'de': 
      return 0;
    case 'en': 
      return 1;
    case 'es': 
      return 2;
    case 'fr':
      return 3;
    case 'it': 
      return 4;

    default: return 1; 
  }
}

