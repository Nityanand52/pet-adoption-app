import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/adoption_application.dart';
import '../main.dart';

class MyAdoptionPage extends StatefulWidget {
  const MyAdoptionPage({
    super.key,
  });

  @override
  State<MyAdoptionPage> createState() => _MyAdoptionPageState();
}

class _MyAdoptionPageState extends State<MyAdoptionPage> {
  List<AdoptionApplication> applications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadApplications();
  }

  Future<void> loadApplications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('adoptionApplications')
          .where('userId', isEqualTo: user.uid)
          .get();

      final loadedApplications = snapshot.docs.map((doc) {
        final data = doc.data();

        return AdoptionApplication(
          id: doc.id,
          pet: Pet(
            id: data['petId'] ?? '',
            name: data['petName'] ?? '',
            type: data['petType'] ?? 'Unknown',
            age: data['petAge'] ?? '',
            description: data['petDescription'] ?? '',
            icon: data['petType'] == 'Dog'
                ? Icons.pets
                : Icons.cruelty_free,
            price: (data['petPrice'] as num?)?.toDouble() ?? 0.0,
            gender: data['petGender'] ?? '',
            isVaccinated: data['petVaccinated'] ?? false,
            healthStatus: data['petHealthStatus'] ?? '',
          ),
          applicantName: data['applicantName'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          address: data['address'] ?? '',
          reason: data['reason'] ?? '',
          experience: data['experience'] ?? '',
          status: data['status'] ?? 'Pending',
        );
      }).toList();

      setState(() {
        applications = loadedApplications;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading applications: $e');

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Adoption Applications'),
        centerTitle: true,
      ),
      body: applications.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 15),
            Text(
              'No adoption applications yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: applications.length,
        itemBuilder: (context, index) {
          final application = applications[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Icon(
                              application.pet.icon,
                              size: 70,
                              color: Colors.teal,
                            ),
                          ),

                          const SizedBox(height: 15),

                          Center(
                            child: Text(
                              application.pet.name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 5),

                          Center(
                            child: Text(
                              '${application.pet.type} • ${application.pet.age}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          const Text(
                            'Adoption Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              _statusBadge(application.status),
                            ],
                          ),

                          const SizedBox(height: 15),

                          Text(
                            _statusMessage(application.status),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'About the Pet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            application.pet.description,
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 25),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Close'),
                            ),
                          ),

                          const SizedBox(height: 10),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.teal.shade100,
                          child: Icon(
                            application.pet.icon,
                            size: 30,
                            color: Colors.teal,
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                application.pet.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${application.pet.type} • ${application.pet.age}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        _statusBadge(application.status),
                      ],
                    ),

                    const SizedBox(height: 15),

                    const Divider(),

                    const SizedBox(height: 10),

                    const Text(
                      'Application Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _statusMessage(application.status),
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 15,
                          color: Colors.teal,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    IconData icon;

    if (status == 'Accepted') {
      icon = Icons.check_circle;
    } else if (status == 'Rejected') {
      icon = Icons.cancel;
    } else {
      icon = Icons.hourglass_top;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          status,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _statusMessage(String status) {
    if (status == 'Accepted') {
      return 'Congratulations! Your adoption application has been approved.';
    }

    if (status == 'Rejected') {
      return 'Unfortunately, your adoption application was not approved.';
    }

    return 'Your application is waiting for review.';
  }
}