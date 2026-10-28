
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
    final name = TextEditingController(
      text: pet?['name']?.toString() ?? '',
    );
    final type = TextEditingController(
      text: pet?['type']?.toString() ?? '',
    );
    final age = TextEditingController(
      text: pet?['age']?.toString() ?? '',
    );
    final description = TextEditingController(
      text: pet?['description']?.toString() ?? '',
    );
    final price = TextEditingController(
      text: pet?['price']?.toString() ?? '',
    );
    final gender = TextEditingController(
      text: pet?['gender']?.toString() ?? '',
    );
    final health = TextEditingController(
      text: pet?['healthStatus']?.toString() ?? '',
    );

    bool vaccinated = pet?['isVaccinated'] == true;
    bool saving = false;
    XFile? selectedImage;
    String? imageUrl = pet?['imageUrl']?.toString();
    final formKey = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
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
                  setDialogState(() {
                    selectedImage = picked;
                  });
                }
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Image selection failed: $e')),
                );
              }
            }

            Widget field(
              TextEditingController controller,
              String label, {
              bool numeric = false,
              bool multiline = false,
            }) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: controller,
                  keyboardType: numeric
                      ? TextInputType.number
                      : multiline
                          ? TextInputType.multiline
                          : TextInputType.text,
                  maxLines: multiline ? 3 : 1,
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter $label';
                    }

                    if (numeric) {
                      final number = double.tryParse(value.trim());
                      if (number == null || number < 0) {
                        return 'Enter a valid price';
                      }
                    }

                    return null;
                  },
                ),
              );
            }

            return AlertDialog(
              title: Text(petId == null ? 'Add Pet' : 'Edit Pet'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedImage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FutureBuilder<List<int>>(
                              future: selectedImage!.readAsBytes(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const SizedBox(
                                    height: 120,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                return Image.memory(
                                  // XFile returns Uint8List.
                                   Uint8List.fromList(snapshot.data!),
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          )
                        else if (imageUrl != null &&
                            imageUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Image.network(
                              imageUrl!,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 60),
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Icon(Icons.pets, size: 70),
                          ),
                        OutlinedButton.icon(
                          onPressed: saving ? null : chooseImage,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: Text(
                            imageUrl != null || selectedImage != null
                                ? 'Change Pet Image'
                                : 'Choose Pet Image',
                          ),
                        ),
                        const SizedBox(height: 16),
                        field(name, 'Pet Name'),
                        field(type, 'Type (Dog/Cat)'),
                        field(age, 'Age (e.g. 2 years)'),
                        field(
                          description,
                          'Description',
                          multiline: true,
                        ),
                        field(price, 'Price', numeric: true),
                        field(gender, 'Gender'),
                        field(health, 'Health Status'),
                        SwitchListTile(
                          title: const Text('Vaccinated'),
                          value: vaccinated,
                          onChanged: saving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    vaccinated = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
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
                                  'Cloudinary did not return an image URL',
                                );
                              }
                            }

                            final data = <String, dynamic>{
                              'name': name.text.trim(),
                              'type': type.text.trim(),
                              'age': age.text.trim(),
                              'description': description.text.trim(),
                              'price':
                                  double.parse(price.text.trim()),
                              'gender': gender.text.trim(),
                              'healthStatus': health.text.trim(),
                              'isVaccinated': vaccinated,
                              if (imageUrl != null) 'imageUrl': imageUrl,
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
                                  content:
                                      Text('Pet saved successfully'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!dialogContext.mounted) return;

                            setDialogState(() => saving = false);
                            ScaffoldMessenger.of(dialogContext)
                                .showSnackBar(
                              SnackBar(
                                content: Text('Save failed: $e'),
                              ),
                            );
                          }
                        },
                  child: Text(saving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      name.dispose();
      type.dispose();
      age.dispose();
      description.dispose();
      price.dispose();
      gender.dispose();
      health.dispose();
    }
  }

  Future<void> deletePet(
    BuildContext context,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Pet?'),
        content: const Text(
          'Are you sure you want to delete this pet?',
        ),
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
      appBar: AppBar(
        title: const Text('Manage Pets'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showPetForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Pet'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: pets.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documents = snapshot.data!.docs;

          if (documents.isEmpty) {
            return const Center(
              child: Text('No pets available. Add your first pet!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final data = doc.data();

              final imageUrl = data['imageUrl']?.toString();

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: imageUrl != null &&
                            imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl)
                        : null,
                    child: imageUrl == null || imageUrl.isEmpty
                        ? const Icon(Icons.pets)
                        : null,
                  ),
                  title: Text(
                    data['name']?.toString() ?? 'Unnamed',
                  ),
                  subtitle: Text(
                    '${data['type'] ?? ''} • ${data['age'] ?? ''}\n'
                    'Price: ${data['price'] ?? 0}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit),
                        onPressed: () => showPetForm(
                          context,
                          petId: doc.id,
                          pet: data,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () =>
                            deletePet(context, doc.id),
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
