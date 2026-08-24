import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/etudiant.dart';
import '../models/installment.dart';
import '../services/student_service.dart';

class StudentDetailsScreen extends StatefulWidget {
  final String studentId;
  const StudentDetailsScreen({super.key, required this.studentId});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen>
    with SingleTickerProviderStateMixin {
  final StudentService _service = StudentService();

  Student?          _student;
  List<Installment> _installments = [];
  bool              _loading      = true;
  double            _remaining    = 0;
  bool              _upToDate     = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final s = await _service.getStudentById(widget.studentId);
      final i = await _service.getInstallments(widget.studentId);
      final r = await _service.getRemainingAmount(widget.studentId);
      final u = await _service.isStudentUpToDate(widget.studentId);
      setState(() {
        _student      = s;
        _installments = i;
        _remaining    = r;
        _upToDate     = u;
        _loading      = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  double get _totalScolarite =>
      _installments.fold(0, (s, e) => s + e.amount);
  double get _totalPaye =>
      _installments.fold(0, (s, e) => s + e.paidAmount);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7FD),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0055E5))),
      );
    }

    final s = _student;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FD),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(s),
            Container(
              color: const Color(0xFF0055E5),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: 'Dossier & Finances'),
                  Tab(text: 'Ajouter un paiement'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _DossierTab(
                    student: s,
                    installments: _installments,
                    totalScolarite: _totalScolarite,
                    totalPaye: _totalPaye,
                    remaining: _remaining,
                    upToDate: _upToDate,
                  ),
                  _PaymentTab(
                    student: s,
                    installments: _installments,
                    onPaymentDone: () async {
                      await _loadData();
                      _tabController.animateTo(0);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Student? s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(color: Color(0xFF0055E5)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    s?.initials ?? '??',
                    style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800,
                      color: Color(0xFF0055E5),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _upToDate ? const Color(0xFF2ECC71) : Colors.red.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _upToDate ? Icons.check_circle : Icons.warning_rounded,
                      color: Colors.white, size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _upToDate ? 'À jour' : 'IMPAYÉ',
                      style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s?.fullName ?? '',
            style: const TextStyle(
                color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            '${s?.studentId ?? ''}  •  ${s?.filiereName ?? '-'}  •  ${s?.level ?? '-'}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 1 — Dossier & Finances
// ============================================================================
class _DossierTab extends StatelessWidget {
  final Student?          student;
  final List<Installment> installments;
  final double            totalScolarite;
  final double            totalPaye;
  final double            remaining;
  final bool              upToDate;

  const _DossierTab({
    required this.student,
    required this.installments,
    required this.totalScolarite,
    required this.totalPaye,
    required this.remaining,
    required this.upToDate,
  });

  @override
  Widget build(BuildContext context) {
    final s = student;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),

          _Card(
            title: 'Informations personnelles',
            icon: Icons.person_outline,
            children: [
              _InfoRow(icon: Icons.badge_outlined,   label: 'Matricule',  value: s?.studentId ?? '-'),
              _InfoRow(icon: Icons.person,           label: 'Prénom',     value: s?.firstName ?? '-'),
              _InfoRow(icon: Icons.person,           label: 'Nom',        value: s?.lastName ?? '-'),
              _InfoRow(icon: Icons.email_outlined,   label: 'Email',      value: s?.email ?? '-'),
              _InfoRow(icon: Icons.phone_outlined,   label: 'Téléphone',  value: s?.phone ?? '-'),
            ],
          ),

          const SizedBox(height: 14),

          _Card(
            title: 'Informations académiques',
            icon: Icons.school_outlined,
            children: [
              _InfoRow(icon: Icons.account_tree_outlined, label: 'Filière', value: s?.filiereName ?? '-'),
              _InfoRow(icon: Icons.stairs_outlined,       label: 'Niveau',  value: s?.level ?? '-'),
              _InfoRow(icon: Icons.qr_code,               label: 'QR Code', value: s?.qrCode ?? '-'),
              _InfoRow(
                icon: Icons.circle, label: 'Statut', value: s?.status ?? '-',
                valueColor: s?.status == 'active' ? const Color(0xFF2ECC71) : Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── QR Card ──────────────────────────────────────────
          _QrCard(student: s),

          const SizedBox(height: 14),

          _Card(
            title: 'Résumé financier',
            icon: Icons.account_balance_wallet_outlined,
            children: [
              _FinanceRow(
                label: 'Scolarité totale',
                value: '${totalScolarite.toInt()} FCFA',
                color: const Color(0xFF0D1B4B),
                icon: Icons.school_outlined,
              ),
              const Divider(height: 20),
              _FinanceRow(
                label: 'Montant payé',
                value: '${totalPaye.toInt()} FCFA',
                color: const Color(0xFF2ECC71),
                icon: Icons.check_circle_outline,
              ),
              const Divider(height: 20),
              _FinanceRow(
                label: 'Reste à payer',
                value: '${remaining.toInt()} FCFA',
                color: remaining > 0 ? const Color(0xFFF39C12) : const Color(0xFF2ECC71),
                icon: remaining > 0 ? Icons.pending_outlined : Icons.done_all,
                bold: true,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: totalScolarite > 0
                      ? (totalPaye / totalScolarite).clamp(0.0, 1.0)
                      : 0,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation(
                    upToDate ? const Color(0xFF2ECC71) : const Color(0xFF0055E5),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${totalScolarite > 0 ? ((totalPaye / totalScolarite) * 100).toStringAsFixed(1) : '0.0'}% réglé',
                style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _Card(
            title: 'Échéances & transactions',
            icon: Icons.receipt_long_outlined,
            subtitle:
            '${installments.where((e) => e.isPaid).length}/${installments.length} tranche(s) réglée(s)',
            children: installments.isEmpty
                ? [
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aucune tranche enregistrée.',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            ]
                : installments.map((item) => _InstallmentRow(item: item)).toList(),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 2 — Ajouter un paiement
// ============================================================================
class _PaymentTab extends StatefulWidget {
  final Student?          student;
  final List<Installment> installments;
  final VoidCallback      onPaymentDone;

  const _PaymentTab({
    required this.student,
    required this.installments,
    required this.onPaymentDone,
  });

  @override
  State<_PaymentTab> createState() => _PaymentTabState();
}

class _PaymentTabState extends State<_PaymentTab> {
  final StudentService _service      = StudentService();
  final _amountCtrl                  = TextEditingController();
  final _receivedCtrl                = TextEditingController();
  final _noteCtrl                    = TextEditingController();

  Installment? _selectedInstallment;
  bool         _loading = false;
  String?      _error;

  double? _lastAmountPaid;
  double? _lastChangeGiven;
  bool?   _lastIsFullyPaid;

  List<Installment> get _unpaidInstallments =>
      widget.installments.where((i) => !i.isPaid).toList();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _receivedCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _amountToPay =>
      double.tryParse(_amountCtrl.text.trim().replaceAll(' ', '')) ?? 0;

  double get _amountReceived =>
      double.tryParse(_receivedCtrl.text.trim().replaceAll(' ', '')) ?? 0;

  double get _liveChange =>
      (_amountReceived - _amountToPay).clamp(0.0, double.infinity);

  bool get _isInsufficient =>
      _amountReceived > 0 && _amountReceived < _amountToPay;

  Future<void> _submit() async {
    if (_selectedInstallment == null) {
      setState(() => _error = 'Veuillez sélectionner une tranche.');
      return;
    }
    if (_amountCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez saisir un montant à imputer.');
      return;
    }
    if (_receivedCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez saisir le montant reçu.');
      return;
    }

    final amount   = _amountToPay;
    final received = _amountReceived;

    if (amount <= 0) {
      setState(() => _error = 'Montant à imputer invalide.');
      return;
    }
    if (received <= 0) {
      setState(() => _error = 'Montant reçu invalide.');
      return;
    }
    if (received < amount) {
      setState(() => _error =
      'Montant reçu (${received.toInt()} FCFA) insuffisant pour couvrir ${amount.toInt()} FCFA.');
      return;
    }

    final maxAmount =
        _selectedInstallment!.amount - _selectedInstallment!.paidAmount;
    if (amount > maxAmount) {
      setState(() =>
      _error = 'Le montant dépasse le reste dû (${maxAmount.toInt()} FCFA).');
      return;
    }

    setState(() {
      _loading          = true;
      _error            = null;
      _lastAmountPaid   = null;
      _lastChangeGiven  = null;
      _lastIsFullyPaid  = null;
    });

    try {
      final result = await _service.payInstallment(
        installmentId  : _selectedInstallment!.id,
        studentId      : widget.student!.id,
        amount         : amount,
        amountReceived : received,
      );

      _amountCtrl.clear();
      _receivedCtrl.clear();
      _noteCtrl.clear();

      setState(() {
        _lastAmountPaid  = (result['amountPaid']  as num).toDouble();
        _lastChangeGiven = (result['changeGiven'] as num).toDouble();
        _lastIsFullyPaid = result['isFullyPaid']  as bool;
        _selectedInstallment = null;
      });

      await Future.delayed(const Duration(seconds: 2));
      widget.onPaymentDone();
    } catch (e) {
      setState(() => _error = 'Erreur : ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unpaid = _unpaidInstallments;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),

          if (_lastAmountPaid != null) ...[
            _buildReceipt(),
            const SizedBox(height: 12),
          ],

          if (_error != null) ...[
            _Banner(message: _error!, isError: true),
            const SizedBox(height: 8),
          ],

          if (widget.student != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(14),
                border:
                Border.all(color: const Color(0xFF0055E5).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0055E5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        widget.student!.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.student!.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14,
                          color: Color(0xFF0D1B4B),
                        ),
                      ),
                      Text(
                        widget.student!.studentId,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          if (unpaid.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Scolarité entièrement réglée !',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Toutes les tranches ont été payées.',
                    style: TextStyle(color: Color(0xFF059669), fontSize: 13),
                  ),
                ],
              ),
            )
          else ...[

            _buildSectionLabel('Sélectionner la tranche *'),
            const SizedBox(height: 10),
            ...unpaid.map((inst) {
              final sel   = _selectedInstallment?.id == inst.id;
              final reste = inst.amount - inst.paidAmount;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedInstallment = inst;
                    _amountCtrl.text     = reste.toInt().toString();
                    _receivedCtrl.clear();
                    _error               = null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF0055E5) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? const Color(0xFF0055E5) : const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                    boxShadow: sel
                        ? [BoxShadow(
                        color: const Color(0xFF0055E5).withOpacity(0.2),
                        blurRadius: 8, offset: const Offset(0, 3))]
                        : [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: sel
                              ? Colors.white.withOpacity(0.2)
                              : const Color(0xFFF39C12).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_month_outlined, size: 18,
                          color: sel ? Colors.white : const Color(0xFFF39C12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inst.monthName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14,
                                color: sel ? Colors.white : const Color(0xFF0D1B4B),
                              ),
                            ),
                            Text(
                              inst.paidAmount > 0
                                  ? 'Payé : ${inst.paidAmount.toInt()} — Reste : ${reste.toInt()} FCFA'
                                  : 'À payer : ${reste.toInt()} FCFA',
                              style: TextStyle(
                                fontSize: 12,
                                color: sel ? Colors.white70 : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (sel)
                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            _buildSectionLabel('Montant à imputer (FCFA) *'),
            const SizedBox(height: 8),
            _buildMoneyField(
              controller: _amountCtrl,
              hint: 'Ex: 83 889',
              onChanged: (_) => setState(() {}),
            ),

            if (_selectedInstallment != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _quickAmounts().map((v) {
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _amountCtrl.text = v.toInt().toString()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0055E5).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF0055E5).withOpacity(0.3)),
                      ),
                      child: Text(
                        '${v.toInt()} FCFA',
                        style: const TextStyle(
                          fontSize: 12, color: Color(0xFF0055E5),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            _buildSectionLabel('Montant remis par le payeur (FCFA) *'),
            const SizedBox(height: 8),
            _buildMoneyField(
              controller: _receivedCtrl,
              hint: 'Ex: 100 000',
              accentColor: const Color(0xFF2ECC71),
              onChanged: (_) => setState(() {}),
            ),

            if (_receivedCtrl.text.isNotEmpty &&
                _amountCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildChangeSummary(),
            ],

            const SizedBox(height: 16),

            _buildSectionLabel('Note (optionnel)'),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B4B)),
              decoration: InputDecoration(
                hintText: 'Ex: Paiement en espèces, reçu n°...',
                hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                    const BorderSide(color: Color(0xFF0055E5), width: 1.8)),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0055E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: const Color(0xFF0055E5).withOpacity(0.4),
                ),
                child: _loading
                    ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_card, size: 20),
                    SizedBox(width: 10),
                    Text('Valider le paiement',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  Widget _buildMoneyField({
    required TextEditingController controller,
    required String hint,
    Color accentColor = const Color(0xFF0055E5),
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0D1B4B)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Text(
            'FCFA',
            style: TextStyle(
              color: accentColor, fontWeight: FontWeight.w800, fontSize: 13,
            ),
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            BorderSide(color: accentColor, width: 1.8)),
      ),
    );
  }

  Widget _buildChangeSummary() {
    final insufficient = _isInsufficient;
    final change       = _liveChange;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: insufficient
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: insufficient
              ? const Color(0xFFDC2626).withOpacity(0.3)
              : const Color(0xFF0055E5).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          _SummaryLine(
            label: 'Montant à imputer',
            value: '${_amountToPay.toInt()} FCFA',
            color: const Color(0xFF0D1B4B),
          ),
          const Divider(height: 14),
          _SummaryLine(
            label: 'Montant reçu',
            value: '${_amountReceived.toInt()} FCFA',
            color: const Color(0xFF0D1B4B),
          ),
          const Divider(height: 14),
          _SummaryLine(
            label: insufficient ? '⚠ Insuffisant' : 'Rendu de monnaie',
            value: insufficient
                ? '− ${(_amountToPay - _amountReceived).toInt()} FCFA'
                : '${change.toInt()} FCFA',
            color: insufficient
                ? const Color(0xFFDC2626)
                : const Color(0xFF2ECC71),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildReceipt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 44),
          const SizedBox(height: 8),
          const Text(
            'Paiement enregistré !',
            style: TextStyle(
              color: Color(0xFF059669),
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 14),
          _SummaryLine(
            label: 'Montant imputé',
            value: '${_lastAmountPaid!.toInt()} FCFA',
            color: const Color(0xFF059669),
          ),
          const Divider(height: 14, color: Color(0xFFA7F3D0)),
          _SummaryLine(
            label: 'Rendu de monnaie',
            value: '${_lastChangeGiven!.toInt()} FCFA',
            color: const Color(0xFF059669),
            bold: true,
          ),
          if (_lastIsFullyPaid == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '✓ Tranche entièrement réglée',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<double> _quickAmounts() {
    if (_selectedInstallment == null) return [];
    final reste = _selectedInstallment!.amount - _selectedInstallment!.paidAmount;
    final half  = (reste / 2).roundToDouble();
    return [if (half > 0 && half < reste) half, reste];
  }
}

// ============================================================================
// QR Card Widget
// ============================================================================
class _QrCard extends StatefulWidget {
  final Student? student;
  const _QrCard({required this.student});

  @override
  State<_QrCard> createState() => _QrCardState();
}

class _QrCardState extends State<_QrCard> {
  final GlobalKey _qrKey = GlobalKey();
  bool _sharing = false;

  Future<void> _shareQr() async {
    setState(() => _sharing = true);
    try {
      final boundary = _qrKey.currentContext!.findRenderObject()
      as RenderRepaintBoundary;
      final image    = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes    = byteData!.buffer.asUint8List();

      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/qr_${widget.student?.studentId ?? 'etudiant'}.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'QR Code — ${widget.student?.fullName ?? ''}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    if (s == null) return const SizedBox.shrink();

    final qrData = (s.qrCode != null && s.qrCode!.isNotEmpty) ? s.qrCode! : (s.studentId ?? '');

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
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2, color: Color(0xFF0055E5), size: 20),
              const SizedBox(width: 8),
              const Text(
                'QR Code étudiant',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D1B4B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF0055E5).withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0055E5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          s.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${s.studentId}  •  ${s.filiereName ?? '-'}  •  ${s.level ?? '-'}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF0D1B4B),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF0D1B4B),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      qrData,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0055E5),
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'EduScan — Système de gestion scolaire',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _sharing ? null : _shareQr,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0055E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 3,
                shadowColor: const Color(0xFF0055E5).withOpacity(0.3),
              ),
              icon: _sharing
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.share, size: 18),
              label: Text(
                _sharing ? 'Préparation...' : 'Partager / Télécharger',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Widgets communs
// ============================================================================

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  final bool   bold;

  const _SummaryLine({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 13, color: Colors.grey.shade700,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            )),
        Text(value,
            style: TextStyle(
              fontSize: bold ? 16 : 14, fontWeight: FontWeight.w800, color: color,
            )),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String       title;
  final IconData     icon;
  final String?      subtitle;
  final List<Widget> children;

  const _Card({
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
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
            blurRadius: 12, offset: const Offset(0, 4),
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
              Text(title,
                  style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1B4B),
                  )),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                )),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: valueColor ?? const Color(0xFF0D1B4B),
                )),
          ),
        ],
      ),
    );
  }
}

class _FinanceRow extends StatelessWidget {
  final String   label;
  final String   value;
  final Color    color;
  final IconData icon;
  final bool     bold;

  const _FinanceRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF1A1A2E),
              )),
        ),
        Text(value,
            style: TextStyle(
              fontSize: bold ? 17 : 14, fontWeight: FontWeight.w800, color: color,
            )),
      ],
    );
  }
}

