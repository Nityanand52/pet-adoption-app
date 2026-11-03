import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ManagePetsPage extends StatelessWidget {
  const ManagePetsPage({super.key});

  CollectionReference<Map<String, dynamic>> get pets =>
      FirebaseFirestore.instance.collection('pets');

  Future<String?> uploadPetImage(XFile image) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/zmogwtwg/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = 'pet_adoption_uploads'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          await image.readAsBytes(),
          filename: image.name,
        ),
      );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed: $body');
    }

    final result = jsonDecode(body) as Map<String, dynamic>;
    return result['secure_url'] as String?;
  }

  Future<void> showPetForm(
    BuildContext context, {
    String? petId,
    Map<String, dynamic>? pet,
  }) async {
    final name = TextEditingController(text: pet?['name']?.toString() ?? '');
    final breed = TextEditingController(text: pet?['breed']?.toString() ?? '');
    final age = TextEditingController(text: pet?['age']?.toString() ?? '');
    final description = TextEditingController(
      text: pet?['description']?.toString() ?? '',
    );
    final fee = TextEditingController(
      text: (pet?['adoptionFee'] ?? pet?['price'])?.toString() ?? '0',
    );
    final location = TextEditingController(
      text: pet?['location']?.toString() ?? '',
    );

    const animalTypes = [
      'Dog', 'Cat', 'Rabbit', 'Bird', 'Hamster',
      'Guinea Pig', 'Turtle', 'Fish',
    ];
    const genders = ['Male', 'Female', 'Unknown'];
    const healthStatuses = [
      'Healthy', 'Under Treatment', 'Recovering', 'Special Needs', 'Unknown',
    ];
    const sterilizationOptions = ['Yes', 'No', 'Unknown'];

    String type = animalTypes.contains(pet?['type'])
        ? pet!['type'] as String
        : 'Dog';
    String ageUnit = pet?['ageUnit']?.toString() == 'Years'
        ? 'Years'
        : 'Months';
    String gender = genders.contains(pet?['gender'])
        ? pet!['gender'] as String
        : 'Unknown';
    String health = healthStatuses.contains(pet?['healthStatus'])
        ? pet!['healthStatus'] as String
        : 'Unknown';
    String sterilized = sterilizationOptions.contains(pet?['sterilized'])
        ? pet!['sterilized'] as String
        : 'Unknown';

    bool vaccinated = pet?['isVaccinated'] == true;
    bool saving = false;
    XFile? selectedImage;
    String? imageUrl = pet?['imageUrl']?.toString();
    final formKey = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> chooseImage() async {
              try {
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                  maxWidth: 1200,
                );
                if (picked != null && dialogContext.mounted) {
                  setDialogState(() => selectedImage = picked);
                }
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Image selection failed: $e')),
                );
              }
            }

            InputDecoration decoration(String label, {String? hint}) =>
                InputDecoration(
                  labelText: label,
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                );

            Widget sectionTitle(String number, String title, String subtitle) {
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context)
                          .colorScheme.primaryContainer,
                      child: Text(
                        number,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          Text(subtitle,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            Widget dropdown<T>({
              required String label,
              required T value,
              required List<T> items,
              required ValueChanged<T?> onChanged,
            }) {
              return DropdownButtonFormField<T>(
                value: value,
                isExpanded: true,
                decoration: decoration(label),
                items: items
                    .map((item) => DropdownMenuItem<T>(
                          value: item,
                          child: Text(item.toString()),
                        ))
                    .toList(),
                onChanged: saving ? null : onChanged,
              );
            }

            Widget textField(
              TextEditingController controller,
              String label, {
              String? hint,
              int maxLines = 1,
              TextInputType keyboardType = TextInputType.text,
              String? Function(String?)? validator,
            }) {
              return TextFormField(
                controller: controller,
                maxLines: maxLines,
                keyboardType: keyboardType,
                decoration: decoration(label, hint: hint),
                validator: validator ??
                    (value) => value == null || value.trim().isEmpty
                        ? 'Please enter $label'
                        : null,
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
              contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(petId == null ? 'Add New Pet' : 'Edit Pet',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 21)),
                        const SizedBox(height: 4),
                        Text('Create an adoption listing',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.pets,
                      color: Theme.of(context).colorScheme.primary, size: 28),
                ],
              ),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        sectionTitle('1', 'Basic information',
                            'Tell adopters about this animal'),
                        if (selectedImage != null)
                          FutureBuilder<Uint8List>(
                            future: selectedImage!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox(
                                  height: 150,
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.memory(
                                  snapshot.data!,
                                  height: 165,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          )
                        else if (imageUrl != null && imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              imageUrl!,
                              height: 165,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 60),
                            ),
                          )
                        else
                          Container(
                            height: 115,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 30),
                                SizedBox(height: 6),
                                Text('Add a clear pet photo'),
                              ],
                            ),
                          ),
                        const SizedBox(height: 9),
                        OutlinedButton.icon(
                          onPressed: saving ? null : chooseImage,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(selectedImage != null || imageUrl != null
                              ? 'Change photo'
                              : 'Choose pet photo'),
                        ),
                        const SizedBox(height: 12),
                        textField(name, 'Pet name', hint: 'e.g. Coco'),
                        const SizedBox(height: 12),
                        dropdown<String>(
                          label: 'Animal type',
                          value: type,
                          items: animalTypes,
                          onChanged: (value) =>
                              setDialogState(() => type = value!),
                        ),
                        const SizedBox(height: 12),
                        textField(breed, 'Breed',
                            hint: 'e.g. Holland Lop'),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: textField(
                                age,
                                'Age',
                                hint: 'e.g. 6',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  final n = int.tryParse(value?.trim() ?? '');
                                  if (n == null || n < 0) {
                                    return 'Enter a valid age';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: dropdown<String>(
                                label: 'Age unit',
                                value: ageUnit,
                                items: const ['Months', 'Years'],
                                onChanged: (value) =>
                                    setDialogState(() => ageUnit = value!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        dropdown<String>(
                          label: 'Gender',
                          value: gender,
                          items: genders,
                          onChanged: (value) =>
                              setDialogState(() => gender = value!),
                        ),
                        const SizedBox(height: 20),
                        sectionTitle('2', 'Health information',
                            'Share the pet’s current health details'),
                        dropdown<String>(
                          label: 'Health status',
                          value: health,
                          items: healthStatuses,
                          onChanged: (value) =>
                              setDialogState(() => health = value!),
                        ),
                        const SizedBox(height: 4),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Vaccinated'),
                          subtitle: const Text('Has received vaccinations'),
                          value: vaccinated,
                          onChanged: saving
                              ? null
                              : (value) =>
                                  setDialogState(() => vaccinated = value),
                        ),
                        dropdown<String>(
                          label: 'Sterilized (neutered / spayed)',
                          value: sterilized,
                          items: sterilizationOptions,
                          onChanged: (value) =>
                              setDialogState(() => sterilized = value!),
                        ),
                        const SizedBox(height: 20),
                        sectionTitle('3', 'Adoption details',
                            'Set the adoption fee and listing information'),
                        textField(
                          fee,
                          'Adoption fee (₹)',
                          hint: 'Enter 0 for free adoption',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            final n = double.tryParse(value?.trim() ?? '');
                            if (n == null || n < 0) {
                              return 'Enter a valid fee (0 or more)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        textField(
                          location,
                          'Location',
                          hint: 'e.g. Delhi, India',
                        ),
                        const SizedBox(height: 12),
                        textField(
                          description,
                          'Description',
                          hint:
                              'Describe the pet’s personality, habits and special care needs...',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tip: Enter accurate health and vaccination details. Do not mark a pet vaccinated unless the records are confirmed.',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => saving = true);
                          try {
                            if (selectedImage != null) {
                              imageUrl =
                                  await uploadPetImage(selectedImage!);
                              if (imageUrl == null) {
                                throw Exception(
                                    'Cloudinary did not return an image URL');
                              }
                            }

                            final ageValue = int.parse(age.text.trim());
                            final adoptionFee =
                                double.parse(fee.text.trim());

                            final data = <String, dynamic>{
                              'name': name.text.trim(),
                              'type': type,
                              'breed': breed.text.trim(),
                              'age': ageValue,
                              'ageUnit': ageUnit,
                              'description': description.text.trim(),
                              'price': adoptionFee, // Keeps older screens compatible.
                              'adoptionFee': adoptionFee,
                              'currency': 'INR',
                              'gender': gender,
                              'healthStatus': health,
                              'isVaccinated': vaccinated,
                              'sterilized': sterilized,
                              'location': location.text.trim(),
                              'adoptionStatus': 'Available',
                              'updatedAt': FieldValue.serverTimestamp(),
                              if (imageUrl != null) 'imageUrl': imageUrl,
                              if (petId == null)
                                'createdAt': FieldValue.serverTimestamp(),
                            };

                            if (petId == null) {
                              await pets.add(data);
                            } else {
                              await pets.doc(petId).update(data);
                            }

                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Pet saved successfully')),
                              );
                            }
                          } catch (e) {
                            if (!dialogContext.mounted) return;
                            setDialogState(() => saving = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('Save failed: $e')),
                            );
                          }
                        },
                  icon: saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Saving...' : 'Save Pet'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      name.dispose();
      breed.dispose();
      age.dispose();
      description.dispose();
      fee.dispose();
      location.dispose();
    }
  }

  Future<void> deletePet(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Pet?'),
        content: const Text('Are you sure you want to delete this pet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await pets.doc(id).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet deleted')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Pets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showPetForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Pet'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: pets.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final documents = snapshot.data!.docs;
          if (documents.isEmpty) {
            return const Center(
                child: Text('No pets available. Add your first pet!'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final data = doc.data();
              final imageUrl = data['imageUrl']?.toString() ?? '';
              final fee = data['adoptionFee'] ?? data['price'] ?? 0;

              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty ? const Icon(Icons.pets) : null,
                  ),
                  title: Text(
                    data['name']?.toString() ?? 'Unnamed',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${data['type'] ?? ''} • ${data['age'] ?? ''} '
                    '${data['ageUnit'] ?? ''}\nAdoption fee: ₹$fee',
                  ),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 0,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => showPetForm(
                          context,
                          petId: doc.id,
                          pet: data,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () => deletePet(context, doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
