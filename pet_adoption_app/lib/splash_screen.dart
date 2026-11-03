
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.65,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF),
      body: Stack(
        children: [

          // Background decoration
          Positioned(
            top: -100,
            right: -90,
            child: Container(
              height: 280,
              width: 280,
              decoration: BoxDecoration(
                color: const Color(0xFFD7EEE8).withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: -110,
            left: -80,
            child: Container(
              height: 280,
              width: 280,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F1E8),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    const Spacer(),

                    // Animated pet illustration
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: SizedBox(
                        height: 250,
                        width: 250,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [

                            // Outer circle
                            Container(
                              height: 225,
                              width: 225,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCEFE9),
                                shape: BoxShape.circle,
                              ),
                            ),

                            // Main logo
                            Container(
                              height: 165,
                              width: 165,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(48),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00695C)
                                        .withOpacity(0.12),
                                    blurRadius: 25,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.pets_rounded,
                                size: 95,
                                color: Color(0xFF00897B),
                              ),
                            ),

                            // Floating heart
                            Positioned(
                              top: 5,
                              right: 15,
                              child: _decorationIcon(
                                Icons.favorite_rounded,
                                const Color(0xFFE98B83),
                                42,
                              ),
                            ),

                            // Floating paw
                            Positioned(
                              bottom: 12,
                              left: 5,
                              child: _decorationIcon(
                                Icons.pets_rounded,
                                const Color(0xFF80B9A8),
                                38,
                              ),
                            ),

                            // Small decorative circle
                            Positioned(
                              top: 35,
                              left: 15,
                              child: Container(
                                height: 15,
                                width: 15,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE9B878),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // App name and tagline
                    SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [

                          const Text(
                            'Pet Adoption',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00695C),
                              letterSpacing: 0.5,
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Every Paw Deserves a Home.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF777777),
                              letterSpacing: 0.4,
                            ),
                          ),

                          const SizedBox(height: 22),

                          Container(
                            height: 4,
                            width: 55,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9B878),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Bottom loading section
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [

                          const SizedBox(
                            height: 25,
                            width: 25,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF00897B),
                            ),
                          ),

                          const SizedBox(height: 14),

                          const Text(
                            'Finding homes, creating happiness',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                              letterSpacing: 0.4,
                            ),
                          ),

                          const SizedBox(height: 25),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorationIcon(
    IconData icon,
    Color color,
    double size,
  ) {
    return Container(
      height: 58,
      width: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }
}
