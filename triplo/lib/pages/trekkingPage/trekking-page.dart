import 'dart:io';
import 'package:flutter/material.dart';
import 'package:triplo/controller/language.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:flutter/src/material/icons.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/pages/DiaryPage/adding-diary-page.dart';
import 'package:triplo/pages/trekkingPage/details_trekking.dart';
import '../../controller/trekking.dart';
import '../../controller/user.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:triplo/controller/servicecontroller.dart';
import 'package:triplo/widgets_for_pages/weather/weather.dart';
import '../GeowatchPage/geowatch.dart';

// TrekkingPage widget to display detailed information about a trekking
class TrekkingPage extends StatefulWidget {
  final String trekkingId;

  TrekkingPage({super.key, required this.trekkingId});

  @override
  _TrekkingPageState createState() => _TrekkingPageState();
}

class _TrekkingPageState extends State<TrekkingPage> {
  // Icons for the bookmark button (unsaved and saved)
  final List<Icon> icons = [Icon(Icons.bookmark_border), Icon(Icons.bookmark)];
  LatLng? center;
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

  late ServiceController api;

  bool? _isSavedLocal;
  bool _loadingSavedState = true;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    api = context.read<ServiceController>();
  }

  Map<String, dynamic>? weather;
  List<Map<String, dynamic>> forecast = [];
  bool loadingWeather = true;
  String? weatherError;

  @override
  void initState() {
    super.initState();
    // Carichiamo il meteo del percorso (non GPS utente)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //_loadTrailWeather();
      _initSavedState();
    });
  }

  /*Future<void> _loadTrailWeather() async {
    try {
      setState(() {
        loadingWeather = true;
        weatherError = null;
      });

      final trekkingController = context.read<TrekkingController>();
      final trekking = trekkingController.getTrekkingById(widget.trekkingId);
      if (trekking == null) {
        setState(() {
          weatherError = "Trekking not found";
          loadingWeather = false;
        });
        return;
      }
      if (trekking.starting_point != null &&
          trekking.ending_point != null) {
        center = LatLng(
          (trekking.starting_point!.latitude +
              trekking.ending_point!.latitude) /
              2,
          (trekking.starting_point!.longitude +
              trekking.ending_point!.longitude) /
              2,
        );
      } else {
        center = trekking.starting_point ?? const LatLng(46.0, 11.0);
      }

      final LatLng trail = trekking.starting_point ?? const LatLng(0,0);


      final langCode = Localizations.localeOf(context).languageCode;

      final w = await api.weather(
        trail.latitude,
        trail.longitude,
        langCode,
      );

      final f = await api.forecast(
        trail.latitude,
        trail.longitude,
        langCode,
      );

      if (!mounted) return;
      setState(() {
        weather = w;
        forecast = f ?? [];
        loadingWeather = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        weatherError = "Weather unavailable";
        loadingWeather = false;
      });
    }
  }*/

  Future<void> _loadTrailWeatherAfterFetch(Trekking trekking) async {
    try {
      // Calcoliamo il centro per la mappa e il punto per il meteo
      if (trekking.starting_point != null && trekking.ending_point != null) {
        center = LatLng(
          (trekking.starting_point!.latitude +
                  trekking.ending_point!.latitude) /
              2,
          (trekking.starting_point!.longitude +
                  trekking.ending_point!.longitude) /
              2,
        );
      } else {
        center = trekking.starting_point ?? const LatLng(46.0, 11.0);
      }

      final LatLng trail = trekking.starting_point ?? const LatLng(0, 0);
      final langCode = Localizations.localeOf(context).languageCode;

      final w = await api.weather(trail.latitude, trail.longitude, langCode);
      //final f = await api.forecast(trail.latitude, trail.longitude, langCode);

      if (!mounted) return;
      setState(() {
        weather = w;
        //forecast = f ?? [];
        loadingWeather = false;
        weatherError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        weatherError = "Weather unavailable"; 
        loadingWeather = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final languageController = context.watch<Language>();
    final langCode = languageController.locale.languageCode;
    final langIndex = getLanguageSelected(langCode);

    final trekkingController = context.watch<TrekkingController>();
    final trekking = trekkingController.getTrekkingById(widget.trekkingId)!;

    final userController = context.watch<UserController>();

    final user = userController.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off, size: 70, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                local.not_logged_title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                local.not_logged_subtitle,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text(local.go_to_login_button),
              ),
            ],
          ),
        ),
      );
    }


    return FutureBuilder<Trekking?>(
      future: trekkingController.getTrekkingByIdAsync(widget.trekkingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final trekking = snapshot.data;

        if (trekking == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(local.no_trekking_found_label)),
          );
        }

        // Se il trekking è stato appena scaricato e il meteo è ancora in caricamento/errore,
        // facciamo ripartire il caricamento del meteo ora che abbiamo i dati.
        if (loadingWeather && weather == null && weatherError == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadTrailWeatherAfterFetch(trekking);
          });
        }

        // To calculate the trekking durantion time
        String formattedTime;
        if (trekking.estimated_time < 60) {
          formattedTime =
              "${(trekking.estimated_time).toInt()} ${local.minutes_trekking_label}";
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
                  "${trekking.estimated_time ~/ 60} ${local.hour_trekking_label} ${(trekking.estimated_time % 60).toInt()} ${local.minutes_trekking_label}";
            } else {
              formattedTime =
                  "${trekking.estimated_time ~/ 60} ${local.hours_trekking_label} ${(trekking.estimated_time % 60).toInt()} ${local.minutes_trekking_label}";
            }
          }
        }

        // Check if the trekking is saved by the user or not
        final bool isSaved = _isSavedLocal ?? false;

        return Scaffold(
          appBar: AppBar(
            title: Text(trekking.name),
            centerTitle: true,
            actions: [
              //add button
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddingDiaryPage(trekkingId: trekking.documentId),
                    ),
                  );
                },
              ),

              // Play button to start the trekking
              IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DetailsTrekking(trekkingid: trekking.documentId),
                    ),
                  );
                },
              ),

              // Bookmark button to save/unsave the trekking
              IconButton(
                icon: _loadingSavedState
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : (isSaved ? icons[1] : icons[0]),
                onPressed: _loadingSavedState
                    ? null
                    : () async {
                        final previous = isSaved;

                        // UI immediata
                        setState(() {
                          _isSavedLocal = !previous;
                        });

                        try {
                          if (previous) {
                            await trekkingController.removeTrekkingFromSaved(
                              trekking.documentId,
                            );
                          } else {
                            await trekkingController.addTrekkingToSaved(
                              trekking.documentId,
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;

                          // rollback
                          setState(() {
                            _isSavedLocal = previous;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(local.save_route_error)),
                          );
                        }
                      },
              ),
            ],
          ),
          body: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(overscroll: false),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map photo --> close up view
                  _photoSection(
                    trekkingController.getCachedImage(trekking.mapPhoto),
                  ),

                  const SizedBox(height: 16),

                  // Title --> Trekking name
                  Text(
                    trekking.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info card --> starting point, ending point, level, distance, time, elevation gain
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // Starting point
                          _infoRichRow(
                            Icons.place,
                            local.starting_point_trekking_label,
                            trekking.starting_point_name,
                          ),
                          // Ending point
                          _infoRichRow(
                            Icons.flag,
                            local.ending_point_trekking_label,
                            trekking.ending_point_name,
                          ),
                          // Difficulty level
                          _infoRow(
                            Icons.terrain,
                            local.level_label,
                            trekking.difficulty_level == "easy"
                                ? local.beginner_level
                                : trekking.difficulty_level == "intermediate"
                                ? local.intermediate_level
                                : local.advanced_level,
                            valueColor: _difficultyColor(
                              trekking.difficulty_level,
                            ),
                          ),
                          // Distance
                          _infoRow(
                            Icons.straighten,
                            local.distance_trekking_label,
                            "${trekking.distance} km",
                          ),
                          // Estimated time
                          _infoRow(
                            Icons.schedule,
                            local.estimated_time_trekking_label,
                            formattedTime,
                          ),
                          // Elevation gain whit up and down arrows
                          _elevationRow(
                            local.elevaition_gain_trekking_label,
                            trekking.elevation_gain,
                            trekking.upGain,
                            trekking.downGain,
                          ),

                          if (trekking.pic_nic_area == true ||
                              trekking.family_firendly == true)
                            const Divider(),

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                // Picnic area
                                if (trekking.refreshment_point.isNotEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 12),
                                    child: Icon(
                                      Icons.table_restaurant,
                                      size: 25,
                                    ),
                                  ),

                                // Family Friendly
                                if (trekking.family_firendly)
                                  const Icon(Icons.family_restroom, size: 25),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Ending point photo
                  _photoSection(
                    trekkingController.getCachedImage(
                      trekking.endingPointPhoto,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info section
                  _sectionTitle(local.info_trekking_label),
                  Text(trekking.info[langIndex]),

                  const SizedBox(height: 16),

                  // Description section
                  _sectionTitle(local.description_trekking_label),
                  Text(trekking.description[langIndex]),

                  const SizedBox(height: 16),

                  // Refreshment point
                  _refreshmentRow(
                    local.refreshment_point_trekking_label,
                    trekking.refreshment_point.isNotEmpty
                        ? trekking.refreshment_point
                        : local.refreshment_point_available_trekking_label,
                  ),

                  const SizedBox(height: 16),

                  // Challenges section
                  _sectionTitle(local.challenges_trekking_label),
                  trekking.challenges.isNotEmpty
                      ? FutureBuilder<List<File>>(
                          future: trekkingController.getCachedImages(
                            trekking.challenges,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            }

                            if (snapshot.hasError || !snapshot.hasData) {
                              return Text(
                                local.challenges_available_trekking_label,
                              );
                            }

                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: snapshot.data!.map((url) {
                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.2),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Image.file(
                                    url,
                                    height:
                                        45, // Dimensione simile agli screenshot
                                    width: 45,
                                    fit: BoxFit.contain,
                                    // Se l'immagine specifica ha un errore di caricamento
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        )
                      : Text(local.challenges_available_trekking_label),

                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      local.weather_near_trail_label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GeoWatchPage(
                            trailCenter: center,
                            trekkingId: trekking.documentId,
                            trekkingName: trekking.name,
                          )),
                      );
                    },

                    child: Weather(
                      weather: weather,
                      loading: loadingWeather,
                      error: weatherError,
                      hideLocationName: true,
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Get language index based on language code --> it is used to select the correct language from info and description lists
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
      default:
        return 1;
    }
  }

  // Widget to display a photo section with a loading indicator until the image is loaded and then show the image
  Widget _photoSection(Future<File?> future) {
    return FutureBuilder<File?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, size: 40),
          );
        }

        final file = snapshot.data;
        if (file == null) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported, size: 40),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  // Widget to display an information row with an icon, label, and value
  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value, style: TextStyle(color: valueColor)),
          ),
        ],
      ),
    );
  }

  // Widget to display an information row with an icon, label, and value in rich text format
  Widget _infoRichRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),

          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "$label:\n",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget to display a refreshment point row with an icon, label, and value
  Widget _refreshmentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.restaurant, size: 18),
          const SizedBox(width: 8),

          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),

          Expanded(child: Text(value, softWrap: true)),
        ],
      ),
    );
  }

  // Widget to display a section title
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Function to convert difficulty level to color
  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case "easy":
        return Colors.lightBlue;
      case "intermediate":
        return Colors.red;
      case "hard":
        return Colors.black;
      default:
        return Colors.blueGrey; // fallback
    }
  }

  // Widget to display an elevation row with up and down gain indicators
  Widget _elevationRow(
    String label,
    double elevation,
    bool upGain,
    bool downGain,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.trending_up, size: 18),
          const SizedBox(width: 8),

          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),

          Text("$elevation m"),

          const SizedBox(width: 6),

          if (upGain)
            const Icon(Icons.arrow_upward, size: 16, color: Colors.black),

          if (downGain)
            const Icon(Icons.arrow_downward, size: 16, color: Colors.black),
        ],
      ),
    );
  }

  Future<void> _initSavedState() async {
    try {
      final trekkingController = context.read<TrekkingController>();
      final saved = await trekkingController.isTrekkingSaved(widget.trekkingId);

      if (!mounted) return;
      setState(() {
        _isSavedLocal = saved;
        _loadingSavedState = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSavedLocal = false;
        _loadingSavedState = false;
      });
    }
  }
}
