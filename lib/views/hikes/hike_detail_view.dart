import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../models/hike.dart';
import '../../models/weather_data.dart';
import '../../db/app_db.dart';
import '../../viewmodels/hike_viewmodel.dart';
import '../../viewmodels/weather_viewmodel.dart';
import '../../services/ai_service.dart';
import '../ai/ai_suggestion_detail_page.dart';
import 'hike_form_view.dart';
import '../observations/no_observation_card.dart';
import '../observations/observation_item.dart';
import '../observations/observation_list_view.dart';
import '../observations/observation_form_view.dart';

class HikeDetailView extends StatefulWidget {
  final int hikeId;

  const HikeDetailView({super.key, required this.hikeId});

  @override
  State<HikeDetailView> createState() => _HikeDetailViewState();
}

class _HikeDetailViewState extends State<HikeDetailView> {
  Hike? _hike;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHike();
  }

  Future<void> _loadHike() async {
    setState(() => _isLoading = true);

    // Use getHikeDetailData to fetch the hike together with all observations and media
    Hike? h;
    try {
      h = await AppDatabase.instance.getHikeDetailData(widget.hikeId);
    } catch (e) {
      h = null;
    }

    if (!mounted) return;
    setState(() {
      _hike = h;
      _isLoading = false;
    });

    // Load stored weather forecasts if hike exists and has valid id
    if (h != null && h.id != null && mounted) {
      try {
        final weatherVM = Provider.of<WeatherViewModel>(context, listen: false);
        await weatherVM.loadStoredForecasts(h.id!);
      } catch (e) {
        debugPrint('Error loading weather forecasts: $e');
      }
    }
  }

  // Choose the best image to show in the banner:
  // 1) First image-type MediaItem from observations (most recent observations are first)
  // 2) Fallback to placeholder asset
  Widget _buildBannerImage() {
    // Find first image path
    String? path;
    if (_hike != null && _hike!.observations.isNotEmpty) {
      for (final obs in _hike!.observations) {
        if (obs.media.isNotEmpty) {
          // Find first media item whose type equals 'image' (case-insensitive)
          dynamic found;
          for (final m in obs.media) {
            try {
              if ((m.type).toLowerCase() == 'image') {
                found = m;
                break;
              }
            } catch (_) {
              // ignore malformed media entries
            }
          }
          if (found != null && (found.path as String).isNotEmpty) {
            path = found.path as String;
            break;
          }
        }
      }
    }

    // If we found a local file path and not running on web, show it
    if (path != null && path.isNotEmpty) {
      try {
        if (!kIsWeb) {
          final file = File(path);
          if (file.existsSync()) {
            return Image.file(file, fit: BoxFit.cover);
          }
        }

        // If path looks like a network URL, try Image.network
        if (path.startsWith('http://') || path.startsWith('https://')) {
          return Image.network(path, fit: BoxFit.cover);
        }
      } catch (_) {
        // ignore and fallthrough to placeholder
      }
    }

    // Default placeholder
    return Image.asset('lib/assets/images/imageholder.png', fit: BoxFit.cover);
  }

  Future<void> _markComplete() async {
    // intentionally empty
  }

  Future<void> _deleteHike() async {
    if (_hike == null || _hike!.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete hike?'),
        content: Text('Are you sure you want to delete "${_hike!.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final vm = Provider.of<HikeViewModel>(context, listen: false);
    final success = await vm.deleteHike(_hike!.id!);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Hike deleted' : 'Failed to delete hike')),
      );
      if (success) Navigator.of(context).pop(true);
    }
  }

  void _onAddObservation() async {
    if (!mounted) return;
    final result = await Navigator.of(context).push<bool?>(
      MaterialPageRoute(builder: (_) => ObservationFormView(hikeId: _hike?.id)),
    );

    if (result == true) {
      await _loadHike();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Observation added')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final primary = cs.primary;
    final secondaryText = isDark ? Colors.grey.shade300 : const Color(0xFF8B4513);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Show the floating add button only when the hike is complete AND
      // there is at least one observation (per requested behavior). When
      // there are no observations, the NoObservationCard will render its
      // own Add button and the FAB is hidden to avoid duplicate controls.
      floatingActionButton: (!_isLoading && _hike != null && _hike!.isComplete && _hike!.observations.isNotEmpty)
          ? FloatingActionButton.extended(
        onPressed: _onAddObservation,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add observation'),
      )
          : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: cs.onBackground),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                if (_hike != null) {
                  final result = await Navigator.of(context).push<bool?>(
                    MaterialPageRoute(builder: (_) => HikeFormView(hike: _hike)),
                  );
                  if (result == true) await _loadHike();
                }
              } else if (value == 'delete') {
                await _deleteHike();
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            icon: Icon(Icons.more_vert, color: cs.onBackground),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_hike == null
          ? Center(child: Text('Hike not found', style: theme.textTheme.bodyLarge))
          : Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 300,
                automaticallyImplyLeading: false,
                backgroundColor: cs.background,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      Positioned.fill(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // show hike/observation image when available, otherwise placeholder
                            _buildBannerImage(),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    cs.surface.withOpacity(0.1),
                                    cs.background.withOpacity(0.05),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                cs.surface,
                                cs.surface.withOpacity(0.66),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_hike!.isComplete)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Completed',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.cardColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Planned',
                            style: TextStyle(
                              color: theme.hintColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      Text(
                        _hike!.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onBackground,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),

                      const SizedBox(height: 8),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(Icons.location_on, size: 20, color: cs.onBackground.withOpacity(0.6)),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _hike!.location,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onBackground.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 20),

                      _infoGrid(
                        primary,
                        date: _hike!.date,
                        length: "${_hike!.length.toStringAsFixed(1)} km",
                        difficulty: _hike!.difficulty,
                        duration: "${_hike!.estimatedDuration ?? 1} ${(_hike!.estimatedDuration ?? 1) == 1 ? 'day' : 'days'}",
                        parking: _hike!.hasParking ? 'Yes' : 'No',
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Description',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: secondaryText,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _hike!.description ?? 'No description provided.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onBackground.withOpacity(0.75),
                          height: 1.5,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          _pill(primary, Icons.check_circle, 'Complete', active: _hike!.isComplete),
                          const SizedBox(width: 12),
                          _pill(const Color(0xFFFFD700), Icons.star, 'Remarkable', active: _hike!.isRemarkable),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Weather Forecast Section
                      _buildWeatherForecastSection(primary, theme, secondaryText),

                      const SizedBox(height: 24),

                      // AI Trip Advisor Button - Always visible
                      _buildAITripAdvisorButton(primary, theme),

                      const SizedBox(height: 24),

                      Text(
                        'Observations',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: secondaryText,
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (!_hike!.isComplete)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 6,
                                offset: Offset(0, 2),
                                color: Color(0x11000000),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: cs.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.info_outline, color: cs.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hike is planned',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Observations can only be added after the hike has been completed.',
                                      style: theme.textTheme.bodySmall,
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_hike!.observations.isEmpty)
                        NoObservationCard(onAdd: _onAddObservation)
                      else if (_hike!.id != null) ...[
                          ObservationListForHike(
                            hikeId: _hike!.id!,
                            limit: 5,
                            onChanged: () async {
                              // reload full hike data when inline list reports changes
                              await _loadHike();
                            },
                          ),

                          // If there are more than 5 observations, show a button to view them all
                          if (_hike!.observations.length > 5) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () async {
                                  final result = await Navigator.of(context).push<bool?>(
                                    MaterialPageRoute(builder: (_) => ObservationListView(hikeId: _hike!.id!)),
                                  );
                                  // If any deletion happened in the full list, reload hike
                                  if (result == true) await _loadHike();
                                },
                                child: const Text('View all observations'),
                              ),
                            ),
                          ],

                          const SizedBox(height: 120),
                        ]
                      else
                        // Hike exists but has no ID (shouldn't happen, but handle gracefully)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Unable to load observations.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      )),
    );
  }

  Widget _infoGrid(
      Color primary, {
        required String date,
        required String length,
        required String difficulty,
        required String parking,
        required String duration,
      }) {
    Widget tile(IconData icon, String label, String value) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              offset: Offset(0, 3),
              color: Color(0x11000000),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, color: primary, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.0,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        tile(Icons.calendar_month, "Date", date),
        tile(Icons.straighten, "Length", length),
        tile(Icons.trending_up, "Difficulty", difficulty),
        tile(Icons.access_time, "Duration", duration),
        tile(Icons.local_parking, "Parking", parking),
      ],
    );
  }

  Widget _pill(Color color, IconData icon, String label, {bool active = false}) {
    final bool isStar = icon == Icons.star || icon == Icons.star_border;

    const Color amberMain = Color(0xFFFFC107);
    const Color amberBgActive = Color(0xFFFFF8E1);

    if (isStar) {
      final theme = Theme.of(context);
      final Color textColor = active ? amberMain : theme.hintColor;
      final Color bgColor = active ? amberBgActive : theme.cardColor.withOpacity(0.06);
      final IconData displayIcon = active ? Icons.star : Icons.star_border;
      final FontWeight fw = active ? FontWeight.w700 : FontWeight.w600;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(40)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(displayIcon, size: 16, color: textColor),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: textColor, fontWeight: fw, fontSize: 13)),
          ],
        ),
      );
    }

    final IconData displayIcon =
    (!active && icon == Icons.check_circle) ? Icons.check_circle_outline : icon;

    final Color textColor = active ? color : Theme.of(context).hintColor;
    final Color bgColor = active ? color.withOpacity(0.12) : Theme.of(context).cardColor.withOpacity(0.06);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(40)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(displayIcon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildWeatherForecastSection(Color primary, ThemeData theme, Color secondaryText) {
    if (_hike == null) return const SizedBox.shrink();

    return Consumer<WeatherViewModel>(
      builder: (context, weatherVM, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weather Forecast',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: secondaryText,
                        ),
                      ),
                      if (weatherVM.forecastList.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                _hike!.isComplete ? Icons.storage : Icons.cloud,
                                size: 12,
                                color: theme.hintColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _hike!.isComplete
                                  ? 'Stored data'
                                  : 'Live forecast',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (!weatherVM.isLoading)
                  IconButton(
                    icon: Icon(Icons.refresh, color: primary),
                    onPressed: () async {
                      await _fetchWeatherForecast();
                    },
                    tooltip: _hike!.isComplete
                      ? 'Load from database'
                      : 'Refresh weather forecast',
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (weatherVM.isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: primary),
                ),
              )
            else if (weatherVM.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      weatherVM.errorMessage!.contains('past') ||
                      weatherVM.errorMessage!.contains('future') ||
                      weatherVM.errorMessage!.contains('date')
                        ? Icons.warning_amber_rounded
                        : weatherVM.errorMessage!.contains('completed')
                        ? Icons.info_outline
                        : Icons.cloud_off,
                      size: 40,
                      color: Colors.orange.shade700
                    ),
                    const SizedBox(height: 8),
                    Text(
                      weatherVM.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orange.shade900),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 8),
                    // Only show retry button if not a validation error
                    if (!weatherVM.errorMessage!.contains('past') &&
                        !weatherVM.errorMessage!.contains('future') &&
                        !weatherVM.errorMessage!.contains('completed') &&
                        !weatherVM.errorMessage!.contains('date'))
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _fetchWeatherForecast();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              )
            else if (weatherVM.forecastList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Icon(
                      _hike!.isComplete ? Icons.history : Icons.wb_sunny,
                      size: 40,
                      color: primary
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hike!.isComplete
                        ? 'No weather data stored for this completed hike'
                        : 'No weather data available',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _fetchWeatherForecast();
                      },
                      icon: Icon(_hike!.isComplete ? Icons.refresh : Icons.download),
                      label: Text(_hike!.isComplete ? 'Load from Database' : 'Fetch Weather'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: weatherVM.forecastList.length,
                  itemBuilder: (context, index) {
                    final forecast = weatherVM.forecastList[index];
                    return _buildWeatherCard(forecast, primary);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildWeatherCard(WeatherData weather, Color primary) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            offset: Offset(0, 2),
            color: Color(0x11000000),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatDate(weather.forecastDate),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            weather.getEmoji(),
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            '${weather.temperature.toStringAsFixed(0)}°C',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            weather.condition,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).hintColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _fetchWeatherForecast() async {
    if (_hike == null || _hike!.id == null) {
      debugPrint('Cannot fetch weather: hike or hike.id is null');
      return;
    }

    final weatherVM = Provider.of<WeatherViewModel>(context, listen: false);

    try {
      // Check if hike is completed - only load from database
      if (_hike!.isComplete) {
        debugPrint('Hike is completed. Loading weather from database only.');
        await weatherVM.loadStoredForecasts(_hike!.id!);

        if (weatherVM.forecastList.isEmpty) {
          weatherVM.errorMessage = 'No weather data stored for this completed hike.';
          weatherVM.notifyListeners();
        }
        return;
      }

      // For planned hikes, fetch new forecast
      final location = _hike!.location.trim();

      if (location.isEmpty) {
        weatherVM.errorMessage = 'Location is empty';
        weatherVM.notifyListeners();
        return;
      }

      // Parse hike date
      DateTime startDate;
      try {
        startDate = _parseHikeDate(_hike!.date);
      } catch (e) {
        weatherVM.errorMessage = 'Invalid date format';
        weatherVM.notifyListeners();
        return;
      }

      // Check if hike date is in the past
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final hikeDate = DateTime(startDate.year, startDate.month, startDate.day);

      if (hikeDate.isBefore(today)) {
        weatherVM.errorMessage =
          '⚠️ Hike date is in the past (${_hike!.date}).\n'
          'Weather forecast is only available for future dates.\n'
          'Please update the hike date or mark this hike as completed.';
        weatherVM.notifyListeners();
        return;
      }

      // Check if hike date is too far in the future (API limitation: 5 days)
      final maxForecastDate = today.add(const Duration(days: 5));
      if (hikeDate.isAfter(maxForecastDate)) {
        weatherVM.errorMessage =
          '⚠️ Hike date is too far in the future (${_hike!.date}).\n'
          'Weather forecast is only available for the next 5 days.\n'
          'Please check again closer to the hike date.';
        weatherVM.notifyListeners();
        return;
      }


      if (_hike!.isMapPicked && _hike!.latitude != null && _hike!.longitude != null) {
        // Use coordinates from map picker
        await weatherVM.fetchAndSaveWeatherForHikeByCoordinates(
          _hike!.id!,
          _hike!.latitude!,
          _hike!.longitude!,
          startDate,
          _hike!.estimatedDuration ?? 1,
        );
      } else {
        // Use location name (legacy behavior)
        await weatherVM.fetchAndSaveWeatherForHikeByLocation(
          _hike!.id!,
          location,
          startDate,
          _hike!.estimatedDuration ?? 1,
        );
      }

    } catch (e) {
      weatherVM.errorMessage = 'Failed to fetch weather: $e';
      weatherVM.notifyListeners();
    }
  }

  /// Build AI Trip Advisor Button
  Widget _buildAITripAdvisorButton(Color primary, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleAIButtonTap(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Trip Advisor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get personalized recommendations for this hike',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handle AI button tap - Check database first, then generate if needed
  void _handleAIButtonTap(BuildContext context) async {
    if (_hike?.id == null) {
      _showErrorDialog(context, 'Error', 'Cannot generate AI suggestion for this hike.');
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
                'Loading AI suggestions...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Checking database',
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
      // Check if AI suggestion already exists in database
      final existingSuggestion = await AppDatabase.instance.getAISuggestionByHikeId(_hike!.id!);

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      if (existingSuggestion != null) {
        // AI suggestion found in database, navigate directly to detail page
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AISuggestionDetailPage(
                suggestion: existingSuggestion,
                hike: _hike!,
              ),
            ),
          );
        }
      } else {
        // No AI suggestion found, show info dialog
        _showNoAISuggestionDialog(context);
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      _showErrorDialog(
        context,
        'Error',
        'An error occurred while checking AI suggestions: $e',
      );
    }
  }

  /// Show dialog informing user that no AI suggestion exists for this hike
  void _showNoAISuggestionDialog(BuildContext context) {
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
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.info_outline,
                color: Colors.blue[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No AI Plan Available',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          'AI has not planned this hike yet.\n\n'
              'AI Trip Advisor is only available for previously planned hikes.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue[700],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Close'),
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

  DateTime _parseHikeDate(String dateStr) {
    try {
      // Try format 1: "August 12, 2024" (Month name format)
      final months = {
        'january': 1, 'february': 2, 'march': 3, 'april': 4,
        'may': 5, 'june': 6, 'july': 7, 'august': 8,
        'september': 9, 'october': 10, 'november': 11, 'december': 12,
      };

      final lowerStr = dateStr.toLowerCase();

      // Check if it contains month name
      if (lowerStr.contains(' ')) {
        final parts = lowerStr.split(' ');
        if (parts.length == 3) {
          final month = months[parts[0]];
          if (month != null) {
            final day = int.parse(parts[1].replaceAll(',', ''));
            final year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
        }
      }

      // Try format 2: "YYYY-MM-DD" (ISO format)
      if (dateStr.contains('-') && dateStr.length == 10) {
        return DateTime.parse(dateStr);
      }

      // Try format 3: "D/M/YYYY" or "DD/MM/YYYY" or "M/D/YYYY" (Slash format)
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          final firstNum = int.parse(parts[0]);
          final secondNum = int.parse(parts[1]);
          final year = int.parse(parts[2]);

          // Determine if it's DD/MM/YYYY or MM/DD/YYYY
          // If first number > 12, it must be DD/MM/YYYY
          // If second number > 12, it must be MM/DD/YYYY
          // Otherwise, assume DD/MM/YYYY (Vietnamese format)

          if (firstNum > 12) {
            // Must be DD/MM/YYYY
            return DateTime(year, secondNum, firstNum);
          } else if (secondNum > 12) {
            // Must be MM/DD/YYYY
            return DateTime(year, firstNum, secondNum);
          } else {
            // Ambiguous - assume DD/MM/YYYY (Vietnamese format)
            // e.g., "3/5/2025" = May 3, 2025
            return DateTime(year, secondNum, firstNum);
          }
        }
      }

      // Try format 4: "D.M.YYYY" or "DD.MM.YYYY" (Dot format)
      if (dateStr.contains('.')) {
        final parts = dateStr.split('.');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }

    } catch (e) {
      debugPrint('Error parsing date: $e');
    }

    // If all parsing fails, throw exception instead of returning DateTime.now()
    throw FormatException('Unable to parse date: $dateStr');
  }
}
