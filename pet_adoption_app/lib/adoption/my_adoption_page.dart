import 'package:flutter/material.dart';
import '../models/adoption_application.dart';

class MyAdoptionPage extends StatelessWidget {
  final List<AdoptionApplication> applications;

  const MyAdoptionPage({
    super.key,
    required this.applications,
  });

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
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                ],
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