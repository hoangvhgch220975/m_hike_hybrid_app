// lib/views/plan/widgets/plan_card.dart

import 'package:flutter/material.dart';
import '../../../models/hike.dart';
import '../../../models/ai_suggestion.dart';
import '../../../services/ai_service.dart';
import '../../ai/ai_suggestion_detail_page.dart';

class PlanCard extends StatelessWidget {
  final Hike hike;
  final VoidCallback? onCompleted;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  // Optional override color for the complete button (if null, uses theme.primary)
  final Color? completeButtonColor;

  const PlanCard({
    super.key,
    required this.hike,
    this.onCompleted,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.completeButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    // Determine difficulty color
    Color difficultyColor;
    switch (hike.difficulty) {
      case 'Easy':
        difficultyColor = const Color(0xFF4CAF50);
        break;
      case 'Moderate':
        difficultyColor = const Color(0xFFFF9800);
        break;
      case 'Hard':
        difficultyColor = const Color(0xFFF44336);
        break;
      default:
        difficultyColor = Colors.grey;
    }

    final theme = Theme.of(context);
    // Use provided completeButtonColor for this card if present, otherwise fall back to theme primary
    final primary = completeButtonColor ?? theme.colorScheme.primary;
    // Determine icon color that contrasts with the chosen primary
    final onPrimary = ThemeData.estimateBrightnessForColor(primary) == Brightness.dark ? Colors.white : Colors.black;

    // Show options when user taps the overflow button
    void _showOptions() async {
      showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    if (onEdit != null) onEdit!();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.of(ctx).pop();

                    // Confirm deletion
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) {
                        return AlertDialog(
                          title: const Text('Delete hike?'),
                          content: Text('Are you sure you want to delete "${hike.name}"? This action cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.of(dCtx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        );
                      },
                    );

                    if (confirm == true && onDelete != null) {
                      onDelete!();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          );
        },
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        // Outer InkWell handles both tap (open detail) and long-press (open options)
        onTap: onTap,
        onLongPress: _showOptions,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(30, 0, 0, 0),
                offset: Offset(0, 8),
                blurRadius: 24,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Location + Date + Action Buttons
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hike.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              hike.location,
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            Text('•', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                            Text(
                              hike.date,
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Delete button - Nút xóa (improved styling)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        // Show confirmation dialog - Hiển thị dialog xác nhận
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext ctx) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red[700],
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Delete Plan',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                'Are you sure you want to delete "${hike.name}"? This action cannot be undone.',
                                style: const TextStyle(fontSize: 15, height: 1.5),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );

                        // If user confirmed deletion - Nếu người dùng xác nhận xóa
                        if (shouldDelete == true && onDelete != null) {
                          onDelete!();
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red[400]!,
                              Colors.red[600]!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.delete_outline, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Complete button - Nút hoàn thành
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onCompleted,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(Icons.check, size: 20, color: onPrimary),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                hike.description ?? 'No description available',
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.5, color: theme.hintColor),
                maxLines: 3,
                overflow: TextOverflow.visible,
                softWrap: true,
              ),

              const SizedBox(height: 16),

              // Difficulty + Length + AI Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Difficulty badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: difficultyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: difficultyColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      hike.difficulty,
                      style: theme.textTheme.bodyMedium?.copyWith(color: difficultyColor, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),

                  Row(
                    children: [
                      // Length text
                      Text(
                        "${hike.length.toStringAsFixed(1)} km",
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      // AI suggestion button - Nút AI gợi ý
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _handleAIButtonTap(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF667eea).withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Xử lý khi nhấn nút AI - Get or generate AI suggestion
  void _handleAIButtonTap(BuildContext context) async {
    if (hike.id == null) {
      _showErrorDialog(context, 'Cannot generate AI suggestion', 'This hike hasn\'t been saved yet.');
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'AI is analyzing your trip...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a few seconds',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).hintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Get or generate AI suggestion
      final suggestion = await AIService.getOrGenerateAISuggestion(hike);

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      if (suggestion != null) {
        // Show summary dialog with "View Details" button
        _showAISummaryDialog(context, suggestion);
      } else {
        _showErrorDialog(context, 'AI Generation Failed', 'Failed to generate AI suggestion. Please try again.');
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Show error dialog
      String errorMessage = 'An error occurred while generating AI suggestion.';
      if (e.toString().contains('timeout')) {
        errorMessage = 'The AI service is taking too long to respond. Please check your connection and try again.';
      } else if (e.toString().contains('Connection') || e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to AI service.\n\n'
            'Please make sure:\n'
            '• Backend is running at localhost:8000\n'
            '• Using correct URL:\n'
            '  - Android Emulator: 10.0.2.2:8000\n'
            '  - iOS/Desktop: localhost:8000\n'
            '• Firewall is not blocking connection';
      }

      _showErrorDialog(context, 'Connection Error', errorMessage);
    }
  }


  void _showAISummaryDialog(BuildContext context, AISuggestion suggestion) {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Trip Advisor',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Personalized recommendations',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content - Scrollable summary
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary
                        Text(
                          'Summary',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          suggestion.summary,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Quick stats
                        _buildQuickStat(
                          theme,
                          Icons.backpack,
                          'Packing Items',
                          '${suggestion.packingList.length} items',
                        ),
                        const SizedBox(height: 12),
                        _buildQuickStat(
                          theme,
                          Icons.warning_amber_rounded,
                          'Potential Risks',
                          '${suggestion.risks.length} identified',
                        ),

                        if (suggestion.startTimeHint != null) ...[
                          const SizedBox(height: 12),
                          _buildQuickStat(
                            theme,
                            Icons.access_time,
                            'Best Start Time',
                            suggestion.startTimeHint!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            // Navigate to detail page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AISuggestionDetailPage(
                                  suggestion: suggestion,
                                  hike: hike,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667eea),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'View Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStat(ThemeData theme, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF667eea).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF667eea).withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF667eea)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[700],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
