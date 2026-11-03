import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/animal_report.dart';
import 'report/report_animal_page.dart';
import 'report/my_reports_page.dart';
import 'models/adoption_application.dart';
import 'adoption/my_adoption_page.dart';
import 'adoption/adoption_form_page.dart';
import 'admin/adoption_requests_page.dart';
import 'admin/manage_pets_page.dart';
import 'report/rescue_map_page.dart';
import 'splash_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const PetAdoptionApp());
}

class PetAdoptionApp extends StatefulWidget {
  const PetAdoptionApp({super.key});

  @override
  State<PetAdoptionApp> createState() => _PetAdoptionAppState();
}

class _PetAdoptionAppState extends State<PetAdoptionApp> {
  bool isLoggedIn = false;
  bool isAdmin = false;
  bool showSplash = true;

  late UserProfile currentUser;

  @override
  void initState() {
    super.initState();

    currentUser = UserProfile(
      name: '',
      email: '',
      phone: '',
    );

    // Splash screen timer
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showSplash = false;
        });
      }
    });
  }

  Future<void> _login(
    String email,
    String password,
    String name,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      final userName = data?['name'] ?? name;
      final userEmail = data?['email'] ?? email;
      final role = data?['role'] ?? 'user';

      setState(() {
        isLoggedIn = true;
        isAdmin = role == 'admin';

        currentUser = UserProfile(
          name: userName,
          email: userEmail,
          phone: '+1 (555) 000-0000',
        );
      });
    } catch (e) {
      print('Error loading user profile: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load user profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    setState(() {
      isLoggedIn = false;
      isAdmin = false;

      currentUser = UserProfile(
        name: '',
        email: '',
        phone: '',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '🐾 Pet Adoption',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),
        useMaterial3: true,
      ),

      home: showSplash
    ? const SplashScreen()
    : !isLoggedIn
        ? LoginPage(
            onLogin: _login,
          )
        : isAdmin
            ? AdminDashboard(
                onLogout: _logout,
              )
            : HomePage(
                user: currentUser,
                onLogout: _logout,
              ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  final VoidCallback onLogout;

  const AdminDashboard({
    super.key,
    required this.onLogout,
  });

  Stream<int> getCount(String collection) {
    return FirebaseFirestore.instance
        .collection(collection)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getPendingApplications() {
    return FirebaseFirestore.instance
        .collection('adoptionApplications')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F8F6),
        elevation: 0,
        title: const Text(
          'Rescue Admin',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF173D35),
          ),
        ),
        actions: [
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // WELCOME BANNER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF126B59),
                    Color(0xFF23977B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -5,
                    bottom: -15,
                    child: Icon(
                      Icons.pets,
                      size: 125,
                      color: Colors.white.withOpacity(0.10),
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ADMIN CONTROL CENTER',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'Welcome back, Admin! 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Every action helps an animal find a safe home.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Making a difference every day',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // OVERVIEW
            const Text(
              'Dashboard Overview',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF193B33),
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'A quick look at your application',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 18),

            // STATISTICS GRID
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 13,
              mainAxisSpacing: 13,
              childAspectRatio: 1.45,
              children: [
                _AdminStatCard(
                  title: 'Animal Reports',
                  icon: Icons.crisis_alert_rounded,
                  color: const Color(0xFFE66B55),
                  stream: getCount('animalReports'),
                ),

                _AdminStatCard(
                  title: 'Adoption Requests',
                  icon: Icons.assignment_rounded,
                  color: const Color(0xFF5586D9),
                  stream: getCount('adoptionApplications'),
                ),

                _AdminStatCard(
                  title: 'Available Pets',
                  icon: Icons.pets_rounded,
                  color: const Color(0xFF23977B),
                  stream: getCount('pets'),
                ),

                _AdminStatCard(
                  title: 'Pending Requests',
                  icon: Icons.pending_actions_rounded,
                  color: const Color(0xFFE4A344),
                  stream: getPendingApplications(),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // QUICK ACTIONS
            const Text(
              'Manage Your Application',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF193B33),
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Choose an area to manage',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 18),

            _AdminActionCard(
              title: 'Animal Reports',
              subtitle: 'Review rescue requests and update their status',
              icon: Icons.crisis_alert_rounded,
              color: const Color(0xFFE66B55),
              background: const Color(0xFFFFEFEB),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminAnimalReportsPage(),
                  ),
                );
              },
            ),

            _AdminActionCard(
              title: 'Live Rescue Map',
              subtitle: 'Locate animals that need immediate help',
              icon: Icons.map_rounded,
              color: const Color(0xFF168E79),
              background: const Color(0xFFE5F5EF),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RescueMapPage(),
                  ),
                );
              },
            ),

            _AdminActionCard(
              title: 'Adoption Applications',
              subtitle: 'Review, approve or reject applications',
              icon: Icons.assignment_rounded,
              color: const Color(0xFF5586D9),
              background: const Color(0xFFEBF1FF),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdoptionRequestsPage(),
                  ),
                );
              },
            ),

            _AdminActionCard(
              title: 'Manage Pets',
              subtitle: 'Add new pets or update existing listings',
              icon: Icons.pets_rounded,
              color: const Color(0xFF9A70C7),
              background: const Color(0xFFF3ECFA),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManagePetsPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            // FOOTER
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.favorite,
                    color: Colors.teal.shade300,
                    size: 22,
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Together, we make happy endings possible.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Stream<int> stream;

  const _AdminStatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: color.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),
              Icon(
                Icons.trending_up_rounded,
                color: color.withOpacity(0.7),
                size: 19,
              ),
            ],
          ),
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snapshot) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    snapshot.hasError
                        ? '--'
                        : snapshot.hasData
                            ? '${snapshot.data}'
                            : '...',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF193B33),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}



