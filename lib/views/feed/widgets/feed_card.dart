// lib/views/feed/widgets/feed_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/hike.dart';
import '../../../db/app_db.dart';
import '../../shared/notification_helper.dart';

class FeedCard extends StatefulWidget {
  final Hike hike;
  final VoidCallback? onRemarkableChanged;
  final VoidCallback? onTap;

  const FeedCard({
    super.key,
    required this.hike,
    this.onRemarkableChanged,
    this.onTap,
  });

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  late bool _isRemarkable;
  String? _bannerPath;

  @override
  void initState() {
    super.initState();
    _isRemarkable = widget.hike.isRemarkable;
    _loadBannerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant FeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the parent rebuilds (filtering / pagination), Flutter may reuse
    // the same State object for a different Hike instance. If the hike id
    // changed we must reload the banner and update state accordingly.
    if (oldWidget.hike.id != widget.hike.id) {
      _isRemarkable = widget.hike.isRemarkable;
      _bannerPath = null;
      _loadBannerIfNeeded();
    }
  }

  Future<void> _loadBannerIfNeeded() async {
    try {
      if (widget.hike.id == null) return;
      final observations = await AppDatabase.instance.getObservationsByHike(widget.hike.id!);
      String? path;

      // Find first IMAGE media (not video)
      if (observations.isNotEmpty) {
        for (final obs in observations) {
          if (obs.media.isNotEmpty) {
            // Find first image in this observation
            for (final media in obs.media) {
              if (media.type.toLowerCase() == 'image') {
                path = media.path;
                break;
              }
            }
            // If found image, stop searching
            if (path != null) break;
          }
        }
      }

      if (!mounted) return;
      setState(() => _bannerPath = path);
    } catch (_) {
      // ignore and fallback to asset
    }
  }

  Widget _buildBannerWidget(String? path) {
    if (path == null || path.isEmpty) {
      return Image.asset('lib/assets/images/imageholder.png', fit: BoxFit.cover);
    }

    if (path.startsWith('http') || path.startsWith('https')) return Image.network(path, fit: BoxFit.cover);
    if (path.startsWith('file://')) return Image.file(File(path.replaceFirst('file://', '')), fit: BoxFit.cover);
    if (path.startsWith('/') || RegExp(r'^[a-zA-Z]:\\').hasMatch(path)) return Image.file(File(path), fit: BoxFit.cover);
    return Image.asset(path, fit: BoxFit.cover);
  }

  Future<void> _toggleRemarkable() async {
    final newValue = !_isRemarkable;

    // Update in database
    final updatedHike = Hike(
      id: widget.hike.id,
      name: widget.hike.name,
      location: widget.hike.location,
      date: widget.hike.date,
      length: widget.hike.length,
      difficulty: widget.hike.difficulty,
      description: widget.hike.description,
      isComplete: widget.hike.isComplete,
      isRemarkable: newValue,
      hasParking: widget.hike.hasParking,
    );

    try {
      await AppDatabase.instance.updateHike(updatedHike);

      setState(() {
        _isRemarkable = newValue;
      });

      // Show notification
      if (newValue) {
        if (mounted) {
          NotificationHelper.showSuccess(
            context,
            '⭐ "${widget.hike.name}" marked as remarkable!',
          );
        }
      } else {
        if (mounted) {
          NotificationHelper.showInfo(
            context,
            'Removed remarkable status from "${widget.hike.name}"',
          );
        }
      }

      // Notify parent to refresh
      widget.onRemarkableChanged?.call();
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(
          context,
          'Failed to update remarkable status',
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Generate tags based on hike properties
    final tags = _generateTags();

    // card and shadow adapted to current theme
    final cardColor = theme.cardColor ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final shadowColor = Colors.black.withOpacity(isDark ? 0.5 : 0.08);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: shadowColor, blurRadius: 12),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE - Show default hike image with remarkable button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRect(child: _buildBannerWidget(_bannerPath)),
                  ),
                ),
                // Remarkable button overlay
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _toggleRemarkable,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isRemarkable
                            ? const Color(0xFFFFD700)
                            : (theme.colorScheme.surface.withOpacity(0.9)),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRemarkable ? Icons.star : Icons.star_border,
                        color: _isRemarkable
                            ? Colors.white
                            : (theme.iconTheme.color ?? const Color(0xFF6B7280)),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // CONTENT
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.hike.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ) ??
                        const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                  const SizedBox(height: 6),

                  _iconText(Icons.location_on, widget.hike.location, theme),
                  const SizedBox(height: 4),
                  _iconText(Icons.calendar_today, widget.hike.date, theme),
                  const SizedBox(height: 4),
                  _iconText(Icons.straighten, '${widget.hike.length.toStringAsFixed(1)} km', theme),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.map((t) => _tagChip(t, theme)).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FeedTag> _generateTags() {
    List<FeedTag> tags = [];

    // Difficulty tag
    Color difficultyColor;
    IconData difficultyIcon;
    switch (widget.hike.difficulty) {
      case 'Easy':
        difficultyColor = Colors.green;
        difficultyIcon = Icons.directions_walk;
        break;
      case 'Moderate':
        difficultyColor = Colors.lightBlue;
        difficultyIcon = Icons.hiking;
        break;
      case 'Hard':
        difficultyColor = Colors.indigo;
        difficultyIcon = Icons.landscape;
        break;
      default:
        difficultyColor = Colors.grey;
        difficultyIcon = Icons.help_outline;
    }
    tags.add(FeedTag(widget.hike.difficulty, difficultyColor, difficultyIcon));

    // Completed tag
    if (widget.hike.isComplete) {
      tags.add(const FeedTag("Completed", Color(0xFF225749)));
    }

    // Remarkable tag (use state variable for real-time updates)
    if (_isRemarkable) {
      tags.add(const FeedTag("Remarkable 🌟", Color(0xFFFFD700)));
    }

    return tags;
  }

  Widget _iconText(IconData icon, String text, ThemeData theme) {
    final iconColor = theme.iconTheme.color?.withOpacity(0.8) ?? Colors.grey[600];
    final textColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.9) ?? Colors.grey[600];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
        ),
      ],
    );
  }

  Widget _tagChip(FeedTag tag, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tag.color.withOpacity(isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tag.icon != null) ...[
            Icon(tag.icon, size: 14, color: tag.color),
            const SizedBox(width: 4),
          ],
          Text(
            tag.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tag.color,
            ),
          ),
        ],
      ),
    );
  }
}

// TAG MODEL
class FeedTag {
  final String label;
  final Color color;
  final IconData? icon;

  const FeedTag(this.label, this.color, [this.icon]);
}

