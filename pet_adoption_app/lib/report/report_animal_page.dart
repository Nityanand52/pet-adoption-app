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

  bool isSubmitting = false;

  @override
  void dispose() {
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (locationController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final report = AnimalReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        animalType: selectedAnimal,
        location: locationController.text.trim(),
        condition: selectedCondition,
        description: descriptionController.text.trim(),
        imagePath: null,
        date: DateTime.now(),
        status: 'Pending',
      );

      // Send report to main.dart
      // main.dart will save it to Firestore.
      await widget.onReportSubmitted(report);

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Animal report submitted successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $e'),
        ),
      );
    }
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

            // TITLE
            const Text(
              'Report an Animal',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Help us know about an animal that needs attention.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
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
                if (value != null) {
                  setState(() {
                    selectedAnimal = value;
                  });
                }
              },
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
                prefixIcon: const Icon(Icons.health_and_safety),
              ),
              items: conditions.map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: Text(condition),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCondition = value;
                  });
                }
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
                hintText: 'Enter where you found the animal',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
                hintText: 'Describe the animal and what happened...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Icon(Icons.description),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Submit Report',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}