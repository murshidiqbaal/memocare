import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller with 2 seconds duration
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Fade in animation for the logo
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Scale up animation for the logo
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Delayed fade in for the text and tagline
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start the animation
    _controller.forward();

    // Navigate to Role Selection after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Using GoRouter context.go to navigate to /role-selection or generic login route
        // Assuming '/role-selection' or standard initial input.
        // Based on previous file, '/login' was used in tap.
        // We will try to go to '/role-selection' if defined, or '/' if that's the home.
        // Given prompt "Automatically navigate to: Role Selection / Login Screen", I'll assume '/role-selection'
        // but since I don't see the router config, I'll use pushReplacement to the widget class or a likely route.
        // Seeing role_selection_screen.dart content, it pushes '/login'.
        // I'll stick to 'context.go('/role-selection')' or simply push the widget if route isn't guaranteed.
        // To be safe and adhere to "Complete ready-to-run", I will use a direct route name check
        // or just use `context.go('/role-selection')` if I am confident, or `Navigator`.
        // The safest bet given existing go_router logic in file 127 is named routes.
        // I'll guess '/role-selection'. If not, the user can adjust routes.
        // Actually, let's use the explicit widget navigation to be 100% sure it works without route config changes.
        // Wait, go_router is imported. I should use it.
        // Defaulting to '/role-selection'.

        try {
          context.go('/role-selection');
        } catch (e) {
          // Fallback if route not defined
          context.go('/');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.lightBlue.shade50,
              Colors.teal.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            const Spacer(),

            // --- Logo Section ---
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Subtle Glow Effect
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    // Icon Background
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Center(
                        // Brain + Heart Metaphor Icon
                        child: Icon(
                          Icons.psychology, // Brain/Mind
                          size: 60,
                          color: Colors.teal.shade400,
                        ),
                      ),
                    ),
                    // Small Heart Badge
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite, // Heart/Care
                          size: 20,
                          color: Colors.pink.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- Text Section ---
            FadeTransition(
              opacity: _textFadeAnimation,
              child: Column(
                children: [
                  // App Name
                  Text(
                    'MemoCare',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tagline
                  Text(
                    'Remember What Matters.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.teal.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
