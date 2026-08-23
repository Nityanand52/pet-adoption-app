import 'package:flutter/material.dart';
import '../main.dart';
import '../models/adoption_application.dart';

class AdoptionFormPage extends StatefulWidget {
  final Pet pet;
  final String applicantName;
  final String applicantEmail;

  const AdoptionFormPage({
    super.key,
    required this.pet,
    required this.applicantName,
    required this.applicantEmail,
  });

  @override
  State<AdoptionFormPage> createState() => _AdoptionFormPageState();
}

class _AdoptionFormPageState extends State<AdoptionFormPage> {
  final _formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final reasonController = TextEditingController();
  final experienceController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    addressController.dispose();
    reasonController.dispose();
    experienceController.dispose();
    super.dispose();
  }

  void _submitApplication() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final application = AdoptionApplication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pet: widget.pet,
      applicantName: widget.applicantName,
      email: widget.applicantEmail,
      phone: phoneController.text,
      address: addressController.text,
      reason: reasonController.text,
      experience: experienceController.text,
    );

    Navigator.pop(context, application);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adoption Application'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // PET INFORMATION
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.teal.shade100,
                        child: Icon(
                          widget.pet.icon,
                          size: 35,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pet.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.pet.type} • ${widget.pet.age}',
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Your Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              // NAME
              TextFormField(
                initialValue: widget.applicantName,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              // EMAIL
              TextFormField(
                initialValue: widget.applicantEmail,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              // PHONE
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              // ADDRESS
              TextFormField(
                controller: addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 25),

              const Text(
                'About Adoption',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              // REASON
              TextFormField(
                controller: reasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Why do you want to adopt this pet?',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.favorite),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please tell us why you want to adopt';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              // EXPERIENCE
              TextFormField(
                controller: experienceController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Previous pet experience',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.pets),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your experience';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _submitApplication,
                  icon: const Icon(Icons.send),
                  label: const Text(
                    'Submit Application',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Center(
                child: Text(
                  'Your application will be reviewed by the adoption team.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
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