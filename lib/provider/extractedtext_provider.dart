import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Model/extracted_text_model.dart';
import '../hive/hive_boxes.dart';

final extractedTextProvider = StateNotifierProvider<ExtractedTextNotifier, List<ExtractedTextModel>>((ref) {
  return ExtractedTextNotifier();
});

class ExtractedTextNotifier extends StateNotifier<List<ExtractedTextModel>> {
  ExtractedTextNotifier() : super([]) {
    _loadExtractedTexts();
  }

  void _loadExtractedTexts() {
    try {
      var box = HiveBoxes.getExtractedTextBox();
      state = box.values.toList();
      print('Loaded ${state.length} extracted texts');
    } catch (e) {
      print('Error loading extracted texts: $e');
      state = [];
    }
  }

  void addExtractedText(ExtractedTextModel extractedText) {
    try {
      var box = HiveBoxes.getExtractedTextBox();
      box.add(extractedText);
      state = [...state, extractedText];
      print('Added extracted text for: ${extractedText.videoPath}');
    } catch (e) {
      print('Error adding extracted text: $e');
    }
  }

  void removeExtractedText(ExtractedTextModel extractedText) {
    try {
      var box = HiveBoxes.getExtractedTextBox();
      final index = box.values.toList().indexWhere((e) => e.videoPath == extractedText.videoPath);
      if (index != -1) {
        box.deleteAt(index);
        state = state.where((e) => e.videoPath != extractedText.videoPath).toList();
        print('Removed extracted text for: ${extractedText.videoPath}');
      }
    } catch (e) {
      print('Error removing extracted text: $e');
    }
  }

  ExtractedTextModel? getExtractedTextForVideo(String videoPath) {
    try {
      return state.firstWhere((e) => e.videoPath == videoPath);
    } catch (e) {
      return null;
    }
  }
}
