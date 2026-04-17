import 'package:flutter/material.dart';
import '../home_shell.dart'; // Ensure this path points to your HomeShell file

enum GifSize { small, medium, large, custom }

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isExiting = false;
  bool _showBranding = false;

  @override
  void initState() {
    super.initState();

    // Trigger branding animation shortly after launch
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showBranding = true);
    });

    _startExitTimer();
  }

  Future<void> _startExitTimer() async {
    // 1. Wait for the GIF to play out (Adjust this if your GIF is longer/shorter)
    await Future.delayed(const Duration(milliseconds: 2800));

    if (!mounted) return;

    // 2. Start fading out the GIF and Text
    setState(() {
      _isExiting = true;
      _showBranding = false;
    });

    // 3. Wait exactly 800ms for the fade-out animation to finish
    await Future.delayed(const Duration(milliseconds: 800));

    _navigateToNext();
  }

  void _navigateToNext() {
    if (!mounted) return;

    // Premium Cross-Fade to your main HomeShell
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1000),
        pageBuilder: (context, animation, secondaryAnimation) => const HomeShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          );
        },
      ),
    );
  }

  double _getGifSize(GifSize size) {
    final screenWidth = MediaQuery.of(context).size.width;
    switch (size) {
      case GifSize.small:
        return screenWidth * 0.4;
      case GifSize.large:
        return screenWidth * 0.8;
      case GifSize.medium:
        return screenWidth * 0.6;
      case GifSize.custom:
      default:
        return 350.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double currentSize = _getGifSize(GifSize.custom);

    return Scaffold(
      backgroundColor: Colors.black, // Matched to your app's deep background
      body: Stack(
        children: [
          // ── CENTER ANIMATED GIF ──
          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _isExiting ? 0.0 : 1.0,
              child: Image.asset(
                'assets/icon/splash.gif',
                width: currentSize,
                height: currentSize,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // ── BOTTOM ANIMATED BRANDING ──
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: _showBranding ? 1.0 : 0.0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    offset: _showBranding ? Offset.zero : const Offset(0, 0.5),
                    // Removed 'const' from Column and added it to the individual Text/SizedBox widgets
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'A',
                          style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2),
                        ),
                        const SizedBox(height: 6),
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF00A3FF), // Bright Blue from the top-left of the icon
                              Color(0xFF1854E3), // Deep Blue (Your original color)
                              Color(0xFFB100FF), // Rich Purple/Magenta from the bottom-right
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            'Ezze Softwares',
                            style: TextStyle(
                              // The color must be white for the gradient to paint over it properly
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'PRODUCT',
                          style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}