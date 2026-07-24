import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'landing_page.dart';   // lib/landing_page.dart
import 'admin_page.dart';     // lib/admin_page.dart

void main() {
  runApp(const LeadDeskApp());
}

// ── Router: maps URLs to screens ─────────────────────────────────────────────
// "/"      → LandingPage  (public form)
// "/admin" → AdminPage    (password-protected dashboard)
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminPage(),
    ),
  ],
);

// ── Root app widget ───────────────────────────────────────────────────────────
class LeadDeskApp extends StatelessWidget {
  const LeadDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LeadDesk Mini',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
          primary: const Color(0xFF6C63FF),
          surface: const Color(0xFF1A1A2E),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E32),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A2A45)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF9090B0)),
          hintStyle: const TextStyle(color: Color(0xFF6060A0)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
