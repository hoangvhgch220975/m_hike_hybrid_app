import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'views/splash/splash.dart';
import 'viewmodels/hike_viewmodel.dart';
import 'viewmodels/observation_viewmodel.dart';
import 'viewmodels/media_viewmodel.dart';
import 'viewmodels/map_viewmodel.dart';
import 'viewmodels/weather_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  final themeModel = ThemeViewModel();
  await themeModel.loadTheme();

  runApp(MyApp(themeModel: themeModel));
}

class MyApp extends StatelessWidget {
  final ThemeViewModel themeModel;

  const MyApp({super.key, required this.themeModel});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeModel),
        ChangeNotifierProvider(create: (_) => HikeViewModel()),
        ChangeNotifierProvider(create: (_) => ObservationViewModel()),
        ChangeNotifierProvider(create: (_) => MediaViewModel()),
        ChangeNotifierProvider(create: (_) => MapViewModel()),
        ChangeNotifierProvider(create: (_) => WeatherViewModel()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, theme, child) {
          // Build base themes from the Material defaults to ensure matching TextTheme
          final lightBase = ThemeData.light();
          final darkBase = ThemeData.dark();

          // Define a green primary color for the app (used for highlights)
          const primaryGreen = Color(0xFF2E7D32); // similar to old green

          final lightTheme = ThemeData(
            brightness: Brightness.light,
            fontFamily: 'PlusJakartaSans',
            colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen, brightness: Brightness.light),
            primaryColor: primaryGreen,
          ).copyWith(
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            textTheme: lightBase.textTheme.apply(bodyColor: Colors.black),
            appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, iconTheme: IconThemeData(color: Colors.black87)),
            floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: primaryGreen, foregroundColor: Colors.white),
          );

          final darkTheme = ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'PlusJakartaSans',
            colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen, brightness: Brightness.dark),
            primaryColor: primaryGreen,
          ).copyWith(
            scaffoldBackgroundColor: Colors.black,
            cardColor: const Color(0xFF1E1E1E),
            iconTheme: const IconThemeData(color: Colors.white),
            textTheme: darkBase.textTheme.apply(bodyColor: Colors.white),
            appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, iconTheme: IconThemeData(color: Colors.white)),
            floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: primaryGreen, foregroundColor: Colors.white),
          );

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: theme.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
