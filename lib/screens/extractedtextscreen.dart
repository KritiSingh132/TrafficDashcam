import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../Model/extracted_text_model.dart';
import '../provider/extractedtext_provider.dart';

class ExtractedTextScreen extends ConsumerStatefulWidget {
  final String videoPath;

  const ExtractedTextScreen({super.key, required this.videoPath});

  @override
  _ExtractedTextScreenState createState() => _ExtractedTextScreenState();
}

class _ExtractedTextScreenState extends ConsumerState<ExtractedTextScreen> {
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  String? _extractedText;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _loadExistingExtractedText();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
      }).catchError((error) {
        print('Error initializing video: $error');
      });
  }

  void _loadExistingExtractedText() {
    final existingText = ref.read(extractedTextProvider.notifier).getExtractedTextForVideo(widget.videoPath);
    if (existingText != null) {
      setState(() {
        _extractedText = existingText.extractedText;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extractedTextList = ref.watch(extractedTextProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Extract Text from Video',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields, color: Colors.white),
            onPressed: _extractText,
          ),
        ],
      ),
      body: Column(
        children: [
          // Video Player Section
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.black,
            child: _videoController != null && _videoController!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          
          // Video Controls
          if (_videoController != null && _videoController!.value.isInitialized)
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: () {
                      setState(() {
                        _videoController!.value.isPlaying
                            ? _videoController!.pause()
                            : _videoController!.play();
                      });
                    },
                  ),
                  Expanded(
                    child: VideoProgressIndicator(
                      _videoController!,
                      allowScrubbing: true,
                    ),
                  ),
                ],
              ),
            ),

          // Extract Text Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _extractText,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.text_fields),
                label: Text(_isLoading ? 'Extracting...' : 'Extract Text from Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Extracted Text Section
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Extracted Text:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _extractedText ?? 'No text extracted yet. Tap the extract button to analyze the video.',
                        style: TextStyle(
                          fontSize: 16,
                          color: _extractedText != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _extractText() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate text extraction process
      // In a real app, you would use OCR libraries like google_ml_kit or tesseract_ocr
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock extracted text - replace this with actual OCR implementation
      String extractedTexts = _simulateTextExtraction();
      
      // Create ExtractedTextModel with correct parameter names
      final result = ExtractedTextModel(
        videoPath: widget.videoPath, 
        extractedText: extractedTexts,  // Use extractedText instead of text
        extractedAt: DateTime.now(),
      );
      
      // Add to provider
      ref.read(extractedTextProvider.notifier).addExtractedText(result);
      
      setState(() {
        _extractedText = extractedTexts;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text extraction completed!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error extracting text: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _simulateTextExtraction() {
    // This is a mock function. In a real app, you would implement actual OCR
    final mockTexts = [
      "License Plate: ABC-1234\nSpeed Limit: 60 MPH\nLocation: Main Street",
      "STOP\nSchool Zone\nSpeed Limit 25\nWhen Children Present",
      "Highway 101\nNext Exit 2 Miles\nGas Food Lodging",
      "No Parking\nTow Away Zone\nMonday - Friday\n8AM - 6PM",
      "Welcome to Downtown\nSpeed Limit 35\nNo Honking Zone",
    ];
    
    // Return a random mock text
    return mockTexts[DateTime.now().millisecond % mockTexts.length];
  }
}