class _AdminActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 53,
                  width: 53,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 27,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF193B33),
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 17,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class AdminAnimalReportsPage extends StatefulWidget {
  const AdminAnimalReportsPage({super.key});

  @override
  State<AdminAnimalReportsPage> createState() =>
      _AdminAnimalReportsPageState();
}

class _AdminAnimalReportsPageState
    extends State<AdminAnimalReportsPage> {
  bool isLoading = true;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> reports = [];

  String selectedFilter = 'All';
  final TextEditingController searchController = TextEditingController();

  final List<String> statusOptions = [
    'Pending',
    'In Progress',
    'Resolved',
  ];

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadReports() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('animalReports')
          .orderBy('date', descending: true)
          .get();

      if (!mounted) return;

      setState(() {
        reports = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load reports: $e')),
      );
    }
  }

  Future<void> updateReportStatus(
    String reportId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('animalReports')
          .doc(reportId)
          .update({
        'status': newStatus,
      });

      await loadReports();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report marked as $newStatus'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green;
      case 'In Progress':
        return Colors.orange.shade800;
      default:
        return Colors.red.shade700;
    }
  }

  Color getConditionColor(String condition) {
    final value = condition.toLowerCase();

    if (value.contains('injured') || value.contains('critical')) {
      return Colors.red;
    } else if (value.contains('sick') || value.contains('ill')) {
      return Colors.orange;
    }

    return Colors.teal;
  }

  String formatDate(dynamic date) {
    if (date == null) return 'Date unavailable';

    DateTime? parsedDate;

    if (date is Timestamp) {
      parsedDate = date.toDate();
    } else if (date is DateTime) {
      parsedDate = date;
    }

    if (parsedDate == null) return 'Date unavailable';

    return '${parsedDate.day.toString().padLeft(2, '0')}/'
        '${parsedDate.month.toString().padLeft(2, '0')}/'
        '${parsedDate.year}';
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      get filteredReports {
    return reports.where((doc) {
      final data = doc.data();

      final status = data['status'] ?? 'Pending';
      final animalType =
          (data['animalType'] ?? '').toString().toLowerCase();
      final location =
          (data['location'] ?? '').toString().toLowerCase();

      final query = searchController.text.toLowerCase();

      final matchesFilter =
          selectedFilter == 'All' || status == selectedFilter;

      final matchesSearch =
          animalType.contains(query) || location.contains(query);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  Widget buildStatCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatusBadge(String status) {
    final color = getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildInfoRow(
    IconData icon,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.teal.shade600,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildReportCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final report = document.data();

    final animalType = report['animalType'] ?? 'Unknown Animal';
    final condition = report['condition'] ?? 'Not specified';
    final location = report['location'] ?? 'Not specified';
    final description = report['description'] ?? 'No description';
    final imagePath = report['imagePath']?.toString() ?? '';

    final rawStatus = report['status'] ?? 'Pending';

    final status = statusOptions.contains(rawStatus)
        ? rawStatus
        : 'Pending';

    final conditionColor = getConditionColor(condition);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ANIMAL INFORMATION
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: imagePath.isNotEmpty
                      ? Image.network(
                          imagePath,
                          height: 65,
                          width: 65,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return animalPlaceholder();
                          },
                        )
                      : animalPlaceholder(),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animalType,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Reported on ${formatDate(report['date'])}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                buildStatusBadge(status),
              ],
            ),

            const SizedBox(height: 18),

            // CONDITION
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: conditionColor.withOpacity(0.09),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.health_and_safety_outlined,
                    size: 16,
                    color: conditionColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    condition,
                    style: TextStyle(
                      color: conditionColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            buildInfoRow(
              Icons.location_on_outlined,
              location,
            ),

            buildInfoRow(
              Icons.notes_outlined,
              description,
            ),

            const Divider(height: 22),

            // STATUS UPDATE
            const Text(
              'Manage Report',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: status,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.edit_note,
                  color: Colors.teal,
                ),
                filled: true,
                fillColor: Colors.teal.shade50.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: statusOptions.map((value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && value != status) {
                  updateReportStatus(document.id, value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget animalPlaceholder() {
    return Container(
      height: 65,
      width: 65,
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.pets,
        size: 32,
        color: Colors.teal.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = reports.where(
      (doc) => (doc.data()['status'] ?? 'Pending') == 'Pending',
    ).length;

    final progressCount = reports.where(
      (doc) => doc.data()['status'] == 'In Progress',
    ).length;

    final resolvedCount = reports.where(
      (doc) => doc.data()['status'] == 'Resolved',
    ).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F6),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F8F6),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Animal Reports',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loadReports,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh reports',
          ),
          const SizedBox(width: 5),
        ],
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            )
          : RefreshIndicator(
              onRefresh: loadReports,
              color: Colors.teal,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // PAGE INTRODUCTION
                  const Text(
                    'Rescue Center',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Manage Animal Reports',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Keep track of animals that need your help.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SUMMARY CARDS
                  Row(
                    children: [
                      buildStatCard(
                        'Total',
                        reports.length,
                        Icons.pets,
                        Colors.teal,
                      ),
                      const SizedBox(width: 9),
                      buildStatCard(
                        'Pending',
                        pendingCount,
                        Icons.access_time,
                        Colors.orange,
                      ),
                      const SizedBox(width: 9),
                      buildStatCard(
                        'Resolved',
                        resolvedCount,
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // SEARCH
                  TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Search animal or location...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.teal,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // FILTERS
                  const Text(
                    'Filter Reports',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All',
                        'Pending',
                        'In Progress',
                        'Resolved',
                      ].map((filter) {
                        final selected = selectedFilter == filter;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: selected,
                            selectedColor: Colors.teal,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            onSelected: (value) {
                              setState(() {
                                selectedFilter = filter;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // REPORT COUNT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Submitted Reports',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${filteredReports.length} found',
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // REPORT LIST
                  if (filteredReports.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.pets,
                            size: 45,
                            color: Colors.teal.shade200,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No reports found',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Try changing your search or filter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredReports.map(buildReportCard),
                ],
              ),
            ),
    );
  }
}


// ============== PET MODEL ==============

class Pet {
  final String id;
  final String name;
  final String type;
  final String age;
  final String description;
  final IconData icon;
  final double price;
  final String gender;
  final bool isVaccinated;
  final String healthStatus;

  DateTime adoptedDate = DateTime(2099, 1, 1);
  bool isFavorite;
  bool isAdopted;

  Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.age,
    required this.description,
    required this.icon,
    required this.price,
    required this.gender,
    required this.isVaccinated,
    required this.healthStatus,
    this.isFavorite = false,
    this.isAdopted = false,
  });
}

// ============== USER MODEL ==============

class UserProfile {
  String name;
  String email;
  String phone;
  List<Pet> adoptedPets;

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    this.adoptedPets = const [],
  });
}

// ============== LOGIN PAGE ==============

class LoginPage extends StatefulWidget {
  final Function(String email, String password, String name) onLogin;

  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool showPassword = false;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final user = credential.user;

      if (user != null) {
        widget.onLogin(
          user.email ?? emailController.text.trim(),
          passwordController.text,
          user.email?.split('@')[0] ?? 'User',
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email';
      } else if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Incorrect email or password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleSignup() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final user = credential.user;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        widget.onLogin(
          emailController.text.trim(),
          passwordController.text,
          nameController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Signup failed';

      if (e.code == 'email-already-in-use') {
        message = 'An account already exists with this email';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade400, Colors.teal.shade700],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO
                  const SizedBox(height: 40),
                  const Icon(Icons.pets, size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    '🐾 Pet Adoption',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isLogin
                        ? 'Find Your Perfect Companion'
                        : 'Join Our Pet Family',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // CARD CONTAINER
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          // TOGGLE BUTTONS
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => setState(() => isLogin = true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isLogin
                                        ? Colors.teal
                                        : Colors.grey.shade200,
                                    foregroundColor:
                                        isLogin ? Colors.white : Colors.teal,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => setState(() => isLogin = false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: !isLogin
                                        ? Colors.teal
                                        : Colors.grey.shade200,
                                    foregroundColor:
                                        !isLogin ? Colors.white : Colors.teal,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                  ),
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // NAME FIELD (SIGNUP ONLY)
                          if (!isLogin)
                            Column(
                              children: [
                                TextField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    hintText: 'Full Name',
                                    prefixIcon: const Icon(Icons.person),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                ),
                                const SizedBox(height: 15),
                              ],
                            ),

                          // EMAIL FIELD
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              hintText: 'Email Address',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 15),

                          // PASSWORD FIELD
                          TextField(
                            controller: passwordController,
                            obscureText: !showPassword,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                    () => showPassword = !showPassword),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),

                          const SizedBox(height: 15),

                          // CONFIRM PASSWORD FIELD (SIGNUP ONLY)
                          if (!isLogin)
                            Column(
                              children: [
                                TextField(
                                  controller: confirmPasswordController,
                                  obscureText: !showPassword,
                                  decoration: InputDecoration(
                                    hintText: 'Confirm Password',
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        showPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () => setState(
                                          () => showPassword = !showPassword),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                ),
                                const SizedBox(height: 15),
                              ],
                            ),

                          // LOGIN/SIGNUP BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : (isLogin ? _handleLogin : _handleSignup),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      isLogin ? 'Login' : 'Sign Up',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          if (isLogin) ...[
                            const SizedBox(height: 15),
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password reset link sent to email'),
                                    backgroundColor: Colors.teal,
                                  ),
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(color: Colors.teal),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // DEMO CREDENTIALS
                  if (isLogin)
                    Column(
                      children: [
                        const Text(
                          'Demo Account:',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            children: [
                              Text(
                                'Email: demo@example.com',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Password: demo123',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============== HOME PAGE ==============

class HomePage extends StatefulWidget {
  final UserProfile user;
  final VoidCallback onLogout;

  const HomePage({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int currentIndex = 0;
  final TextEditingController searchController = TextEditingController();

  late AnimationController animationController;
  late AnimationController fabAnimationController;

  String searchText = '';
  String selectedType = 'All';


  String sortBy = 'Name';

  late UserProfile userProfile;
  final List<AdoptionApplication> adoptionApplications = [];
  List<AnimalReport> animalReports = [];
  Future<void> loadAnimalReports() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('animalReports')
          .orderBy('date', descending: true)
          .get();

      final loadedReports = snapshot.docs.map((doc) {
        final data = doc.data();

        return AnimalReport(
          id: doc.id,
          animalType: data['animalType'] ?? '',
          location: data['location'] ?? '',
          condition: data['condition'] ?? '',
          description: data['description'] ?? '',
          imagePath: data['imagePath'],
          date: (data['date'] as Timestamp).toDate(),
          status: data['status'] ?? 'Pending',
        );
      }).toList();

      setState(() {
        animalReports = loadedReports;
      });

      print('Loaded ${animalReports.length} animal reports from Firestore');
    } catch (e) {
      print('Error loading animal reports: $e');
    }
  }
  Future<void> saveAnimalReport(AnimalReport report) async {
    try {
      await FirebaseFirestore.instance
          .collection('animalReports')
          .doc(report.id)
          .set({
        'animalType': report.animalType,
        'location': report.location,
        'condition': report.condition,
        'description': report.description,
        'imagePath': report.imagePath,
        'date': Timestamp.fromDate(report.date),
        'status': report.status,
      });

      setState(() {
        animalReports.add(report);
      });

      print('Animal report saved successfully');
    } catch (e) {
      print('Error saving animal report: $e');
      rethrow;
    }
  }
  List<Pet> pets = [];


  Future<void> loadPetsFromFirestore() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('pets').get();

      final loadedPets = snapshot.docs.map((doc) {
        final data = doc.data();

        return Pet(
          id: doc.id,
          name: data['name'] ?? '',
          type: data['type'] ?? '',
          age: data['age'] ?? '',
          description: data['description'] ?? '',
          icon: data['type'] == 'Dog'
              ? Icons.pets
              : Icons.cruelty_free,
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          gender: data['gender'] ?? '',
          isVaccinated: data['isVaccinated'] ?? false,
          healthStatus: data['healthStatus'] ?? '',
        );
      }).toList();

      setState(() {
        pets = loadedPets;
      });

      print('Loaded ${pets.length} pets from Firestore');
    } catch (e) {
      print('Error loading pets: $e');
    }
  }
  @override
  void initState() {
    super.initState();
    loadAnimalReports();

    animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    userProfile = widget.user;

    loadPetsFromFirestore();
  }

  @override
  void dispose() {
    animationController.dispose();
    fabAnimationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  List<Pet> _getFilteredAndSortedPets() {
    List<Pet> filtered = pets.where((pet) {
      final query = searchText.toLowerCase();
      final matchesSearch = pet.name.toLowerCase().contains(query) ||
          pet.type.toLowerCase().contains(query);
      final matchesType =
          selectedType == 'All' || pet.type == selectedType;

      return matchesSearch && matchesType && !pet.isAdopted;
    }).toList();

    // Sort
    if (sortBy == 'Price') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (sortBy == 'Age') {
      filtered.sort((a, b) => int.parse(a.age.split(' ')[0])
          .compareTo(int.parse(b.age.split(' ')[0])));
    } else {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🐾 Pet Adoption',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Hi, ${userProfile.name}!',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: currentIndex == 0
          ? _buildHome()
          : currentIndex == 1
              ? _buildFavorites()
              : _buildProfile(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ============== HOME PAGE BUILDER ==============

  Widget _buildHome() {
    final filteredPets = _getFilteredAndSortedPets();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            FadeTransition(
              opacity: animationController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find Your Perfect Companion 🐾',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Give a loving pet a forever home ❤️',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // SEARCH
            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() => searchText = value);
              },
              decoration: InputDecoration(
                hintText: 'Search by name or breed...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() => searchText = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // FILTER & SORT ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // FILTER BY TYPE
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'All',
                      'Dog',
                      'Cat',
                    ]
                        .map(
                          (type) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(type),
                              selected: selectedType == type,
                              onSelected: (selected) {
                                setState(() => selectedType = type);
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),

                // SORT DROPDOWN
                DropdownButton<String>(
                  value: sortBy,
                  items: ['Name', 'Price', 'Age']
                      .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      })
                      .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => sortBy = newValue);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // AVAILABLE PETS COUNT
            Text(
              'Available Pets (${filteredPets.length})',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            // EMPTY STATE
            if (filteredPets.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text(
                    'No pets found 🐾',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 20),

// REPORT AN ANIMAL
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.red.shade100,
                ),
              ),
              color: Colors.red.shade50,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportAnimalPage(
                        onReportSubmitted: saveAnimalReport,
                      )
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.report_problem_outlined,
                          color: Colors.red.shade700,
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Report an Animal',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Found an injured or abandoned animal?',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // PET LIST WITH ANIMATION
            ...filteredPets.asMap().entries.map((entry) {
              int idx = entry.key;
              Pet pet = entry.value;

              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animationController,
                    curve: Interval(
                      (idx * 0.1).clamp(0.0, 1.0),
                      ((idx + 1) * 0.1).clamp(0.0, 1.0),
                    ),
                  ),
                ),
                child: PetCard(
                  pet: pet,
                  onFavorite: () {
                    setState(() => pet.isFavorite = !pet.isFavorite);
                  },
                  onTap: () => _showPetDetails(pet),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ============== FAVORITES PAGE BUILDER ==============

  Widget _buildFavorites() {
    final favoritePets = pets.where((pet) => pet.isFavorite).toList();

    if (favoritePets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: fabAnimationController,
              child: Icon(
                Icons.favorite_border,
                size: 70,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'No favorite pets yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'Tap ❤️ on a pet to add it here.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: favoritePets
          .map(
            (pet) => PetCard(
              pet: pet,
              onFavorite: () {
                setState(() => pet.isFavorite = false);
              },
              onTap: () => _showPetDetails(pet),
            ),
          )
          .toList(),
    );
  }

  // ============== PROFILE PAGE BUILDER ==============

  Widget _buildProfile() {
    final adoptedCount =
        pets.where((pet) => pet.isAdopted).length;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // PROFILE HEADER
            ScaleTransition(
              scale: fabAnimationController,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.teal.shade100,
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.teal,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Text(
              userProfile.name,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            Text(
              userProfile.email,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            // STATS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Favorites',
                    pets.where((p) => p.isFavorite).length.toString(), Icons.favorite),
                _buildStatCard('Adopted',
                    adoptedCount.toString(), Icons.check_circle),
                _buildStatCard('Available',
                    pets.where((p) => !p.isAdopted).length.toString(), Icons.pets),
              ],
            ),

            const SizedBox(height: 30),

            // EDIT PROFILE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showEditProfileDialog(),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
              ),
            ),

            const SizedBox(height: 15),

            // MY ADOPTION APPLICATIONS BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyAdoptionPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.assignment),
                label: const Text('My Adoption Applications'),
              ),
            ),

            const SizedBox(height: 15),

            // CONTACT INFO
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: Text(userProfile.email),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {},
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('Phone'),
                      subtitle: Text(userProfile.phone),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ADOPTION HISTORY
            if (adoptedCount > 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Adopted Pets',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      ...pets
                          .where((pet) => pet.isAdopted)
                          .map(
                            (pet) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: Icon(pet.icon, color: Colors.teal),
                                title: Text(pet.name),
                                subtitle: Text(
                                    'Adopted on ${pet.adoptedDate.toString().split(' ')[0]}'),
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
              ),


            ListTile(
              leading: const Icon(
                Icons.assignment_outlined,
                color: Colors.teal,
              ),
              title: const Text('My Reports'),
              subtitle: const Text(
                'View your submitted animal reports',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyReportsPage(
                      reports: animalReports,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          children: [
            Icon(icon, color: Colors.teal, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ============== PET DETAILS MODAL ==============

  void _showPetDetails(Pet pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // PET ICON
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    pet.icon,
                    size: 55,
                    color: Colors.teal,
                  ),
                ),

                const SizedBox(height: 15),

                // PET NAME
                Text(
                  pet.name,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 5),

                Text(
                  '${pet.type} • ${pet.age}',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),

                const SizedBox(height: 15),

                // DESCRIPTION
                Text(
                  pet.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 20),

                // INFO CARDS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDetailChip('💰', '\$${pet.price.toStringAsFixed(0)}'),
                    _buildDetailChip('⚧', pet.gender),
                    _buildDetailChip(
                        pet.isVaccinated ? '✓' : '✗',
                        pet.isVaccinated ? 'Vaccinated' : 'Not Vax'),
                  ],
                ),

                const SizedBox(height: 15),

                // HEALTH STATUS
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pet.healthStatus == 'Excellent'
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        pet.healthStatus == 'Excellent'
                            ? Icons.check_circle
                            : Icons.info,
                        color: pet.healthStatus == 'Excellent'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Health Status: ${pet.healthStatus}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ADOPT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final application = await Navigator.push<AdoptionApplication>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdoptionFormPage(
                            pet: pet,
                            applicantName: userProfile.name,
                            applicantEmail: userProfile.email,
                          ),
                        ),
                      );

                      if (application != null) {
                        setState(() {
                          adoptionApplications.add(application);
                        });

                        try {
                          await FirebaseFirestore.instance
                              .collection('adoptionApplications')
                              .add({
                            'userId': FirebaseAuth.instance.currentUser!.uid,
                            'id': application.id,
                            'petId': application.pet.id,
                            'petName': application.pet.name,
                            'applicantName': application.applicantName,
                            'email': application.email,
                            'phone': application.phone,
                            'address': application.address,
                            'reason': application.reason,
                            'experience': application.experience,
                            'status': application.status,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          print('Adoption application saved to Firestore!');
                        } catch (e) {
                          print('Error saving adoption application: $e');
                        }
                      }
                    },
                    icon: const Icon(Icons.favorite),
                    label: const Text('Adopt Me'),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailChip(String icon, String label) {
    return Chip(
      label: Text('$icon $label'),
      backgroundColor: Colors.teal.shade50,
    );
  }

  void _adoptPet(Pet pet) {
    setState(() {
      pet.isAdopted = true;
      pet.adoptedDate = DateTime.now();
      userProfile.adoptedPets.add(pet);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎉 Congratulations! You adopted ${pet.name}!',
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: userProfile.name);
    final emailController = TextEditingController(text: userProfile.email);
    final phoneController = TextEditingController(text: userProfile.phone);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  userProfile.name = nameController.text;
                  userProfile.email = emailController.text;
                  userProfile.phone = phoneController.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully! ✓'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

// ============== PET CARD WIDGET ==============

class PetCard extends StatefulWidget {
  final Pet pet;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  const PetCard({
    super.key,
    required this.pet,
    required this.onFavorite,
    required this.onTap,
  });

  @override
  State<PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<PetCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        onHover: (isHovering) {
          if (isHovering) {
            _hoverController.forward();
          } else {
            _hoverController.reverse();
          }
        },
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.02)
              .animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut)),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                // PET ICON
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    widget.pet.icon,
                    size: 40,
                    color: Colors.teal,
                  ),
                ),

                const SizedBox(width: 15),

                // PET INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.pet.name,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.pet.isVaccinated)
                            Tooltip(
                              message: 'Vaccinated',
                              child: Icon(
                                Icons.shield_outlined,
                                size: 18,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        widget.pet.type,
                        style: const TextStyle(fontSize: 14),
                      ),

                      const SizedBox(height: 3),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.pet.age,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '\$${widget.pet.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // FAVORITE BUTTON
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: widget.pet.isFavorite
                          ? Tween<double>(begin: 1.0, end: 1.2)
                              .animate(AlwaysStoppedAnimation(1.0))
                          : AlwaysStoppedAnimation(1.0),
                      child: IconButton(
                        onPressed: widget.onFavorite,
                        icon: Icon(
                          widget.pet.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.pet.isFavorite
                              ? Colors.red
                              : Colors.grey,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}