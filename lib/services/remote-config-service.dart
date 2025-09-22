import 'dart:developer' as dp;
import 'package:aiassistant1/utils/app_strings.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();

  factory RemoteConfigService() {
    // Purchases.setEmail(email)
    return _instance;
  }

  RemoteConfigService._internal();

  final remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    try {
      await GetRemoteConfig();
      await SetRemoteConfig();

      remoteConfig.onConfigUpdated.listen((event) async {
        print("Remote Updated");
        await remoteConfig.activate();
        await SetRemoteConfig();
      });
    } catch (e) {
      print("Remote Config initialization error: $e");
      // Set default values if remote config fails
      AppStrings.gemini_model = "gemini-2.0-flash";
    }
  }

  Future GetRemoteConfig() async {
    try {
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(seconds: 1),
        ),
      );

      await remoteConfig.setDefaults(const {
        "gemini_model": "gemini-2.0-flash",
      });
      await remoteConfig.fetchAndActivate();
    } on Exception catch (e) {
      // TODO
      print("Remote Config error: $e");
    }
  }

  Future SetRemoteConfig() async {
    try {
      AppStrings.gemini_model = remoteConfig.getString('gemini_model');
      dp.log("Gemini model set to: ${AppStrings.gemini_model}");
    } catch (e) {
      print("Error setting remote config: $e");
      AppStrings.gemini_model = "gemini-2.0-flash"; // fallback
    }
  }
}
