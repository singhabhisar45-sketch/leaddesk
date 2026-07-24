// ──────────────────────────────────────────────────────────────────────────────
// landing_page.dart — Public page with the lead capture form
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'lead.dart';
import 'api_service.dart';
import 'footer.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController    = TextEditingController();
  final _emailController   = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedBudget;

  bool _isSubmitting = false;
  bool _submitted    = false;
  String? _serverError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ── Validators (null = valid, string = error message) ──────────────────────
  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your name';
    if (v.trim().length < 2)  return 'Name must be at least 2 characters';
    if (v.trim().length > 100) return 'Name is too long';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateBudget(String? v) {
    if (v == null || v.isEmpty) return 'Please select a budget range';
    return null;
  }

  String? _validateMessage(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please write a message';
    if (v.trim().length < 10)   return 'At least 10 characters required';
    if (v.trim().length > 2000) return 'Maximum 2000 characters';
    return null;
  }

  // ── Form submit ─────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ApiService.submitLead(
        name:        _nameController.text.trim(),
        email:       _emailController.text.trim(),
        budgetRange: _selectedBudget!,
        message:     _messageController.text.trim(),
      );
      setState(() => _submitted = true);
    } on ApiException catch (e) {
      setState(() => _serverError = e.message);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/back.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Color(0xB3000000), BlendMode.darken),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [_buildHero(), _buildFormSection(), const AppFooter()],
          ),
        ),
      ),
    );
  }

  // ── Hero banner ─────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nav
          Stack(
            alignment: Alignment.center,
            children: [
              // This SizedBox forces the Stack to stretch across the whole screen
              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF9C64FF)]),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('LeadDesk', style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                child: TextButton.icon(
                  onPressed: () => context.go('/admin'),
                  icon: const Icon(Icons.admin_panel_settings_outlined,
                      size: 16, color: Color(0xFF6C63FF)),
                  label: Text('Admin', style: GoogleFonts.inter(
                      color: const Color(0xFF6C63FF))),
                ),
              ),
            ],
          ),

          const SizedBox(height: 60),

          Text('Turn visitors into\nreal opportunities',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white,
                  height: 1.2, letterSpacing: -1)),
          const SizedBox(height: 16),
          Text('Share your project details and we\'ll get back to you within 24 hours.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 16, color: const Color(0xFF9090B0), height: 1.6)),
          const SizedBox(height: 40),

          // Stats
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 40, runSpacing: 16,
            children: [
              _stat('500+', 'Projects delivered'),
              _stat('< 24h', 'Response time'),
              _stat('98%',   'Client satisfaction'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String number, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(number, style: GoogleFonts.inter(
          fontSize: 26, fontWeight: FontWeight.w800,
          color: const Color(0xFF6C63FF))),
      Text(label, style: GoogleFonts.inter(
          fontSize: 13, color: const Color(0xFF6060A0))),
    ],
  );

  // ── Form section ─────────────────────────────────────────────────────────────
  Widget _buildFormSection() {
    return Container(
      width: double.infinity, color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _submitted ? _buildSuccessCard() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      key: const ValueKey('success'),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00C853).withValues(alpha: 0.12),
          ),
          child: const Icon(Icons.check_circle_outline_rounded,
              color: Color(0xFF81C784), size: 36),
        ),
        const SizedBox(height: 20),
        Text('We got your message! 🎉', style: GoogleFonts.inter(
            fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text("We'll review your inquiry and reach out within 24 hours.",
            style: GoogleFonts.inter(fontSize: 14,
                color: const Color(0xFF9090B0), height: 1.6),
            textAlign: TextAlign.center),
        const SizedBox(height: 28),
        OutlinedButton(
          onPressed: () {
            setState(() {
              _submitted = false; _serverError = null; _selectedBudget = null;
            });
            _nameController.clear();
            _emailController.clear();
            _messageController.clear();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6C63FF),
            side: const BorderSide(color: Color(0xFF6C63FF)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Submit another inquiry'),
        ),
      ]),
    );
  }

  Widget _buildForm() {
    return Container(
      key: const ValueKey('form'),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A45)),
      ),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Start your project', style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Fill in the details below — takes about 2 minutes',
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF6060A0))),
          const SizedBox(height: 28),

          // Server error banner
          if (_serverError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFFF6B6B), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_serverError!, style: GoogleFonts.inter(
                    color: const Color(0xFFFF6B6B), fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // Name
          _label('Full Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController, validator: _validateName,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'e.g. Jane Smith',
              prefixIcon: Icon(Icons.person_outline_rounded,
                  color: Color(0xFF6060A0), size: 20),
            ),
          ),
          const SizedBox(height: 18),

          // Email
          _label('Email Address'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController, validator: _validateEmail,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'e.g. jane@example.com',
              prefixIcon: Icon(Icons.email_outlined,
                  color: Color(0xFF6060A0), size: 20),
            ),
          ),
          const SizedBox(height: 18),

          // Budget dropdown
          _label('Budget Range'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedBudget,
            validator: _validateBudget,
            dropdownColor: const Color(0xFF1E1E32),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF6060A0)),
            decoration: const InputDecoration(
              hintText: 'Select your budget',
              prefixIcon: Icon(Icons.attach_money_rounded,
                  color: Color(0xFF6060A0), size: 20),
            ),
            items: Lead.budgetRanges
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (val) => setState(() => _selectedBudget = val),
          ),
          const SizedBox(height: 18),

          // Message
          _label('Project Description'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _messageController, validator: _validateMessage,
            maxLines: 5, style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Tell us about your project, goals, and timeline...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: ListenableBuilder(
              listenable: _messageController,
              builder: (_, _) => Text(
                '${_messageController.text.length} / 2000',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _messageController.text.length > 1800
                      ? const Color(0xFFFF6B6B) : const Color(0xFF404060),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Text('Send Inquiry  →'),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text('🔒  Your information is private and never shared',
              style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFF404060)))),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w600,
      color: const Color(0xFF9090B0)));
}
