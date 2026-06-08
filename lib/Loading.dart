import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // LOADING ANIMATION CONTROLLER
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // ANIMATION VALUE 0 -> 1
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    // START ANIMATION
    _controller.forward();

    // NAVIGATE TO MENU SCREEN
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/menu');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // =========================
  // LOADING BAR WIDGET
  // =========================
  Widget buildLoadingBar() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.65,
      height: 8,

      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),

      child: Align(
        alignment: Alignment.centerLeft,

        child: Container(
          width: MediaQuery.of(context).size.width * 0.65 * _animation.value,

          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // =========================
  // MAIN UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B3C),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            // BUNNY IMAGE
            Image.asset(
              'assets/bunny.png',
              width: MediaQuery.of(context).size.width * 0.6,
              height: 200,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 40),

            // SEPARATE LOADING BAR FUNCTION
            buildLoadingBar(),
          ],
        ),
      ),
    );
  }
}
