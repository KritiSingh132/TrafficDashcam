import 'package:car_dashcam/provider/video_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VideoControls extends ConsumerStatefulWidget {
  final Function( bool isFav) onSettingsChanged;

  const VideoControls({super.key, required this.onSettingsChanged});

  @override
  _VideoControlsState createState() => _VideoControlsState();
}

class _VideoControlsState extends ConsumerState<VideoControls> {


  bool isFav = false;



  @override
 // Add this to your VideoControls widget if not already present
Widget build(BuildContext context) {
  return Consumer(
    builder: (context, ref, child) {
      final isFavoriteMode = ref.watch(settingsProvider).isFavorite;
      
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Settings button
          FloatingActionButton(
            onPressed: () {
              context.go('/settings');
            },
            child: const Icon(Icons.settings),
          ),
          // Recording list button
          FloatingActionButton(
            onPressed: () {
              context.go('/rec_list');
            },
            child: const Icon(Icons.list),
          ),
          // Favorite toggle button
          FloatingActionButton(
            onPressed: () {
              final newFavoriteState = !isFavoriteMode;
              ref.read(settingsProvider.notifier).updateIsFavorite(newFavoriteState);
              widget.onSettingsChanged(newFavoriteState);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    newFavoriteState 
                      ? 'Favorite mode enabled - next recordings will be saved as favorites'
                      : 'Favorite mode disabled - next recordings will be saved normally'
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            backgroundColor: isFavoriteMode ? Colors.yellow : Colors.grey,
            child: Icon(
              Icons.star,
              color: isFavoriteMode ? Colors.black : Colors.white,
              size: 30.0,
            ),
          ),
        ],
      );
    },
  );
}

  void _updateSettings() {
    widget.onSettingsChanged(isFav);
  }
}
