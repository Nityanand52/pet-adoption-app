import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';


import 'models/animal_report.dart';
import 'report/report_animal_page.dart';
import 'report/my_reports_page.dart';

import 'models/adoption_application.dart';
import 'adoption/my_adoption_page.dart';
import 'adoption/adoption_form_page.dart';
import 'package:flutter/material.dart';

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
  late UserProfile currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = UserProfile(
      name: '',
      email: '',
      phone: '',
    );
  }

  Future<void> _login(String email, String password, String name) async {
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

      setState(() {
        isLoggedIn = true;

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
          content: Text('Could not load user profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _logout() {
    setState(() {
      isLoggedIn = false;
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: isLoggedIn
          ? HomePage(
              user: currentUser,
              onLogout: _logout,
            )
          : LoginPage(onLogin: _login),
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
                        onReportSubmitted: (report) {
                          setState(() {
                            animalReports.add(report);
                          });
                        },
                      ),
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
                      builder: (context) => MyAdoptionPage(
                        applications: adoptionApplications,
                      ),
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