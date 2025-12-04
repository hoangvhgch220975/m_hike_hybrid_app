import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/hike_viewmodel.dart';

class EmptyRemarkableView extends StatefulWidget {
  const EmptyRemarkableView({super.key});

  @override
  State<EmptyRemarkableView> createState() => _EmptyRemarkableViewState();
}

class _EmptyRemarkableViewState extends State<EmptyRemarkableView> {
  Future<void> _refreshData() async {
    final viewModel = Provider.of<HikeViewModel>(context, listen: false);
    await viewModel.loadRemarkable();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: theme.cardColor.withOpacity(0.9),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Image.asset('lib/assets/images/hike_logo.png', width: 32, height: 32, fit: BoxFit.contain),
        ),
        centerTitle: true,
        title: Text('Remarkable Hikes', style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
      ),

      body: RefreshIndicator(
        color: colorScheme.primary,
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 100,
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: 360,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // === Illustration ===
                        SizedBox(
                          width: 260,
                          child: CustomPaint(
                            size: const Size(200, 150),
                            painter: MountainIllustrationPainter(
                              outlineColor: theme.hintColor,
                              skyColor: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // === Title ===
                        Text(
                          "Your Most Memorable Adventures",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, color: theme.textTheme.titleMedium?.color),
                        ),
                        const SizedBox(height: 8),

                        // === Description ===
                        SizedBox(
                          width: 260,
                          child: Text(
                            "This is where hikes you mark as 'remarkable' will appear. Go back to your hike history to select your favorites.",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.4, color: theme.hintColor),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // === Button ===
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                            elevation: 4,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('View My Hikes', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onPrimary)),

                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Accepts theme colors so the illustration blends with dark/light modes
class MountainIllustrationPainter extends CustomPainter {
  final Color outlineColor;
  final Color skyColor;

  MountainIllustrationPainter({required this.outlineColor, required this.skyColor});

  @override
  void paint(Canvas canvas, Size size) {
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [skyColor.withOpacity(0.18), skyColor.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final mountainPath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.9)
      ..lineTo(size.width * 0.5, size.height * 0.35)
      ..lineTo(size.width * 0.6, size.height * 0.55)
      ..lineTo(size.width * 0.75, size.height * 0.9)
      ..close();

    canvas.drawPath(mountainPath, skyPaint);

    final outline = Paint()
      ..color = outlineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final outlinePath = Path()
      ..moveTo(0, size.height * 0.9)
      ..lineTo(size.width * 0.25, size.height * 0.7)
      ..lineTo(size.width * 0.5, size.height * 0.35)
      ..lineTo(size.width * 0.6, size.height * 0.55)
      ..lineTo(size.width * 0.75, size.height * 0.9)
      ..lineTo(size.width, size.height * 0.75);

    canvas.drawPath(outlinePath, outline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
