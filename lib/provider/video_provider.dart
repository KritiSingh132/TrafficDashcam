import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../Model/video_model.dart';
import '../hive/hive_boxes.dart';

// Camera controller provider
final cameraControllerProvider = FutureProvider<CameraController?>((ref) async {
  try {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return null;
    
    final controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: true,
    );
    
    await controller.initialize();
    return controller;
  } catch (e) {
    print('Error initializing camera: $e');
    return null;
  }
});

// Recording state provider
final recordingStateProvider = StateProvider<bool>((ref) => false);

// Video service provider
final videoServiceProvider = Provider<VideoService?>((ref) {
  final cameraController = ref.watch(cameraControllerProvider).value;
  if (cameraController != null) {
    return VideoService(cameraController);
  }
  return null;
});

// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

// Video list providers
final videoListProvider = StateNotifierProvider<VideoListNotifier, List<VideoModel>>((ref) {
  return VideoListNotifier();
});

final favoriteVideoListProvider = StateNotifierProvider<FavoriteVideoListNotifier, List<VideoModel>>((ref) {
  return FavoriteVideoListNotifier();
});

// Video Service Class
class VideoService {
  final CameraController _cameraController;
  
  VideoService(this._cameraController);
  
  Future<VideoModel?> recordClip({
    required Duration clipLength,
    required ResolutionPreset quality,
  }) async {
    try {
      if (!_cameraController.value.isInitialized) {
        print('Camera not initialized');
        return null;
      }

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final videoDir = Directory(path.join(directory.path, 'videos'));
      
      // Create videos directory if it doesn't exist
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'video_$timestamp.mp4';
      final filePath = path.join(videoDir.path, fileName);

      print('Starting recording to: $filePath');

      // Start recording
      await _cameraController.startVideoRecording();
      print('Recording started...');

      // Wait for the specified duration
      await Future.delayed(clipLength);

      // Stop recording
      final videoFile = await _cameraController.stopVideoRecording();
      print('Recording stopped. File saved at: ${videoFile.path}');

      // Move file to our custom directory
      final file = File(videoFile.path);
      final newFile = await file.copy(filePath);
      await file.delete(); // Delete original temp file

      print('Video moved to: ${newFile.path}');

      // Create VideoModel
      final videoModel = VideoModel(
        filePath: newFile.path,
        recordedAt: DateTime.now(),
        duration: clipLength,
      );

      return videoModel;
    } catch (e) {
      print('Error recording video: $e');
      return null;
    }
  }
}

// Settings classes
class AppSettings {
  final int clipLength;
  final int clipCountLimit;
  final ResolutionPreset videoQuality;
  final bool isFavorite;

  AppSettings({
    this.clipLength = 1, // 1 minute default
    this.clipCountLimit = 5,
    this.videoQuality = ResolutionPreset.high,
    this.isFavorite = false,
  });

  AppSettings copyWith({
    int? clipLength,
    int? clipCountLimit,
    ResolutionPreset? videoQuality,
    bool? isFavorite,
  }) {
    return AppSettings(
      clipLength: clipLength ?? this.clipLength,
      clipCountLimit: clipCountLimit ?? this.clipCountLimit,
      videoQuality: videoQuality ?? this.videoQuality,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings());

  void updateIsFavorite(bool isFavorite) {
    state = state.copyWith(isFavorite: isFavorite);
    print('Favorite mode updated to: $isFavorite');
  }

  void updateClipLength(int minutes) {
    state = state.copyWith(clipLength: minutes);
  }

  void updateClipCount(int count) {
    state = state.copyWith(clipCountLimit: count);
  }

  void updateVideoQuality(ResolutionPreset quality) {
    state = state.copyWith(videoQuality: quality);
  }

  // Add the missing updateSettings method
  void updateSettings(int clipLength, int clipCountLimit, ResolutionPreset resolutionPreset) {
    state = state.copyWith(
      clipLength: clipLength,
      clipCountLimit: clipCountLimit,
      videoQuality: resolutionPreset,
    );
    print('Settings updated: clipLength=$clipLength, clipCount=$clipCountLimit, quality=$resolutionPreset');
  }
}

// Video list notifiers
class VideoListNotifier extends StateNotifier<List<VideoModel>> {
  VideoListNotifier() : super([]) {
    _loadVideos();
  }

  void _loadVideos() {
    final box = HiveBoxes.getVideosBox();
    state = box.values.toList();
    print('Loaded ${state.length} regular videos');
  }

  void addVideo(VideoModel video, context) {
    final box = HiveBoxes.getVideosBox();
    box.add(video);
    state = [...state, video];
    print('Added video to regular list: ${video.filePath}');
  }

  void removeVideo(VideoModel video) {
    final box = HiveBoxes.getVideosBox();
    final index = box.values.toList().indexWhere((v) => v.filePath == video.filePath);
    if (index != -1) {
      box.deleteAt(index);
      state = state.where((v) => v.filePath != video.filePath).toList();
    }
  }
}

class FavoriteVideoListNotifier extends StateNotifier<List<VideoModel>> {
  FavoriteVideoListNotifier() : super([]) {
    _loadFavoriteVideos();
  }

  void _loadFavoriteVideos() {
    final box = HiveBoxes.getFavVideosBox();
    state = box.values.toList();
    print('Loaded ${state.length} favorite videos');
  }

  void addFavVideo(VideoModel video, context) {
    final box = HiveBoxes.getFavVideosBox();
    box.add(video);
    state = [...state, video];
    print('Added video to favorites: ${video.filePath}');
  }

  void removeFavVideo(VideoModel video) {
    final box = HiveBoxes.getFavVideosBox();
    final index = box.values.toList().indexWhere((v) => v.filePath == video.filePath);
    if (index != -1) {
      box.deleteAt(index);
      state = state.where((v) => v.filePath != video.filePath).toList();
    }
  }
}
