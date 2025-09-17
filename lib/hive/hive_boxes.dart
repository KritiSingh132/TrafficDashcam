import 'package:hive/hive.dart';
import '../Model/video_model.dart';
import '../Model/extracted_text_model.dart';

class HiveBoxes {
  static Box<VideoModel> getVideosBox() => Hive.box<VideoModel>('videos');
  static Box<VideoModel> getFavVideosBox() => Hive.box<VideoModel>('favoriteVideos');
  static Box<ExtractedTextModel> getExtractedTextBox() => Hive.box<ExtractedTextModel>('extractedText');
}
