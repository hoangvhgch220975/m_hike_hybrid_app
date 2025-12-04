import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/hike.dart';
import '../../../db/app_db.dart';
import '../../shared/notification_helper.dart';

class RemarkableCard extends StatefulWidget {
  final Hike hike;
  final VoidCallback? onTap;
  final VoidCallback? onRemarkableChanged;

  const RemarkableCard({
    super.key,
    required this.hike,
    this.onTap,
    this.onRemarkableChanged,
  });

  @override
  State<RemarkableCard> createState() => _RemarkableCardState();
}

class _RemarkableCardState extends State<RemarkableCard> {
  late bool _isRemarkable;
  String? _bannerPath;

  @override
  void initState() {
    super.initState();
    _isRemarkable = widget.hike.isRemarkable;
    _loadBannerIfNeeded();
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
      // ignore and fallback to placeholder
    }
  }

  Widget _buildBannerWidget(String? path) {
    if (path == null || path.isEmpty) return Image.asset('lib/assets/images/imageholder.png', fit: BoxFit.cover);
    if (path.startsWith('http') || path.startsWith('https')) return Image.network(path, fit: BoxFit.cover);
    if (path.startsWith('file://')) return Image.file(File(path.replaceFirst('file://', '')), fit: BoxFit.cover);
    if (path.startsWith('/') || RegExp(r'^[a-zA-Z]:\\').hasMatch(path)) return Image.file(File(path), fit: BoxFit.cover);
    return Image.asset(path, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image (use placeholder asset as default) with remarkable button
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
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
                          color: _isRemarkable ? const Color(0xFFFFD700) : theme.cardColor.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRemarkable ? Icons.star : Icons.star_border,
                          color: _isRemarkable ? Colors.white : theme.iconTheme.color,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isRemarkable)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Text('Remarkable 🌟', style: TextStyle(fontSize: 12, color: Color(0xFFFFD700), fontWeight: FontWeight.w600)),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      widget.hike.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.hike.location,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, color: theme.hintColor),
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                    const SizedBox(height: 8),
                    // optional description
                    if (widget.hike.description != null && widget.hike.description!.isNotEmpty)
                      Text(
                        widget.hike.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.4, color: theme.hintColor),
                        maxLines: 3,
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
