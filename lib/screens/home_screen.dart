import 'package:car_dashcam/hive/hive_boxes.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../Model/video_model.dart';
import '../Widgets/video_controls.dart';
import '../provider/video_provider.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final cameraControllerAsyncValue = ref.watch(cameraControllerProvider);
    final isRecording = ref.watch(recordingStateProvider);
    final isFavoriteMode = ref.watch(settingsProvider).isFavorite;
    
    Future<void> recButton(BuildContext context) async {
      final cameraController = ref.read(cameraControllerProvider).value;
      final videoService = ref.read(videoServiceProvider);
      
      print('Record button pressed. Recording state: $isRecording');
      print('Camera controller: ${cameraController != null ? 'Available' : 'Null'}');
      print('Video service: ${videoService != null ? 'Available' : 'Null'}');
      print('Favorite mode: $isFavoriteMode');
      
      if (cameraController != null && cameraController.value.isInitialized && videoService != null) {
        try {
          if (!isRecording) {
            // Start recording
                       ref.read(recordingStateProvider.notifier).state = true;
            int clipcount = ref.read(settingsProvider).clipCountLimit;
            WakelockPlus.enable();
            
            print('Starting recording session with $clipcount clips');
            
            for (int i = 0; i < clipcount; i++) {
              try {
                print('Recording clip ${i + 1}/$clipcount');
                
                VideoModel? recordedclip = await videoService.recordClip(
                  clipLength: Duration(minutes: ref.read(settingsProvider).clipLength),
                  quality: ref.read(settingsProvider).videoQuality,
                );
                
                if (recordedclip != null) {
                  print('Clip recorded successfully: ${recordedclip.filePath}');
                  
                  if (isFavoriteMode) {
                    ref.read(favoriteVideoListProvider.notifier).addFavVideo(recordedclip, context);
                    print('Added to favorites');
                  } else {
                    ref.read(videoListProvider.notifier).addVideo(recordedclip, context);
                    print('Added to regular videos');
                  }
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Clip ${i + 1} recorded successfully!'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                } else {
                  print('Failed to record clip ${i + 1}: recordedclip is null');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to record clip ${i + 1}')),
                  );
                  break;
                }
                
                if (i + 1 >= clipcount) {
                  print('Clip count limit reached. Stopping recording.');
                  break;
                }
                
                setState(() {});
              } catch (e) {
                print('Error while recording clip ${i + 1}: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error recording clip ${i + 1}: $e')),
                );
                break;
              }
            }
            
            print('Recording session completed');
          } else {
            print('Stopping recording manually');
          }
          
          ref.read(recordingStateProvider.notifier).state = false;
          WakelockPlus.disable();
          
          // Show completion message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFavoriteMode 
                ? 'Recording completed! Videos saved to favorites.' 
                : 'Recording completed! Videos saved.'),
              duration: const Duration(seconds: 2),
            ),
          );
          
        } catch (e) {
          print('Error in recording process: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recording error: ${e.toString()}')),
          );
          ref.read(recordingStateProvider.notifier).state = false;
          WakelockPlus.disable();
        }
      } else {
        String errorMsg = '';
        if (cameraController == null) {
          errorMsg = 'Camera not available';
        } else if (!cameraController.value.isInitialized) {
          errorMsg = 'Camera not initialized';
        } else if (videoService == null) {
          errorMsg = 'Video service not available';
        }
        
        print('Cannot start recording: $errorMsg');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }

    DateTime currentTime = DateTime.now();
    String formattedTime = DateFormat('hh:mm:ss a').format(currentTime);

    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          return cameraControllerAsyncValue.when(
            data: (cameraController) {
              if (cameraController != null && cameraController.value.isInitialized) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    double cameraPreviewHeight = orientation != Orientation.landscape
                        ? constraints.maxHeight * 0.9
                        : constraints.maxHeight * 0.97;
                    double cameraPreviewWidth = constraints.maxWidth * 1;

                    return Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            SizedBox(
                              width: cameraPreviewWidth,
                              height: cameraPreviewHeight,
                              child: AspectRatio(
                                aspectRatio: cameraController.value.aspectRatio,
                                child: CameraPreview(cameraController),
                              ),
                            ),
                            Positioned(
                              left: 16.0,
                              top: 40,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isRecording)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.fiber_manual_record, color: Colors.white, size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            "RECORDING",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  if (isFavoriteMode)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.yellow.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star, color: Colors.black, size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            "FAVORITE MODE",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (orientation == Orientation.landscape)
                              Positioned(
                                right: 16.0,
                                child: Column(
                                  children: [
                                    // Record/stop button
                                    FloatingActionButton(
                                      onPressed: isRecording ? null : () async {
                                        await recButton(context);
                                      },
                                      disabledElevation: 0.0,
                                      shape: const CircleBorder(),
                                      backgroundColor: isRecording ? Colors.red : Colors.white,
                                      child: Icon(
                                        isRecording ? Icons.stop : Icons.fiber_manual_record,
                                        color: isRecording ? Colors.white : Colors.red,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: 20.0),
                                    // Settings button
                                    FloatingActionButton(
                                      onPressed: isRecording ? null : () {
                                        context.go('/settings');
                                      },
                                      child: const Icon(Icons.settings),
                                    ),
                                    const SizedBox(height: 20.0),
                                    // Recording list button
                                    FloatingActionButton(
                                      onPressed: () {
                                        context.go('/rec_list');
                                      },
                                      child: const Icon(Icons.list),
                                    ),
                                    const SizedBox(height: 20.0),
                                    // Favorite toggle button
                                    FloatingActionButton(
                                      onPressed: isRecording ? null : () {
                                        ref.read(settingsProvider.notifier).updateIsFavorite(!isFavoriteMode);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              !isFavoriteMode 
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
                                    )
                                  ],
                                )
                              )
                            else
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 20.0,
                                  bottom: 20.0,
                                  top: cameraPreviewHeight * 0.02,
                                ),
                                child: FloatingActionButton(
                                  onPressed: isRecording ? null : () async {
                                    await recButton(context);
                                  },
                                  disabledElevation: 0.0,
                                  shape: const CircleBorder(),
                                  backgroundColor: isRecording ? Colors.red : Colors.white,
                                  child: Icon(
                                    isRecording ? Icons.stop : Icons.fiber_manual_record,
                                    color: isRecording ? Colors.white : Colors.red,
                                    size: 32,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                        if (orientation != Orientation.landscape)
                          VideoControls(
                            onSettingsChanged: (bool isFavVideo) {
                              ref.read(settingsProvider.notifier).updateIsFavorite(isFavVideo);
                            },
                          ),
                      ],
                    );
                  },
                );
              } else {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Initializing camera...'),
                    ],
                  ),
                );
              }
            },
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading camera...'),
                ],
              ),
            ),
            error: (e, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text('Camera Error: $e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(cameraControllerProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
