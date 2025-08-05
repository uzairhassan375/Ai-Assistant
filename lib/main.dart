import 'package:aiassistant1/firebase_options.dart';
import 'package:aiassistant1/screens/home_screen.dart';
import 'package:aiassistant1/screens/user_registration/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:aiassistant1/services/notification_service.dart';
import 'package:aiassistant1/services/task_notification_service.dart';
import 'package:aiassistant1/services/task_notification_integration.dart';
import 'package:aiassistant1/services/settings_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize notification services with timezone support
  await NotificationService().init();
  await TaskNotificationService().initialize();
  
  // Initialize task notification integration
  await TaskNotificationIntegration().initialize();
  
  print('🚀 All notification services initialized successfully');
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  // Global navigator key for notifications
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Set the navigator key for notification service
    NotificationService.navigatorKey = navigatorKey;
    
    return Consumer<SettingsService>(
      builder: (context, settings, child) {
        return MaterialApp(
          navigatorKey: navigatorKey, // Add this line
          debugShowCheckedModeBanner: false,
          title: 'HelpMe',
          themeMode: settings.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(settings.fontScale)),
              child: child!,
            );
          },
          home: StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasData) {
                // User signed in - reinitialize task notification integration
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  TaskNotificationIntegration().reinitialize();
                });
                return const HomeScreen();
              } else {
                // User signed out - dispose task notification integration
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  TaskNotificationIntegration().dispose();
                });
                return const SignInPage();
              }
            },
          ),
        );
      },
    );
  }
}
