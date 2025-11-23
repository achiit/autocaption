class ApiConstants {
  // Gemini API
  static const String geminiApiKey = 'AIzaSyA66yKPqsNNG_I5AJ9W1_0UTNyRWrmScNU';
  static const String geminiUploadUrl =
      'https://generativelanguage.googleapis.com/upload/v1beta/files';
  static const String geminiFilesUrl =
      'https://generativelanguage.googleapis.com/v1beta/files';
  static const String geminiGenerateUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';

  // Server API
  static const String serverUrl = 'https://21coders-autocaption.hf.space';
  static const String uploadEndpoint = '/upload';
  static const String statusEndpoint = '/status';
  static const String downloadEndpoint = '/download';
  static const String templatesEndpoint = '/templates';
}
