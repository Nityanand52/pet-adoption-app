import 'package:flutter/material.dart';
import '../models/animal_report.dart';

class ReportAnimalPage extends StatefulWidget {
  final Function(AnimalReport) onReportSubmitted;

  const ReportAnimalPage({
    super.key,
    required this.onReportSubmitted,
  });

  @override
  State<ReportAnimalPage> createState() => _ReportAnimalPageState();
}

class _ReportAnimalPageState extends State<ReportAnimalPage> {
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();

  String selectedAnimal = 'Dog';
  String selectedCondition = 'Injured';

  final List<String> animalTypes = [
    'Dog',
    'Cat',
    'Bird',
    'Other',
  ];

  final List<String> conditions = [
    'Injured',
    'Abandoned',
    'Lost',
    'Sick',
    'Other',
  ];

  @override
  void dispose() {
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _submitReport() {
    if (locationController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
        ),
      );
      return;
    }

    final report = AnimalReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      animalType: selectedAnimal,
      location: locationController.text.trim(),
      condition: selectedCondition,
      description: descriptionController.text.trim(),
      date: DateTime.now(),
    );

    widget.onReportSubmitted(report);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Animal report submitted successfully'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Animal'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PHOTO SECTION
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.teal.shade100,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 55,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Add Photo',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Photo upload can be added later',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ANIMAL TYPE
            const Text(
              'Animal Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedAnimal,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.pets),
              ),
              items: animalTypes.map((animal) {
                return DropdownMenuItem(
                  value: animal,
                  child: Text(animal),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedAnimal = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            // LOCATION
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: locationController,
              decoration: InputDecoration(
                hintText: 'Where did you find the animal?',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // CONDITION
            const Text(
              'Condition',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedCondition,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.warning_amber),
              ),
              items: conditions.map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: Text(condition),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCondition = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            // DESCRIPTION
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText:
                'Describe what you saw and what help the animal needs...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitReport,
                icon: const Icon(Icons.send),
                label: const Text(
                  'Submit Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}