class _InstallmentRow extends StatelessWidget {
  final Installment item;
  const _InstallmentRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isPaid ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isPaid
              ? const Color(0xFF2ECC71).withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: item.isPaid ? const Color(0xFF2ECC71) : Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.isPaid ? Icons.check : Icons.schedule,
                  size: 16,
                  color: item.isPaid ? Colors.white : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.monthName,
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        )),
                    Text(
                      '${item.paidAmount.toInt()} / ${item.amount.toInt()} FCFA',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isPaid ? const Color(0xFF2ECC71) : Colors.red.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.isPaid ? 'Payé' : 'En attente',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (item.isPaid) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 13, color: Colors.green.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Payé le : ${item.formattedPaidAt}',
                    style: TextStyle(
                      fontSize: 12, color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!item.isPaid && item.paidAmount > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Reste : ${(item.amount - item.paidAmount).toInt()} FCFA',
              style: TextStyle(
                fontSize: 12, color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String message;
  final bool   isError;

  const _Banner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color:
            isError ? const Color(0xFFDC2626) : const Color(0xFF059669),
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
                fontSize: 13, fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildSectionLabel(String label) {
  return Text(
    label,
    style: const TextStyle(
      fontWeight: FontWeight.w700, fontSize: 12,
      color: Color(0xFF374151), letterSpacing: 0.5,
    ),
  );
}