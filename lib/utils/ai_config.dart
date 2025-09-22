
import 'package:aiassistant1/services/remote-config-service.dart';

class AIConfig {
  // Get model name from Remote Config, fallback to default if not available
  static String get modelName {
    try {
      final remoteConfig = RemoteConfigService();
      final model = remoteConfig.remoteConfig.getString('gemini_model');
      // Return the model from Remote Config if it's not empty, otherwise fallback
      return model.isNotEmpty ? model : 'gemini-1.5-flash';
    } catch (e) {
      // Fallback to default model if Remote Config fails
      return 'gemini-1.5-flash';
    }
  }
  
  // Method to get current model name (useful for debugging)
  static String getCurrentModelName() {
    return modelName;
  }
  
  static const int requestTimeoutSeconds = 30;
  static const int connectionTestTimeoutSeconds = 10;
  
  // API endpoints for debugging
  static const String baseUrl = 'https://generativelanguage.googleapis.com';
  static const String apiVersion = 'v1beta';
  
  // Validation method
  static bool isValidApiKey(String key) {
    return key.isNotEmpty && key.startsWith('AIza') && key.length > 30;
  }
}


