import 'package:hive/hive.dart';

part 'extracted_text_model.g.dart';

@HiveType(typeId: 2)
class ExtractedTextModel extends HiveObject {
  @HiveField(0)
  final String videoPath;

  @HiveField(1)
  final String extractedText;

  @HiveField(2)
  final DateTime extractedAt;

  ExtractedTextModel({
    required this.videoPath,
    required this.extractedText,
    required this.extractedAt,
  });

  @override
  String toString() {
    return 'ExtractedTextModel(videoPath: $videoPath, extractedText: $extractedText, extractedAt: $extractedAt)';
  }
}
