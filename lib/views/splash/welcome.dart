import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/navbar.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Image Section
            Container(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    "https://lh3.googleusercontent.com/aida-public/AB6AXuDMFbB5yR0KJA00XSG6IPJxtpyP4w09eJ_3F8b_7DzgqsT94K7zp8R6KaQ-ceTTc7bLFMU5qF5hpZV17xZgZ7zLjSuQ_9LqjVuC_mPj8b5rnkt8rKSabON9LY32dJzFX_Ze9l_GsuTB3uvkCEhFak626Ttz3ad9ZCwi8Ufism4hFq_5s06kt_6r194BiZmrUepoRAMQW2Ei2UyKRoANbfV3rTH5KEJLfH7VAULKCdYR9v9f1ezGp9Yh9OfdjipPxh5YpgLKxSRYBK13",
                  ),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),

            // Text Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          "Your Adventure Awaits",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(fontSize: 32, fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          "Discover new trails, record your hikes, and relive your favorite outdoor moments.",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.4),
                        ),
                      ],
                    ),

                    // Explore Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Save the state that the welcome screen has been viewed
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('has_seen_welcome', true);

                          if (!context.mounted) return;

                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const MainNavbar(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                // Slide transition from right to left (like opening a new app)
                                const slideBegin = Offset(0.15, 0.0);
                                const slideEnd = Offset.zero;
                                const slideCurve = Curves.easeOutCubic;

                                var slideTween = Tween(begin: slideBegin, end: slideEnd).chain(CurveTween(curve: slideCurve));
                                var slideAnimation = animation.drive(slideTween);

                                // Smooth fade transition
                                const fadeBegin = 0.0;
                                const fadeEnd = 1.0;
                                const fadeCurve = Curves.easeInOutCubic;

                                var fadeTween = Tween(begin: fadeBegin, end: fadeEnd).chain(CurveTween(curve: fadeCurve));
                                var fadeAnimation = animation.drive(fadeTween);

                                // Slight scale transition for depth effect
                                const scaleBegin = 0.94;
                                const scaleEnd = 1.0;

                                var scaleTween = Tween(begin: scaleBegin, end: scaleEnd).chain(CurveTween(curve: fadeCurve));
                                var scaleAnimation = animation.drive(scaleTween);

                                return SlideTransition(
                                  position: slideAnimation,
                                  child: FadeTransition(
                                    opacity: fadeAnimation,
                                    child: ScaleTransition(
                                      scale: scaleAnimation,
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 800),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        ),
                        child: Text(
                          'Explore',
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
