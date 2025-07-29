import 'package:flutter/material.dart';
import 'home_page.dart';

// ToDo: Add Lottie animation or logo to splash screen for better visual engagement.
// ToDo: Use Navigator.pushReplacementNamed() with routes if your app will grow in screens.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Adds SingleTickerProviderStateMixin to support the animation controller, it lets your widget drive animations.
  late AnimationController _controller; // Controls timing.
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation controller with 1 seconds duration
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Scaling animation (from 0.8 to 1.2 size)
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // Fade-in effect from transparent to visible
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Start the animation
    _controller.forward();

    // After 3 seconds, go to home screen
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        //* mounted ensures widget still in memory (Widget Tree)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheImages(context);
    });
  }

  void _precacheImages(BuildContext context) {
    const imagePaths = [
      'assets/images/1.png',
      'assets/images/2.png',
      'assets/images/3.png',
      'assets/images/4.png',
    ];
    for (final path in imagePaths) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Always dispose the controller
    // Always clean up animations when the screen is removed to prevent memory leaks.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Soft background
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Image.asset('assets/images/splash-background3.png'),
              ),
            );
          },
        ),
      ),
    );
  }
}
