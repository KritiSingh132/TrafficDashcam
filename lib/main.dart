import 'package:car_dashcam/Model/extracted_text_model.dart';
import 'package:car_dashcam/routes/route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:camera/camera.dart';
import 'Adapter/duration_adapter.dart';
import 'Model/video_model.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Only initialize cameras on mobile platforms
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || 
                  defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      cameras = await availableCameras();
      print('Available cameras: ${cameras.length}');
    } catch (e) {
      print('Error getting cameras: $e');
    }
  }
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register adapters
  Hive.registerAdapter(VideoModelAdapter());
  Hive.registerAdapter(DurationAdapter());
  Hive.registerAdapter(ExtractedTextModelAdapter());
  
  // Open boxes
  await Hive.openBox<VideoModel>('videos');
  await Hive.openBox<VideoModel>('favoriteVideos');
  await Hive.openBox<ExtractedTextModel>('extractedText');
  
  print('Hive boxes opened successfully');
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      title: 'Dash Cam App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: kIsWeb ? null : 'Roboto', // Avoid font issues on web
      ),
    );
  }
}
