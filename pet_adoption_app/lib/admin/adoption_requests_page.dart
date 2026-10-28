import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdoptionRequestsPage extends StatelessWidget {
  const AdoptionRequestsPage({super.key});

  Future<void> updateStatus(String id, String status) async {
    await FirebaseFirestore.instance
        .collection('adoptionApplications')
        .doc(id)
        .update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adoption Applications'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('adoptionApplications')
            .snapshots(),
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

          final applications = snapshot.data!.docs;

          if (applications.isEmpty) {
            return const Center(
              child: Text('No adoption applications found'),
            );
          }

          return ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final doc = applications[index];
              final data = doc.data();
              final status = data['status'] ?? 'Pending';

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pet: ${data['petName'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Applicant: ${data['applicantName'] ?? ''}'),
                      Text('Email: ${data['email'] ?? ''}'),
                      Text('Phone: ${data['phone'] ?? ''}'),
                      Text('Address: ${data['address'] ?? ''}'),
                      Text('Reason: ${data['reason'] ?? ''}'),
                      Text('Experience: ${data['experience'] ?? ''}'),
                      Text('Status: $status'),

                      if (status == 'Pending')
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  await updateStatus(doc.id, 'Approved');
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                              child: const Text('Approve'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  await updateStatus(doc.id, 'Rejected');
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                              child: const Text('Reject'),
                            ),
                          ],
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