import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class AdoptionRequestsPage extends StatefulWidget {

  const AdoptionRequestsPage({super.key});
  @override
  State<AdoptionRequestsPage> createState() =>

      _AdoptionRequestsPageState();
}
class _AdoptionRequestsPageState
    extends State<AdoptionRequestsPage> {
  String selectedFilter = 'All';
  String searchQuery = '';
  final Color primaryColor = const Color(0xFF087F73);
  final Color backgroundColor = const Color(0xFFF4F8F6);

  Future<void> updateStatus(String id, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('adoptionApplications')
          .doc(id)
          .update({'status': status});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application $status successfully'),
          backgroundColor:

              status == 'Approved' ? Colors.green : Colors.red,

          behavior: SnackBarBehavior.floating,

        ),

      );

    } catch (e) {

      if (!mounted) return;



      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text('Could not update application: $e'),

          backgroundColor: Colors.red,

          behavior: SnackBarBehavior.floating,

        ),

      );

    }

  }



  Future<void> confirmAction(

      String id, String status, String petName) async {

    final confirmed = await showDialog<bool>(

      context: context,

      builder: (dialogContext) => AlertDialog(

        shape: RoundedRectangleBorder(

          borderRadius: BorderRadius.circular(20),

        ),

        title: Text('$status application?'),

        content: Text(

          'Are you sure you want to $status the application for $petName?',

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(dialogContext, false),

            child: const Text('Cancel'),

          ),

          ElevatedButton(

            style: ElevatedButton.styleFrom(

              backgroundColor:

                  status == 'Approved' ? Colors.green : Colors.red,

              foregroundColor: Colors.white,

            ),

            onPressed: () => Navigator.pop(dialogContext, true),

            child: Text(status),

          ),

        ],

      ),

    );



    if (confirmed == true) {

      await updateStatus(id, status);

    }

  }



  Color statusColor(String status) {

    switch (status) {

      case 'Approved':

        return Colors.green;

      case 'Rejected':

        return Colors.red;

      default:

        return Colors.orange;

    }

  }



  IconData statusIcon(String status) {

    switch (status) {

      case 'Approved':

        return Icons.check_circle;

      case 'Rejected':

        return Icons.cancel;

      default:

        return Icons.hourglass_top;

    }

  }



  Widget buildStatCard(

      String title, int count, IconData icon, Color color) {

    return Expanded(

      child: Container(

        padding: const EdgeInsets.symmetric(

          horizontal: 10,

          vertical: 16,

        ),

        decoration: BoxDecoration(

          color: Colors.white,

          borderRadius: BorderRadius.circular(18),

          boxShadow: [

            BoxShadow(

              color: Colors.black.withOpacity(0.04),

              blurRadius: 10,

              offset: const Offset(0, 4),

            ),

          ],

        ),

        child: Column(

          children: [

            CircleAvatar(

              radius: 20,

              backgroundColor: color.withOpacity(0.12),

              child: Icon(icon, color: color, size: 21),

            ),

            const SizedBox(height: 10),

            Text(

              '$count',

              style: const TextStyle(

                fontSize: 23,

                fontWeight: FontWeight.bold,

              ),

            ),

            const SizedBox(height: 3),

            Text(

              title,

              textAlign: TextAlign.center,

              style: const TextStyle(

                fontSize: 11,

                color: Colors.black54,

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget buildDetail(

      IconData icon, String title, String value) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 13),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Icon(icon, size: 18, color: Colors.black45),

          const SizedBox(width: 10),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  title,

                  style: const TextStyle(

                    fontSize: 12,

                    color: Colors.black45,

                  ),

                ),

                const SizedBox(height: 2),

                Text(

                  value.isEmpty ? 'Not provided' : value,

                  style: const TextStyle(

                    fontSize: 14,

                    fontWeight: FontWeight.w500,

                  ),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }



  Widget buildApplicationCard(

      QueryDocumentSnapshot<Map<String, dynamic>> doc) {

    final data = doc.data();



    final petName = (data['petName'] ?? '').toString();

    final applicantName =

        (data['applicantName'] ?? '').toString();

    final email = (data['email'] ?? '').toString();

    final phone = (data['phone'] ?? '').toString();

    final address = (data['address'] ?? '').toString();

    final reason = (data['reason'] ?? '').toString();

    final experience = (data['experience'] ?? '').toString();

    final status = (data['status'] ?? 'Pending').toString();



    final color = statusColor(status);



    return Container(

      margin: const EdgeInsets.only(bottom: 18),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: Colors.grey.shade100),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.045),

            blurRadius: 14,

            offset: const Offset(0, 5),

          ),

        ],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // PET HEADER

          Container(

            padding: const EdgeInsets.all(17),

            decoration: BoxDecoration(

              color: primaryColor.withOpacity(0.07),

              borderRadius: const BorderRadius.vertical(

                top: Radius.circular(22),

              ),

            ),

            child: Row(

              children: [

                Container(

                  height: 48,

                  width: 48,

                  decoration: BoxDecoration(

                    color: primaryColor.withOpacity(0.13),

                    borderRadius: BorderRadius.circular(14),

                  ),

                  child: Icon(

                    Icons.pets,

                    color: primaryColor,

                    size: 27,

                  ),

                ),

                const SizedBox(width: 13),

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      const Text(

                        'ADOPTION REQUEST',

                        style: TextStyle(

                          fontSize: 10,

                          letterSpacing: 1.2,

                          color: Colors.black45,

                          fontWeight: FontWeight.bold,

                        ),

                      ),

                      const SizedBox(height: 4),

                      Text(

                        petName.isEmpty ? 'Pet not specified' : petName,

                        style: const TextStyle(

                          fontSize: 19,

                          fontWeight: FontWeight.bold,

                        ),

                      ),

                    ],

                  ),

                ),

                Container(

                  padding: const EdgeInsets.symmetric(

                    horizontal: 11,

                    vertical: 7,

                  ),

                  decoration: BoxDecoration(

                    color: color.withOpacity(0.12),

                    borderRadius: BorderRadius.circular(20),

                  ),

                  child: Row(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      Icon(statusIcon(status), size: 13, color: color),

                      const SizedBox(width: 5),

                      Text(

                        status,

                        style: TextStyle(

                          color: color,

                          fontSize: 11,

                          fontWeight: FontWeight.bold,

                        ),

                      ),

                    ],

                  ),

                ),

              ],

            ),

          ),



          // APPLICANT DETAILS

          Padding(

            padding: const EdgeInsets.all(18),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                const Text(

                  'APPLICANT DETAILS',

                  style: TextStyle(

                    fontSize: 11,

                    letterSpacing: 1,

                    color: Colors.black45,

                    fontWeight: FontWeight.bold,

                  ),

                ),

                const SizedBox(height: 15),



                buildDetail(

                  Icons.person_outline,

                  'Applicant name',

                  applicantName,

                ),

                buildDetail(

                  Icons.email_outlined,

                  'Email address',

                  email,

                ),

                buildDetail(

                  Icons.phone_outlined,

                  'Phone number',

                  phone,

                ),

                buildDetail(

                  Icons.location_on_outlined,

                  'Address',

                  address,

                ),



                const Divider(height: 25),



                const Text(

                  'ADOPTION INFORMATION',

                  style: TextStyle(

                    fontSize: 11,

                    letterSpacing: 1,

                    color: Colors.black45,

                    fontWeight: FontWeight.bold,

                  ),

                ),

                const SizedBox(height: 14),



                buildDetail(

                  Icons.favorite_outline,

                  'Why do you want to adopt?',

                  reason,

                ),

                buildDetail(

                  Icons.home_outlined,

                  'Previous pet experience',

                  experience,

                ),



                if (status == 'Pending') ...[

                  const SizedBox(height: 8),

                  Row(

                    children: [

                      Expanded(

                        child: OutlinedButton.icon(

                          onPressed: () => confirmAction(

                            doc.id,

                            'Rejected',

                            petName,

                          ),

                          icon: const Icon(Icons.close, size: 18),

                          label: const Text('Reject'),

                          style: OutlinedButton.styleFrom(

                            foregroundColor: Colors.red,

                            side: const BorderSide(color: Colors.red),

                            padding: const EdgeInsets.symmetric(

                              vertical: 13,

                            ),

                            shape: RoundedRectangleBorder(

                              borderRadius: BorderRadius.circular(12),

                            ),

                          ),

                        ),

                      ),

                      const SizedBox(width: 12),

                      Expanded(

                        child: ElevatedButton.icon(

                          onPressed: () => confirmAction(

                            doc.id,

                            'Approved',

                            petName,

                          ),

                          icon: const Icon(Icons.check, size: 18),

                          label: const Text('Approve'),

                          style: ElevatedButton.styleFrom(

                            backgroundColor: primaryColor,

                            foregroundColor: Colors.white,

                            elevation: 0,

                            padding: const EdgeInsets.symmetric(

                              vertical: 13,

                            ),

                            shape: RoundedRectangleBorder(

                              borderRadius: BorderRadius.circular(12),

                            ),

                          ),

                        ),

                      ),

                    ],

                  ),

                ],

              ],

            ),

          ),

        ],

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: backgroundColor,

      appBar: AppBar(

        backgroundColor: backgroundColor,

        elevation: 0,

        title: const Text(

          'Adoption Applications',

          style: TextStyle(fontWeight: FontWeight.bold),

        ),

      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(

        stream: FirebaseFirestore.instance

            .collection('adoptionApplications')

            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.hasError) {

            return Center(

              child: Text('Something went wrong: ${snapshot.error}'),

            );

          }



          if (!snapshot.hasData) {

            return const Center(

              child: CircularProgressIndicator(),

            );

          }



          final applications = snapshot.data!.docs;



          final pendingCount = applications

              .where((doc) => doc.data()['status'] == 'Pending')

              .length;

          final approvedCount = applications

              .where((doc) => doc.data()['status'] == 'Approved')

              .length;

          final rejectedCount = applications

              .where((doc) => doc.data()['status'] == 'Rejected')

              .length;



          final filteredApplications = applications.where((doc) {

            final data = doc.data();

            final status = data['status'] ?? 'Pending';



            final matchesFilter = selectedFilter == 'All' ||

                status == selectedFilter;



            final query = searchQuery.toLowerCase();

            final matchesSearch =

                (data['petName'] ?? '')

                        .toString()

                        .toLowerCase()

                        .contains(query) ||

                    (data['applicantName'] ?? '')

                        .toString()

                        .toLowerCase()

                        .contains(query) ||

                    (data['email'] ?? '')

                        .toString()

                        .toLowerCase()

                        .contains(query);



            return matchesFilter && matchesSearch;

          }).toList();



          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

              // DASHBOARD HEADER

              Container(

                width: double.infinity,

                margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),

                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(

                  gradient: LinearGradient(

                    colors: [

                      primaryColor,

                      const Color(0xFF07564F),

                    ],

                    begin: Alignment.topLeft,

                    end: Alignment.bottomRight,

                  ),

                  borderRadius: BorderRadius.circular(22),

                ),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(

                      'Application Overview',

                      style: TextStyle(

                        color: Colors.white,

                        fontSize: 20,

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                    const SizedBox(height: 5),

                    Text(

                      '${applications.length} total adoption applications',

                      style: const TextStyle(

                        color: Colors.white70,

                        fontSize: 13,

                      ),

                    ),

                    const SizedBox(height: 20),

                    Row(

                      children: [

                        buildStatCard(

                          'Pending',

                          pendingCount,

                          Icons.schedule,

                          Colors.orange,

                        ),

                        const SizedBox(width: 10),

                        buildStatCard(

                          'Approved',

                          approvedCount,

                          Icons.check_circle_outline,

                          Colors.green,

                        ),

                        const SizedBox(width: 10),

                        buildStatCard(

                          'Rejected',

                          rejectedCount,

                          Icons.cancel_outlined,

                          Colors.red,

                        ),

                      ],

                    ),

                  ],

                ),

              ),



              // SEARCH

              Padding(

                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: TextField(

                  onChanged: (value) {

                    setState(() => searchQuery = value);

                  },

                  decoration: InputDecoration(

                    hintText: 'Search pet or applicant...',

                    prefixIcon: const Icon(Icons.search),

                    filled: true,

                    fillColor: Colors.white,

                    contentPadding: const EdgeInsets.symmetric(

                      vertical: 14,

                    ),

                    border: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(15),

                      borderSide: BorderSide.none,

                    ),

                  ),

                ),

              ),



              const SizedBox(height: 16),



              // FILTER CHIPS

              SizedBox(

                height: 42,

                child: ListView(

                  scrollDirection: Axis.horizontal,

                  padding: const EdgeInsets.symmetric(horizontal: 16),

                  children: ['All', 'Pending', 'Approved', 'Rejected']

                      .map((filter) {

                    final selected = selectedFilter == filter;



                    return Padding(

                      padding: const EdgeInsets.only(right: 9),

                      child: ChoiceChip(

                        label: Text(filter),

                        selected: selected,

                        onSelected: (_) {

                          setState(() => selectedFilter = filter);

                        },

                        selectedColor: primaryColor,

                        backgroundColor: Colors.white,

                        labelStyle: TextStyle(

                          color: selected ? Colors.white : Colors.black87,

                          fontWeight: FontWeight.w600,

                        ),

                        side: BorderSide.none,

                        showCheckmark: false,

                      ),

                    );

                  }).toList(),

                ),

              ),



              const SizedBox(height: 15),



              // APPLICATION LIST
              if (filteredApplications.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 45,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 65,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No applications found',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Try changing your search or filter.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                ...filteredApplications.map(
                  (application) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    child: buildApplicationCard(application),
                  ),
                ),
              ],
            ),
          );

        },

      ),

    );

  }

}
