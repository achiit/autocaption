import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants/api_constants.dart';
import '../models/caption_model.dart';

class GeminiService {
  /// Upload video file to Gemini (Resumable Upload)
  Future<String?> uploadVideo(File file) async {
    int fileSize = await file.length();
    String? mimeType = lookupMimeType(file.path) ?? 'video/mp4';
    String displayName = file.path.split('/').last;

    // 1. Start Resumable Upload
    final startUrl = Uri.parse(
      '${ApiConstants.geminiUploadUrl}?key=${ApiConstants.geminiApiKey}',
    );
    final startResponse = await http.post(
      startUrl,
      headers: {
        'X-Goog-Upload-Protocol': 'resumable',
        'X-Goog-Upload-Command': 'start',
        'X-Goog-Upload-Header-Content-Length': fileSize.toString(),
        'X-Goog-Upload-Header-Content-Type': mimeType,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'file': {'display_name': displayName},
      }),
    );

    if (startResponse.statusCode != 200) {
      print('Start upload failed: ${startResponse.body}');
      throw Exception('Failed to start upload: ${startResponse.body}');
    }

    final uploadUrl = startResponse.headers['x-goog-upload-url'];
    if (uploadUrl == null) throw Exception('No upload URL received');

    // 2. Upload Bytes
    final bytes = await file.readAsBytes();

    final uploadResponse = await http.post(
      Uri.parse(uploadUrl),
      headers: {
        'X-Goog-Upload-Protocol': 'resumable',
        'X-Goog-Upload-Command': 'upload, finalize',
        'X-Goog-Upload-Offset': '0',
        'Content-Length': fileSize.toString(),
      },
      body: bytes,
    );

    if (uploadResponse.statusCode != 200) {
      print('Upload failed: ${uploadResponse.body}');
      throw Exception('Failed to upload video: ${uploadResponse.body}');
    }

    final json = jsonDecode(uploadResponse.body);
    return json['file']['uri'];
  }

  /// Poll for file processing status
  Future<void> pollFileState(String fileUri) async {
    final uriWithKey = Uri.parse('$fileUri?key=${ApiConstants.geminiApiKey}');

    while (true) {
      final response = await http.get(uriWithKey);
      if (response.statusCode != 200) {
        throw Exception("Failed to check file state: ${response.body}");
      }

      final json = jsonDecode(response.body);
      final state = json['state']; // e.g., PROCESSING, ACTIVE, FAILED

      if (state == 'ACTIVE') {
        break;
      } else if (state == 'FAILED') {
        throw Exception("Video processing failed");
      }

      await Future.delayed(const Duration(seconds: 2));
    }
  }

  /// Generate captions using Gemini
  Future<List<CaptionModel>> generateCaptions({
    required String fileUri,
    required String language,
  }) async {
    final model = GenerativeModel(
        model: 'gemini-flash-latest', apiKey: ApiConstants.geminiApiKey);

    String languagePrompt = language;
    if (language == 'Hinglish') {
      languagePrompt =
          "Hindi speech transcribed using English characters (Hinglish)";
    }

    final prompt =
        "Analyze the audio in this video and generate a transcript in $languagePrompt. "
        "You MUST return the output as a raw JSON list with no markdown formatting. "
        "The JSON objects must represent caption segments and have the following structure: "
        "{'text': 'Full segment text', 'start': 'MM:SS:mmm', 'end': 'MM:SS:mmm', "
        "'words': [{'word': 'Word', 'start': 'MM:SS:mmm', 'end': 'MM:SS:mmm'}, ...]}. "
        "Ensure 'start' and 'end' are in 'MM:SS:mmm' format (e.g., 00:01:500). "
        "Keep segments short (3-5 words in a single line). "
        "Example: [{'text': 'Hello world', 'start': '00:00:000', 'end': '00:01:000', 'words': [{'word': 'Hello', 'start': '00:00:000', 'end': '00:00:500'}, {'word': 'world', 'start': '00:00:500', 'end': '00:01:000'}]}]";

    final content = [
      Content.multi([
        TextPart(prompt),
        FilePart(Uri.parse(fileUri)),
      ]),
    ];

    final response = await model.generateContent(content);
    final text = response.text;

    if (text == null) throw Exception("No response from Gemini");

    // Clean up potential markdown code blocks
    String cleanText =
        text.replaceAll('```json', '').replaceAll('```', '').trim();

    try {
      final List<dynamic> jsonList = jsonDecode(cleanText);

      // Map to CaptionModel
      return jsonList.map((json) {
        return CaptionModel(
          text: json['text'] ?? '',
          start: json['start'] ?? '00:00:000',
          end: json['end'] ?? '00:00:000',
          words: (json['words'] as List<dynamic>?)
                  ?.map((w) => WordModel(
                        word: w['word'] ?? '',
                        start: w['start'] ?? '00:00:000',
                        end: w['end'] ?? '00:00:000',
                      ))
                  .toList() ??
              [],
        );
      }).toList();
    } catch (e) {
      print("JSON Parse Error: $text");
      throw Exception("Failed to parse captions: $e");
    }
  }
}
