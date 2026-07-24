// ──────────────────────────────────────────────────────────────────────────────
// lead.dart — Lead Data Model
// One Lead = one row submitted from the public form.
// ──────────────────────────────────────────────────────────────────────────────

class Lead {
  final int id;
  final String name;
  final String email;
  final String budgetRange;
  final String message;
  final String status;       // 'New', 'Contacted', or 'Closed'
  final DateTime createdAt;

  const Lead({
    required this.id,
    required this.name,
    required this.email,
    required this.budgetRange,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  // Convert JSON from the API response into a Lead object
  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id:          json['id'] as int,
      name:        json['name'] as String,
      email:       json['email'] as String,
      budgetRange: json['budget_range'] as String,
      message:     json['message'] as String,
      status:      json['status'] as String,
      createdAt:   DateTime.parse(json['created_at'] as String),
    );
  }

  // Returns the next status in the cycle: New → Contacted → Closed → New
  String get nextStatus {
    switch (status) {
      case 'New':       return 'Contacted';
      case 'Contacted': return 'Closed';
      default:          return 'New';
    }
  }

  // Returns a readable date like "Jul 24, 2025"
  String get formattedDate {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final d = createdAt.toLocal();
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  // The 4 budget options shown in the dropdown
  static const List<String> budgetRanges = [
    r'< $1,000',
    r'$1,000 – $5,000',
    r'$5,000 – $20,000',
    r'$20,000+',
  ];
}
