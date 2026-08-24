import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/student_service.dart';
import '../models/etudiant.dart';
import 'student_details_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FD),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              decoration: const BoxDecoration(
                color: Color(0xFF0055E5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Espace Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Ajouter un étudiant'),
                      Tab(text: 'Vérifier solvabilité'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Tab content ─────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _AddStudentTab(),
                  _SolvabilityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 1 — Ajouter un étudiant
// ============================================================================
class _AddStudentTab extends StatefulWidget {
  const _AddStudentTab();

  @override
  State<_AddStudentTab> createState() => _AddStudentTabState();
}

class _AddStudentTabState extends State<_AddStudentTab> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _qrCodeCtrl    = TextEditingController();

  String? _selectedLevel;
  String? _selectedFiliereId;
  bool?   _isAffiliated; // true = Affilié, false = Non-affilié
  List<Map<String, dynamic>> _filieres = [];
  bool _loading         = false;
  bool _loadingFilieres = true;
  String? _error;
  String? _success;

  final _levels = ['L1', 'L2', 'L3', 'M1', 'M2'];

  @override
  void initState() {
    super.initState();
    _loadFilieres();
  }

  Future<void> _loadFilieres() async {
    try {
      final res = await Supabase.instance.client
          .from('filieres')
          .select('id, name');
      setState(() {
        _filieres = List<Map<String, dynamic>>.from(res);
        _loadingFilieres = false;
      });
    } catch (_) {
      setState(() => _loadingFilieres = false);
    }
  }

  Future<void> _submit() async {
    // ── Validation ─────────────────────────────────────────────
    // filiere_id NOT NULL en base → toujours obligatoire
    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty ||
        _studentIdCtrl.text.trim().isEmpty ||
        _selectedLevel == null ||
        _isAffiliated == null ||
        _selectedFiliereId == null) {
      setState(() =>
      _error = 'Veuillez remplir tous les champs obligatoires (*), y compris la filière et le statut.');
      return;
    }

    setState(() {
      _loading = true;
      _error   = null;
      _success = null;
    });

    try {
      final supabase     = Supabase.instance.client;
      final isAffiliated = _isAffiliated!;

      // ── Construction des données d'insertion ───────────────────
      final insertData = <String, dynamic>{
        'first_name': _firstNameCtrl.text.trim(),
        'last_name' : _lastNameCtrl.text.trim(),
        'student_id': _studentIdCtrl.text.trim(),
        'email'     : _emailCtrl.text.trim().isEmpty
            ? null
            : _emailCtrl.text.trim(),
        'phone'     : _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
        'level'     : _selectedLevel,
        'qr_code'   : _qrCodeCtrl.text.trim().isEmpty
            ? _studentIdCtrl.text.trim()
            : _qrCodeCtrl.text.trim(),
        'status'    : 'active',
      };

      // filiere_id toujours obligatoire (NOT NULL en base)
      insertData['filiere_id'] = _selectedFiliereId!;

      // ── Insertion de l'étudiant ────────────────────────────────
      final res = await supabase
          .from('students')
          .insert(insertData)
          .select('id')
          .single();

      // ── Génération automatique des tranches de scolarité ────────
      // Affilié    → 755 000 FCFA  (9 tranches)
      // Non-affilié → 1 200 000 FCFA (9 tranches)
      final studentId  = res['id'] as String;
      final totalFcfa  = isAffiliated ? '755 000' : '1 200 000';

      await StudentService().generateInstallments(
        studentId   : studentId,
        isAffiliated: isAffiliated,
      );

      // ── Réinitialisation du formulaire ─────────────────────────
      _firstNameCtrl.clear();
      _lastNameCtrl.clear();
      _emailCtrl.clear();
      _phoneCtrl.clear();
      _studentIdCtrl.clear();
      _qrCodeCtrl.clear();

      setState(() {
        _selectedLevel     = null;
        _selectedFiliereId = null;
        _isAffiliated      = null;
        _isAffiliated      = null;
        _success = 'Étudiant ajouté ! Scolarité de $totalFcfa FCFA générée automatiquement (9 tranches).';
      });
    } catch (e) {
      setState(() => _error = 'Erreur : ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _studentIdCtrl.dispose();
    _qrCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),

          if (_success != null) _Banner(message: _success!, isError: false),
          if (_error != null)   _Banner(message: _error!,   isError: true),

          const SizedBox(height: 8),

          // ── Info scolarité ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF0055E5).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF0055E5), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 12, color: Color(0xFF0D1B4B)),
                      children: [
                        TextSpan(
                          text: 'Scolarité auto-générée : ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: 'Affilié → '),
                        TextSpan(
                          text: '755 000 FCFA',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0055E5),
                          ),
                        ),
                        TextSpan(text: '  •  Non-affilié → '),
                        TextSpan(
                          text: '1 200 000 FCFA',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF39C12),
                          ),
                        ),
                        TextSpan(text: ' (9 tranches mensuelles)'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Informations personnelles',
            icon: Icons.person_outline,
            children: [
              _FormRow(
                children: [
                  Expanded(
                    child: _Field(
                      label: 'Prénom *',
                      controller: _firstNameCtrl,
                      hint: 'Ex: Amien',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      label: 'Nom *',
                      controller: _lastNameCtrl,
                      hint: 'Ex: Christ',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Field(
                label: 'Email',
                controller: _emailCtrl,
                hint: 'etudiant@upb.ci',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _Field(
                label: 'Téléphone',
                controller: _phoneCtrl,
                hint: '+225 07 00 00 00 00',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Informations académiques',
            icon: Icons.school_outlined,
            children: [
              _Field(
                label: 'Matricule *',
                controller: _studentIdCtrl,
                hint: 'Ex: UPB-2024-001',
    ),
     const SizedBox(height: 14),

              //  Statut d'affiliation
              _buildLabel('Statut d\'affiliation *'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isAffiliated      = true;
                        // On garde _selectedFiliereId s'il était déjà choisi
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _isAffiliated == true
                              ? const Color(0xFF0055E5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isAffiliated == true
                                ? const Color(0xFF0055E5)
                                : const Color(0xFFD1D5DB),
                            width: 1.5,
                          ),
                          boxShadow: _isAffiliated == true
                              ? [
                            BoxShadow(
                              color: const Color(0xFF0055E5).withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.school,
                              size: 22,
                              color: _isAffiliated == true
                                  ? Colors.white
                                  : const Color(0xFF0055E5),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Affilié',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: _isAffiliated == true
                                    ? Colors.white
                                    : const Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '755 000 FCFA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isAffiliated == true
                                    ? Colors.white70
                                    : const Color(0xFF0055E5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isAffiliated = false;
                        // filiere_id NOT NULL en base → on garde la sélection
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _isAffiliated == false
                              ? const Color(0xFFF39C12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isAffiliated == false
                                ? const Color(0xFFF39C12)
                                : const Color(0xFFD1D5DB),
                            width: 1.5,
                          ),
                          boxShadow: _isAffiliated == false
                              ? [
                            BoxShadow(
                              color: const Color(0xFFF39C12).withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_off_outlined,
                              size: 22,
                              color: _isAffiliated == false
                                  ? Colors.white
                                  : const Color(0xFFF39C12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Non-affilié',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: _isAffiliated == false
                                    ? Colors.white
                                    : const Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '1 200 000 FCFA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isAffiliated == false
                                    ? Colors.white70
                                    : const Color(0xFFF39C12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              //Filière — chips toujours visibles
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildLabel('Filière *'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0055E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Obligatoire',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF0055E5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _loadingFilieres
                  ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0055E5)))
                  : _filieres.isEmpty
                  ? Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFDC2626), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aucune filière disponible. Veuillez en créer une d\'abord.',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filieres.map((f) {
                  final id  = f['id'] as String;
                  final nom = f['name'] as String;
                  final sel = _selectedFiliereId == id;
                  return GestureDetector(
                    onTap: () => setState(() =>
                    _selectedFiliereId = sel ? null : id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF0055E5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF0055E5)
                              : const Color(0xFFD1D5DB),
                        ),
                        boxShadow: sel
                            ? [
                          BoxShadow(
                            color: const Color(0xFF0055E5)
                                .withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (sel)
                            const Padding(
                              padding: EdgeInsets.only(right: 5),
                              child: Icon(Icons.check,
                                  size: 13, color: Colors.white),
                            ),
                          Text(
                            nom,
                            style: TextStyle(
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF374151),
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),
              _buildLabel('Niveau *'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _levels.map((l) {
                  final sel = _selectedLevel == l;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedLevel = l),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF0055E5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF0055E5)
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                      child: Text(
                        l,
                        style: TextStyle(
                          color: sel ? Colors.white : const Color(0xFF374151),
                          fontWeight:
                          sel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _Field(
                label: 'QR Code (optionnel)',
                controller: _qrCodeCtrl,
                hint: 'Laisser vide = matricule utilisé',
              ),
            ],
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0055E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor: const Color(0xFF0055E5).withOpacity(0.4),
              ),
              child: _loading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_alt_1, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Ajouter l\'étudiant',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}


// TAB 2 — Vérifier solvabilité

class _SolvabilityTab extends StatefulWidget {
  const _SolvabilityTab();

  @override
  State<_SolvabilityTab> createState() => _SolvabilityTabState();
}

class _SolvabilityTabState extends State<_SolvabilityTab> {
  final _searchCtrl = TextEditingController();
  final StudentService _service = StudentService();

  List<Student> _results = [];
  bool _searching = false;
  bool _searched  = false;

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _searched  = false;
    });

    try {
      final res = await Supabase.instance.client
          .from('students')
          .select('*, filieres(*)')
          .or('first_name.ilike.%$query%,last_name.ilike.%$query%,student_id.ilike.%$query%');

      setState(() {
        _results   = (res as List).map((e) => Student.fromJson(e)).toList();
        _searching = false;
        _searched  = true;
      });
    } catch (_) {
      setState(() {
        _searching = false;
        _searched  = true;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF0055E5),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _search(),
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Nom, prénom ou numero matricule...',
                    hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                    prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF0055E5)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _search,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B4B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _searching
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: !_searched
              ? _EmptySearch()
              : _results.isEmpty
              ? const Center(
            child: Text('Aucun étudiant trouvé.',
                style: TextStyle(color: Colors.grey)),
          )
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _results.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 10),
            itemBuilder: (ctx, i) =>
                _SolvabilityCard(student: _results[i]),
          ),
        ),
      ],
    );
  }
}

//  Solvability card
class _SolvabilityCard extends StatefulWidget {
  final Student student;
  const _SolvabilityCard({required this.student});

  @override
  State<_SolvabilityCard> createState() => _SolvabilityCardState();
}

class _SolvabilityCardState extends State<_SolvabilityCard> {
  final StudentService _service = StudentService();

  bool?   _upToDate;
  double? _remaining;
  bool    _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final upToDate  = await _service.isStudentUpToDate(widget.student.id);
      final remaining = await _service.getRemainingAmount(widget.student.id);
      setState(() {
        _upToDate  = upToDate;
        _remaining = remaining;
        _loading   = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentDetailsScreen(studentId: s.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF0055E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    s.initials,
                    style: const TextStyle(
                      color: Color(0xFF0055E5),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF0D1B4B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${s.studentId}  •  ${s.filiereName ?? '-'}  •  ${s.level ?? '-'}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                    if (!_loading && _remaining != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          _upToDate == true
                              ? 'Aucun impayé'
                              : 'Reste : ${_remaining!.toInt()} FCFA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _upToDate == true
                                ? const Color(0xFF2ECC71)
                                : Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _loading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF0055E5)),
              )
                  : Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _upToDate == true
                      ? const Color(0xFF2ECC71).withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _upToDate == true
                          ? Icons.check_circle
                          : Icons.warning_rounded,
                      size: 14,
                      color: _upToDate == true
                          ? const Color(0xFF2ECC71)
                          : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _upToDate == true ? 'À jour' : 'IMPAYÉ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _upToDate == true
                            ? const Color(0xFF2ECC71)
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Helpers

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0055E5), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D1B4B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  final List<Widget> children;
  const _FormRow({required this.children});

  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscure;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B4B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: Color(0xFF0055E5), width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}

Widget _buildLabel(String label) {
  return Text(
    label,
    style: const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 12,
      color: Color(0xFF374151),
      letterSpacing: 0.5,
    ),
  );
}

InputDecoration _dropdownDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF0055E5), width: 1.8),
    ),
  );
}

class _Banner extends StatelessWidget {
  final String message;
  final bool isError;

  const _Banner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isError
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError
                ? const Color(0xFFDC2626)
                : const Color(0xFF059669),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF059669),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0055E5).withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.manage_search,
                size: 48, color: Color(0xFF0055E5)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recherchez un étudiant',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D1B4B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Par nom, prénom ou matricule',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}