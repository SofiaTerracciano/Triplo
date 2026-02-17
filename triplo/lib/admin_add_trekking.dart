import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCreateTrekkingPage extends StatefulWidget {
  const AdminCreateTrekkingPage({super.key});

  @override
  State<AdminCreateTrekkingPage> createState() =>
      _AdminCreateTrekkingPageState();
}

class _AdminCreateTrekkingPageState
    extends State<AdminCreateTrekkingPage> {

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final distanceController = TextEditingController();
  final timeController = TextEditingController();
  final elevationController = TextEditingController();
  final startController = TextEditingController();
  final endController = TextEditingController();

  final infoControllers =
  List.generate(5, (_) => TextEditingController());
  final descControllers =
  List.generate(5, (_) => TextEditingController());

  String difficulty = "easy";
  bool familyFriendly = false;
  bool upGain = true;
  bool downGain = true;

  Future<void> createTrekking() async {
    if (!_formKey.currentState!.validate()) return;

    final db = FirebaseFirestore.instance;

    final trekkingRef = db.collection("trekking").doc();

    await trekkingRef.set({
      "Name": nameController.text.trim(),
      "Difficulty_level": difficulty,
      "Distance": double.parse(distanceController.text),
      "Estimated_time": int.parse(timeController.text),
      "Elevation_gain": double.parse(elevationController.text),
      "Family_friendly": familyFriendly,
      "Up_gain": upGain,
      "Down_gain": downGain,
      "Starting_point_name": startController.text,
      "Ending_point_name": endController.text,
      "Info": infoControllers.map((c) => c.text).toList(),
      "Description": descControllers.map((c) => c.text).toList(),
      "Points": [],
      "Challenges": [],
    });

    // CREATE INDEX
    await db.collection("trekking_index").doc(trekkingRef.id).set({
      "Trekking_id": trekkingRef.id,
      "Trekking_name": nameController.text.trim(),
      "Normalized": nameController.text.trim().toLowerCase(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Trekking creato!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin – Create Trekking")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              DropdownButtonFormField(
                value: difficulty,
                items: const [
                  DropdownMenuItem(value: "easy", child: Text("Easy")),
                  DropdownMenuItem(value: "intermediate", child: Text("Intermediate")),
                  DropdownMenuItem(value: "hard", child: Text("Hard")),
                ],
                onChanged: (v) => difficulty = v!,
              ),

              TextFormField(
                controller: distanceController,
                decoration: const InputDecoration(labelText: "Distance (km)"),
                keyboardType: TextInputType.number,
              ),

              TextFormField(
                controller: timeController,
                decoration: const InputDecoration(labelText: "Estimated time (minutes)"),
                keyboardType: TextInputType.number,
              ),

              TextFormField(
                controller: elevationController,
                decoration: const InputDecoration(labelText: "Elevation gain (m)"),
                keyboardType: TextInputType.number,
              ),

              TextFormField(
                controller: startController,
                decoration: const InputDecoration(labelText: "Starting point name"),
              ),

              TextFormField(
                controller: endController,
                decoration: const InputDecoration(labelText: "Ending point name"),
              ),

              const SizedBox(height: 20),

              const Text("INFO (de, en, es, fr, it)"),
              for (int i = 0; i < 5; i++)
                TextFormField(
                  controller: infoControllers[i],
                  decoration: InputDecoration(
                      labelText: "Info language index $i"),
                  maxLines: 3,
                ),

              const SizedBox(height: 20),

              const Text("DESCRIPTION (de, en, es, fr, it)"),
              for (int i = 0; i < 5; i++)
                TextFormField(
                  controller: descControllers[i],
                  decoration: InputDecoration(
                      labelText: "Description language index $i"),
                  maxLines: 3,
                ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: createTrekking,
                child: const Text("CREATE TREKKING"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
