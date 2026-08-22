import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// --- LOGIC IMPORTS ---
import 'data/finance_repository.dart';
import 'viewmodels/main_viewmodel.dart';
import 'utils/notification_service.dart';

// --- SCREEN IMPORTS ---
import 'screens/home_screen.dart';
import 'screens/add_entry_screen.dart';
import 'screens/advanced_dashboard.dart';
import 'screens/history_screen.dart';
import 'screens/add_goal_screen.dart';
import 'screens/chatbot_screen.dart';

// --- GLOBAL KEYS ---
// These allow us to control the app from anywhere (e.g., show a snackbar from logic)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  // 1. Safe Execution Zone
  // Catches errors that happen outside the widget tree (like asynchronous crashes)
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await NotificationService().init();
      await NotificationService().requestPermissions();
      await NotificationService().scheduleDailyReminder();
      await NotificationService().scheduleHourlyReminder();
    } catch (e) {
      debugPrint("Failed to initialize notifications: $e");
    }

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
        Provider<FinanceRepository>(
          create: (_) => FinanceRepository(),
        ),
        ChangeNotifierProxyProvider<FinanceRepository, MainViewModel>(
          create: (context) => MainViewModel(
            Provider.of<FinanceRepository>(context, listen: false)
          )..loadData(),
          update: (context, repo, previous) => previous ?? MainViewModel(repo)..loadData(),
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
    // High-Contrast Pro Cyberpunk Palette
    const primaryColor = Color(0xFF818CF8); // Indigo 400 (High luminance)
    const secondaryColor = Color(0xFF34D399); // Emerald 400 (High luminance)
    const backgroundColor = Color(0xFF080C14); // Deep Midnight Black
    const surfaceColor = Color(0xFF151D2C); // High-Contrast Slate Surface
    const errorColor = Color(0xFFF43F5E); // Rose 500 (Vivid alert)

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

      // High-Contrast Professional Typography
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -1.0,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xFFE2E8F0), fontWeight: FontWeight.w500),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFCBD5E1)),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
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
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),

      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155), width: 1.2), // High-contrast border
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIconColor: primaryColor,
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1.2,
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
      case '/add_entry':
        return _createRoute(const AddEntryScreen());
      case '/advanced':
      case '/dashboard':
      case '/analytics':
        return _createRoute(const AdvancedDashboard());
      case '/history':
        return _createRoute(const HistoryScreen());
      case '/add-goal':
      case '/add_goal':
      case '/goals':
        return _createRoute(const AddGoalScreen());
      case '/chat':
        return _createRoute(const ChatbotScreen());
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

