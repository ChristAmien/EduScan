import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/etudiant.dart';
import '../models/installment.dart';

// ── Constantes scolarité ─────────────────────────────────────────────────────
const double kTuitionAffiliated    = 755000;
const double kTuitionNonAffiliated = 1200000;

const List<String> kInstallmentMonths = [
  'Octobre', 'Novembre', 'Décembre',
  'Janvier', 'Février', 'Mars',
  'Avril', 'Mai', 'Juin',
];

class StudentService {
  final supabase = Supabase.instance.client;

  //  Récupération étudiants

  Future<Student> getStudentById(String id) async {
    final response = await supabase
        .from('students')
        .select('*, filieres(*)')
        .eq('id', id)
        .single();
    return Student.fromJson(response);
  }

  Future<Student> getStudentByQr(String qrCode) async {
    final response = await supabase
        .from('students')
        .select('*, filieres(*)')
        .eq('qr_code', qrCode)
        .single();
    return Student.fromJson(response);
  }

  Future<List<Student>> getStudents() async {
    final response = await supabase
        .from('students')
        .select('*, filieres(*)')
        .order('first_name');
    return response.map<Student>((e) => Student.fromJson(e)).toList();
  }

  // ── Tranches ──────────────────────────────────────────────────────────────

  Future<List<Installment>> getInstallments(String studentId) async {
    final response = await supabase
        .from('tuition_installments')
        .select()
        .eq('student_id', studentId)
        .order('created_at');
    return response.map<Installment>((e) => Installment.fromJson(e)).toList();
  }

  Future<double> getRemainingAmount(String studentId) async {
    final installments = await getInstallments(studentId);
    double total = 0;
    for (final item in installments) {
      total += item.amount - item.paidAmount;
    }
    return total;
  }

  Future<bool> isStudentUpToDate(String studentId) async {
    final installments = await getInstallments(studentId);
    return installments.every((item) => item.status == 'paid');
  }

  // ── Génération automatique des tranches ──────────────────────────────────
  Future<void> generateInstallments({
    required String studentId,
    required bool isAffiliated,
  }) async {
    final total          = isAffiliated ? kTuitionAffiliated : kTuitionNonAffiliated;
    final perInstallment = total / kInstallmentMonths.length;

    final now          = DateTime.now();
    final academicYear = now.month >= 10 ? now.year : now.year - 1;

    final rows = kInstallmentMonths.asMap().entries.map((entry) {
      return {
        'student_id' : studentId,
        'month_name' : '${entry.value} $academicYear',
        'amount'     : perInstallment,
        'paid_amount': 0,
        'status'     : 'unpaid',
        'paid_at'    : null,
      };
    }).toList();

    await supabase.from('tuition_installments').insert(rows);
  }

  // ── Enregistrer un paiement sur une tranche ───────────────────────────────
  /// [amount]          = montant à imputer sur la tranche
  /// [amountReceived]  = montant remis physiquement par le payeur
  ///
  /// Retourne :
  ///   - amountPaid   : montant réellement imputé
  ///   - changeGiven  : rendu de monnaie (amountReceived − amountPaid)
  ///   - isFullyPaid  : true si la tranche est entièrement soldée
  Future<Map<String, dynamic>> payInstallment({
    required String installmentId,
    required String studentId,
    required double amount,
    required double amountReceived,
  }) async {
    // 1. Récupérer la tranche courante
    final row = await supabase
        .from('tuition_installments')
        .select('amount, paid_amount')
        .eq('id', installmentId)
        .single();

    final currentPaid = (row['paid_amount'] as num).toDouble();
    final total       = (row['amount'] as num).toDouble();
    final maxAllowed  = total - currentPaid;

    // Sécurité : ne jamais imputer plus que le reste dû
    final amountPaid  = amount.clamp(0.0, maxAllowed);
    final newPaid     = currentPaid + amountPaid;
    final isFullyPaid = newPaid >= total;
    final changeGiven = (amountReceived - amountPaid).clamp(0.0, double.infinity);

    // 2. Mettre à jour la tranche
    await supabase.from('tuition_installments').update({
      'paid_amount': newPaid,
      'status'     : isFullyPaid ? 'paid' : 'partial',
      'paid_at'    : isFullyPaid ? DateTime.now().toIso8601String() : null,
    }).eq('id', installmentId);

    // 3. Enregistrer la transaction dans l'historique
    await supabase.from('payment_transactions').insert({
      'installment_id'  : installmentId,
      'student_id'      : studentId,
      'amount_due'      : maxAllowed,
      'amount_received' : amountReceived,
      'amount_paid'     : amountPaid,
      'change_given'    : changeGiven,
      'created_at'      : DateTime.now().toIso8601String(),
    });

    return {
      'amountPaid'  : amountPaid,
      'changeGiven' : changeGiven,
      'isFullyPaid' : isFullyPaid,
    };
  }

  // ── Logs admin ────────────────────────────────────────────────────────────
  Future<void> logAdminAction({
    required String userId,
    required String email,
    required String action,
    String? fullName,
    String? role,
  }) async {
    try {
      await supabase.from('admin_logs').insert({
        'user_id'   : userId,
        'email'     : email,
        'action'    : action,
        'full_name' : fullName,
        'role'      : role,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }
}