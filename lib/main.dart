import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// --- LOGIC IMPORTS ---
import 'logic/finance_provider.dart';

// --- SCREEN IMPORTS ---
import 'screens/home_screen.dart';
import 'screens/add_entry_screen.dart';
import 'screens/advanced_dashboard.dart';
import 'screens/history_screen.dart';
import 'screens/add_goal_screen.dart';

// --- GLOBAL KEYS ---
// These allow us to control the app from anywhere (e.g., show a snackbar from logic)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  // 1. Safe Execution Zone
  // Catches errors that happen outside the widget tree (like asynchronous crashes)
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 2. UX Optimization: Lock Orientation
    // Finance apps are best viewed in Portrait mode on phones
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 3. UX Optimization: Edge-to-Edge Design
    // Makes the status bar transparent so your background gradient flows through
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // For dark backgrounds
      systemNavigationBarColor: Color(0xFF0F172A), // Matches our scaffold background
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    runApp(const FinanceProApp());
  }, (error, stack) {
    // In a real pro app, you would send this to Sentry or Firebase Crashlytics
    debugPrint("CRITICAL APP ERROR: $error");
    debugPrint(stack.toString());
  });
}

class FinanceProApp extends StatelessWidget {
  const FinanceProApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 4. State Injection
    // Using MultiProvider allows you to easily add Auth or Settings providers later
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FinanceProvider()..loadData(),
        ),
      ],
      child: MaterialApp(
        title: 'Vinit Finance AI',
        debugShowCheckedModeBanner: false, // Hides the 'Debug' banner for a cleaner look

        // --- GLOBAL KEYS LINKING ---
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,

        // --- THEME ENGINE ---
        themeMode: ThemeMode.dark, // Enforcing the "Pro" Dark Mode look
        theme: _buildLightTheme(), // Fallback (not active in this config)
        darkTheme: _buildDarkTheme(),

        // --- NAVIGATION ENGINE ---
        initialRoute: '/',
        onGenerateRoute: RouteGenerator.generateRoute,

        // --- TRANSITIONS ---
        // Adds smooth sliding animations between screens
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false),
            child: child!,
          );
        },
      ),
    );
  }

  // --- THEME DEFINITIONS ---

  ThemeData _buildDarkTheme() {
    // "Slate & Indigo" Cyberpunk Palette
    const primaryColor = Color(0xFF6366F1); // Indigo 500
    const secondaryColor = Color(0xFF10B981); // Emerald 500
    const backgroundColor = Color(0xFF0F172A); // Slate 900
    const surfaceColor = Color(0xFF1E293B); // Slate 800
    const errorColor = Color(0xFFEF4444); // Red 500

    final baseTheme = ThemeData.dark(useMaterial3: true);

    return baseTheme.copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,

      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onSurface: Colors.white,
        onPrimary: Colors.white,
      ),

      // Professional Typography
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -1.0,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
      ),

      // Component Styling
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),

      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Modern rounded corners
          side: BorderSide(color: Colors.white.withAlpha(13), width: 1), // Subtle border
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withAlpha(13)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.white.withAlpha(128)),
        prefixIconColor: Colors.white.withAlpha(128),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withAlpha(26),
        thickness: 1,
      ),
    );
  }

  // Fallback theme (kept minimal since we force Dark Mode)
  ThemeData _buildLightTheme() {
    return ThemeData.light(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
    );
  }
}

// --- ROUTE GENERATOR ---
// This separates navigation logic from UI code, keeping things clean.
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // We can pass arguments via settings.arguments if needed

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/home':
        return _createRoute(const HomeScreen());
      case '/add':
        return _createRoute(const AddEntryScreen());
      case '/advanced':
        return _createRoute(const AdvancedDashboard());
      case '/history':
        return _createRoute(const HistoryScreen());
      case '/add-goal':
        return _createRoute(const AddGoalScreen());
      default:
        return _errorRoute();
    }
  }

  // Custom Transition: Slide Up for new screens (iOS style feel)
  static PageRouteBuilder _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05); // Slight shift from bottom
        const end = Offset.zero;
        const curve = Curves.easeOutQuint; // Professional snappy feel

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
    );
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Navigation Error: Page not found')),
      );
    });
  }
}

// --- SPLASH SCREEN ---
// A micro-widget that handles initial data loading gracefully
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Simulate startup check (or wait for Provider to load DB)
    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pro Icon Placeholder (Using standard icon but styled)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_graph,
                  size: 64,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "FINANCE AI",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Smart Money Management",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

