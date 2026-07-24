// ──────────────────────────────────────────────────────────────────────────────
// admin_page.dart — Admin dashboard (password protected)
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lead.dart';
import 'api_service.dart';
import 'status_chip.dart';
import 'footer.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // ── Auth ────────────────────────────────────────────────────────────────────
  static const String _password = 'admin1234'; // change before going live!
  bool _authenticated = false;
  String? _authErrorMsg;
  bool _showPassword = false;
  bool _isLoggingIn = false;
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkExistingToken();
  }

  Future<void> _checkExistingToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      ApiService.jwtToken = token;
      setState(() => _authenticated = true);
      _loadLeads();
    }
  }

  // ── Leads ───────────────────────────────────────────────────────────────────
  List<Lead> _leads = [];
  bool _isLoading = false;
  String? _loadError;
  final _searchCtrl = TextEditingController();
  final Set<int> _updatingIds = {}; // leads currently being updated

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // Load leads from backend (optionally filtered by search)
  Future<void> _loadLeads({String search = ''}) async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final leads = await ApiService.getLeads(search: search);
      if (mounted) {
        setState(() => _leads = leads);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _loadError = e.message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    ApiService.jwtToken = null;
    setState(() {
      _authenticated = false;
      _leads = [];
      _passwordCtrl.clear();
    });
  }

  Future<void> _authenticate() async {
    setState(() {
      _isLoggingIn = true;
      _authErrorMsg = null;
    });
    try {
      await ApiService.login(_passwordCtrl.text);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', ApiService.jwtToken!);
      if (mounted) {
        setState(() => _authenticated = true);
        _loadLeads();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _authErrorMsg = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  Future<void> _toggleStatus(Lead lead) async {
    setState(() => _updatingIds.add(lead.id));
    try {
      final updated = await ApiService.updateStatus(lead.id, lead.nextStatus);
      if (mounted) {
        setState(() {
          final i = _leads.indexWhere((l) => l.id == lead.id);
          if (i != -1) {
            _leads[i] = updated;
          }
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: const Color(0xFFFF6B6B),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingIds.remove(lead.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      _authenticated ? _buildDashboard() : _buildPasswordScreen();

  // ── Password screen ─────────────────────────────────────────────────────────
  Widget _buildPasswordScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/back.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Color(0xB3000000), BlendMode.darken),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF9C64FF)],
                      ),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Admin Access',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your password to continue',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6060A0),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2A2A45)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_authErrorMsg != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFF6B6B,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                  0xFFFF6B6B,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFFF6B6B),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _authErrorMsg!,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFFF6B6B),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          'Password',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF9090B0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: !_showPassword,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (_) => _authenticate(),
                          decoration: InputDecoration(
                            hintText: 'Enter admin password',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFF6060A0),
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF6060A0),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoggingIn ? null : _authenticate,
                      child: _isLoggingIn 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Access Dashboard'),
                    ),
                  ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: Text(
                      '← Back to public page',
                      style: GoogleFonts.inter(color: const Color(0xFF6060A0)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Dashboard ───────────────────────────────────────────────────────────────
  Widget _buildDashboard() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/back.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Color(0xB3000000), BlendMode.darken),
          ),
        ),
        child: Column(
          children: [
            _buildTopBar(),
            _buildStatsRow(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [_buildLeadList(), const AppFooter()]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A45))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered Logo & Admin Badge
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFF6C63FF),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'LeadDesk',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Admin',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF9C8EFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right-aligned actions (Search + Refresh + View Public)
          Positioned(
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (val) => _loadLeads(search: val),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF6060A0),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF6060A0),
                        size: 18,
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF6060A0),
                                size: 16,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                _loadLeads();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _loadLeads(search: _searchCtrl.text),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF6060A0),
                  ),
                  tooltip: 'Refresh',
                ),
                IconButton(
                  onPressed: () => context.go('/'),
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    color: Color(0xFF6060A0),
                  ),
                  tooltip: 'View public page',
                ),
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFF6060A0),
                  ),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final total = _leads.length;
    final newCount = _leads.where((l) => l.status == 'New').length;
    final contacted = _leads.where((l) => l.status == 'Contacted').length;
    final closed = _leads.where((l) => l.status == 'Closed').length;
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              'Total',
              total.toString(),
              Icons.people_outline_rounded,
              const Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              'New',
              newCount.toString(),
              Icons.fiber_new_rounded,
              const Color(0xFF64B5F6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              'Contacted',
              contacted.toString(),
              Icons.mark_email_read_rounded,
              const Color(0xFF81C784),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              'Closed',
              closed.toString(),
              Icons.check_circle_rounded,
              const Color(0xFFEF9A9A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A45)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF6060A0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeadList() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _searchCtrl.text.isEmpty
                    ? 'All Leads'
                    : 'Results for "${_searchCtrl.text}"',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              if (_leads.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_leads.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF9090B0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
              ),
            )
          else if (_loadError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFFF6B6B),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _loadError!,
                      style: GoogleFonts.inter(color: const Color(0xFFFF6B6B)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadLeads,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_leads.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.inbox_rounded,
                        color: Color(0xFF6060A0),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchCtrl.text.isEmpty
                          ? 'No leads yet'
                          : 'No leads match',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _searchCtrl.text.isEmpty
                          ? 'Leads submitted on the public page will appear here.'
                          : 'Try a different search term.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6060A0),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Column(children: _leads.map(_buildLeadCard).toList()),
        ],
      ),
    );
  }

  Widget _buildLeadCard(Lead lead) {
    final updating = _updatingIds.contains(lead.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF9C64FF)],
                  ),
                ),
                child: Center(
                  child: Text(
                    lead.name.isNotEmpty ? lead.name[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      lead.email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6060A0),
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Tap to mark as ${lead.nextStatus}',
                child: StatusChip(
                  status: lead.status,
                  isLoading: updating,
                  onTap: () => _toggleStatus(lead),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF13132A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E1E3A)),
            ),
            child: Text(
              lead.message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF9090B0),
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _meta(
                Icons.attach_money_rounded,
                lead.budgetRange,
                const Color(0xFF03DAC6),
              ),
              _meta(
                Icons.access_time_rounded,
                lead.formattedDate,
                const Color(0xFF9090B0),
              ),
              _meta(Icons.tag_rounded, '#${lead.id}', const Color(0xFF6060A0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(text, style: GoogleFonts.inter(fontSize: 12, color: color)),
    ],
  );
}
