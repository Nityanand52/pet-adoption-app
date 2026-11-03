import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../models/animal_report.dart';

class ReportAnimalPage extends StatefulWidget {
  final Future<void> Function(AnimalReport report) onReportSubmitted;

  const ReportAnimalPage({
    super.key,
    required this.onReportSubmitted,
  });

  @override
  State<ReportAnimalPage> createState() => _ReportAnimalPageState();
}

class _ReportAnimalPageState extends State<ReportAnimalPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController =
      TextEditingController();

  final ImagePicker _picker = ImagePicker();

  String? selectedAnimal;
  String? selectedCondition;

  XFile? selectedImage;

  bool isSubmitting = false;

  final List<String> animalTypes = [
    'Dog',
    'Cat',
    'Cow',
    'Buffalo',
    'Goat',
    'Horse',
    'Bird',
    'Other',
  ];

  final List<String> conditions = [
    'Healthy',
    'Injured',
    'Sick',
    'Abandoned',
    'Critical',
  ];

  // Cloudinary configuration
  final String cloudName = 'zmogwtwg';
  final String uploadPreset = 'pet_adoption_uploads';

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          selectedImage = image;
        });
      }
    } catch (e) {
      showMessage('Unable to select image');
    }
  }

  Future<String?> uploadImageToCloudinary() async {
    if (selectedImage == null) {
      return null;
    }

    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = uploadPreset;

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          selectedImage!.path,
        ),
      );

      final response = await request.send();

      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        return data['secure_url'];
      } else {
        debugPrint('Cloudinary error: $responseData');
        throw Exception('Image upload failed');
      }
    } catch (e) {
      debugPrint('Image upload error: $e');
      rethrow;
    }
  }

  Future<void> submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedAnimal == null || selectedCondition == null) {
      showMessage('Please select animal type and condition');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Upload image first
      final String? imageUrl = await uploadImageToCloudinary();

      // Create report object
      final report = AnimalReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        animalType: selectedAnimal!,
        location: locationController.text.trim(),
        condition: selectedCondition!,
        description: descriptionController.text.trim(),
        imagePath: imageUrl,
        date: DateTime.now(),
        status: 'Pending',
      );

      // Save using the callback in main.dart
      await widget.onReportSubmitted(report);

      if (!mounted) return;

      showMessage('Animal report submitted successfully!');

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Report submission error: $e');

      if (mounted) {
        showMessage('Failed to submit report. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Animal'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Help an animal in need',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Provide the animal details so our team can help.',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 25),

              // Animal type
              const Text(
                'Animal Type',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: selectedAnimal,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select animal type',
                ),
                items: animalTypes.map((animal) {
                  return DropdownMenuItem(
                    value: animal,
                    child: Text(animal),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAnimal = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select animal type';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Location
              const Text(
                'Location',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter animal location',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Condition
              const Text(
                'Animal Condition',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: selectedCondition,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select animal condition',
                ),
                items: conditions.map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(condition),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCondition = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select condition';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Description
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Describe the animal and situation...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Image upload
              const Text(
                'Animal Photo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              if (selectedImage != null)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        selectedImage!.path,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.image, size: 50),
                            ),
                          );
                        },
                      ),
                    ),

                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedImage = null;
                        });
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Remove Photo',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                )
              else
                InkWell(
                  onTap: pickImage,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade400,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: Colors.teal,
                        ),
                        SizedBox(height: 10),
                        Text('Upload Animal Photo'),
                        SizedBox(height: 5),
                        Text(
                          'Choose an image from gallery',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}