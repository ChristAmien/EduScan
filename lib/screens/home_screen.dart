import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/student_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StudentService _service = StudentService();

  int _totalStudents = 0;
  int _upToDateCount = 0;
  int _lateCount = 0;
  int _incompleteCount = 0;
  List<Map<String, dynamic>> _filieres = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final supabase = Supabase.instance.client;

      // Total students
      final studentsRes = await supabase
          .from('students')
          .select('id, student_id, filieres(id, name)')
          .order('first_name');

      final students = studentsRes as List;
      _totalStudents = students.length;

      // Installment statuses
      int upToDate = 0;
      int late = 0;
      int incomplete = 0;

      for (final s in students) {
        final isUpToDate = await _service.isStudentUpToDate(s['id']);
        final remaining = await _service.getRemainingAmount(s['id']);
        if (isUpToDate) {
          upToDate++;
        } else if (remaining > 0) {
          late++;
        } else {
          incomplete++;
        }
      }

      // Filieres with student counts per level
      final filieresRes = await supabase
          .from('filieres')
          .select('id, name, icon_url');

      List<Map<String, dynamic>> filieresData = [];
      for (final f in filieresRes as List) {
        final fStudents = students
            .where((s) => s['filieres']?['id'] == f['id'])
            .toList();

        final l1 = fStudents.where((s) => s['level'] == 'L1').length;
        final l2 = fStudents.where((s) => s['level'] == 'L2').length;
        final l3 = fStudents.where((s) => s['level'] == 'L3').length;

        filieresData.add({
          'id': f['id'],
          'name': f['name'],
          'total': fStudents.length,
          'l1': l1,
          'l2': l2,
          'l3': l3,
        });
      }

      if (mounted) {
        setState(() {
          _upToDateCount = upToDate;
          _lateCount = late;
          _incompleteCount = incomplete;
          _filieres = filieresData;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        user?.userMetadata?['full_name'] ?? user?.email ?? 'Admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FD),
      body: SafeArea(
        child: Column(
          children: [
            // ── Blue header ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(
                color: Color(0xFF0055E5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: logo + profile
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.school,
                                  color: Color(0xFF0055E5), size: 26),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EduScan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Tableau de bord',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Avatar / Profile
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/settings'),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 26),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Tableau de bord',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stat cards row
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.people_alt_outlined,
                        label: 'Total',
                        value: _loading ? '—' : '$_totalStudents',
                        color: const Color(0xFF4D8BFF),
                        bgColor: Colors.white.withOpacity(0.15),
                        textColor: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        icon: Icons.check_circle,
                        label: 'À jour',
                        value: _loading ? '—' : '$_upToDateCount',
                        color: const Color(0xFF2ECC71),
                        bgColor: Colors.white.withOpacity(0.15),
                        textColor: Colors.white,
                        iconBg: const Color(0xFF2ECC71),
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        icon: Icons.access_time,
                        label: 'En retard',
                        value: _loading ? '—' : '$_lateCount',
                        color: Colors.orange,
                        bgColor: Colors.white.withOpacity(0.15),
                        textColor: Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        icon: Icons.person_off_outlined,
                        label: 'Incomplet',
                        value: _loading ? '—' : '$_incompleteCount',
                        color: Colors.purpleAccent,
                        bgColor: Colors.white.withOpacity(0.15),
                        textColor: Colors.purpleAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Scrollable body ──────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF0055E5)))
                  : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scanner button
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, '/scanner'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1B4B),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D1B4B)
                                  .withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0055E5),
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                  Icons.document_scanner_outlined,
                                  color: Colors.white,
                                  size: 22),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Scanner un étudiant',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios,
                                color: Colors.white54, size: 16),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Filières section
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filières',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D1B4B),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Voir toutes >',
                            style: TextStyle(
                              color: Color(0xFF0055E5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Filières grid
                    if (_filieres.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Aucune filière trouvée',
                              style:
                              TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        itemCount: _filieres.length,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.05,
                        ),
                        itemBuilder: (ctx, i) =>
                            _FiliereCard(filiere: _filieres[i]),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Bottom nav ────────────────────────────────────────────────
      bottomNavigationBar: _BottomNav(
        activeIndex: 0,
        onTap: (i) {
          if (i == 1) Navigator.pushNamed(context, '/admin');
          if (i == 2) Navigator.pushNamed(context, '/scanner');
          if (i == 4) Navigator.pushNamed(context, '/settings');
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Stat card (in header)
// ────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final Color textColor;
  final Color? iconBg;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.textColor,
    this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border:
          Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBg ?? color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: iconBg != null ? Colors.white : color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Filière card
// ────────────────────────────────────────────────────────────────────────────
class _FiliereCard extends StatelessWidget {
  final Map<String, dynamic> filiere;

  const _FiliereCard({required this.filiere});

  static const _colors = [
    Color(0xFF0055E5),
    Color(0xFF2ECC71),
    Color(0xFFF39C12),
    Color(0xFF9B59B6),
    Color(0xFFE74C3C),
  ];

  @override
  Widget build(BuildContext context) {
    final idx = (filiere['name'] as String).codeUnitAt(0) % _colors.length;
    final color = _colors[idx];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + name
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.school_outlined, color: color, size: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  filiere['name'],
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Level stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LevelBadge(level: 'L1', count: filiere['l1']),
              _LevelBadge(level: 'L2', count: filiere['l2']),
              _LevelBadge(level: 'L3', count: filiere['l3']),
            ],
          ),

          const Spacer(),

          // Total
          Row(
            children: [
              const Icon(Icons.people, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${filiere['total']} étudiants  >',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String level;
  final int count;

  const _LevelBadge({required this.level, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(level,
            style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text('$count',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D1B4B))),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Bottom nav bar (shared)
// ────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.activeIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, 'Accueil'),
      (Icons.folder_outlined, 'Dossier'),
      (Icons.qr_code_scanner, 'Scanner'),
      (Icons.notifications_outlined, 'Notifications'),
      (Icons.person_outline, 'Profil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = i == activeIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    active
                        ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0055E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF0055E5)
                                .withOpacity(0.3),
                            width: 1.5),
                      ),
                      child: Icon(items[i].$1,
                          size: 22, color: const Color(0xFF0055E5)),
                    )
                        : Icon(items[i].$1,
                        size: 22, color: Colors.grey.shade500),
                    const SizedBox(height: 4),
                    Text(
                      items[i].$2,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                        color: active
                            ? const Color(0xFF0055E5)
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}