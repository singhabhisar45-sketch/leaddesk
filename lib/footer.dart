// ──────────────────────────────────────────────────────────────────────────────
// footer.dart — App footer with required credit line
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  Future<void> _openLink() async {
    final url = Uri.parse('https://digitalheroesco.com');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2A2A45))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: Column(
        children: [
          Text('LeadDesk Mini',
              style: GoogleFonts.inter(
                  color: const Color(0xFF6C63FF),
                  fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          // Required credit line — tapping opens digitalheroesco.com
          GestureDetector(
            onTap: _openLink,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Text.rich(
                TextSpan(
                  text: 'Built for ',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF6060A0), fontSize: 12),
                  children: [
                    TextSpan(
                      text: 'Digital Heroes Training Task',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6C63FF),
                        fontSize: 12, fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: const Color(0xFF6C63FF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('Flutter Web  ·  Go  ·  PostgreSQL',
              style: GoogleFonts.inter(
                  color: const Color(0xFF404060), fontSize: 11)),
        ],
      ),
    );
  }
}
