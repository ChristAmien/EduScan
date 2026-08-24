import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/student_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _selectedRole = 'Secrétaire';
  final List<String> _roles = ['Secrétaire', 'Directeur', 'Resp. Niveau'];

  bool _isLoading      = false;
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  String? _error;

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.trim().isEmpty ||
        _confirmCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs.');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() =>
      _error = 'Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // inscription
      final authRes = await supabase.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        data: {
          'full_name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'role': _selectedRole,
        },
      );

      if (authRes.user == null) throw Exception('Inscription échouée.');

      // Connexion automatique si session absente
      AuthResponse? loginRes;
      if (authRes.session == null) {
        loginRes = await supabase.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      }

      // Enregistrement du log d'inscription
      final user = authRes.user ?? loginRes?.user;
      if (user != null) {
        await StudentService().logAdminAction(
          userId: user.id,
          email: user.email ?? _emailCtrl.text.trim(),
          action: 'register',
          fullName: _nameCtrl.text.trim(),
          role: _selectedRole,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0055E5),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Inscription',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NOM COMPLET
              _buildLabel('NOM COMPLET'),
              const SizedBox(height: 8),
              _buildField(
                controller: _nameCtrl,
                hint: 'Ex: Alla Henriette',
              ),

              const SizedBox(height: 20),

              // TÉLÉPHONE
              _buildLabel('NUMÉRO DE TÉLÉPHONE'),
              const SizedBox(height: 8),
              _buildField(
                controller: _phoneCtrl,
                hint: 'Ex: +225 07 00 00 00 00',
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 20),

              // EMAIL
              _buildLabel('EMAIL'),
              const SizedBox(height: 8),
              _buildField(
                controller: _emailCtrl,
                hint: 'admin@upb.ci',
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              // ROLE
              _buildLabel('ROLE'),
              const SizedBox(height: 10),
              Row(
                children: _roles.asMap().entries.map((entry) {
                  final role = entry.value;
                  final isLast = entry.key == _roles.length - 1;
                  final selected = _selectedRole == role;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRole = role),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: EdgeInsets.only(right: isLast ? 0 : 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF0055E5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF0055E5)
                                : const Color(0xFFD1D5DB),
                            width: 1.4,
                          ),
                        ),
                        child: Text(
                          role,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF374151),
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // MOT DE PASSE
              _buildLabel('CRÉEZ UN MOT DE PASSE'),
              const SizedBox(height: 8),
              _buildField(
                controller: _passCtrl,
                hint: '••••••••',
                obscure: _obscurePass,
                suffix: TextButton(
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                  child: Text(
                    _obscurePass ? 'Voir' : 'Cacher',
                    style: const TextStyle(
                      color: Color(0xFF0055E5),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // CONFIRMER MOT DE PASSE
              _buildLabel('CONFIRMEZ VOTRE MOT DE PASSE'),
              const SizedBox(height: 8),
              _buildField(
                controller: _confirmCtrl,
                hint: '••••••••',
                obscure: _obscureConfirm,
                suffix: TextButton(
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  child: Text(
                    _obscureConfirm ? 'Voir' : 'Cacher',
                    style: const TextStyle(
                      color: Color(0xFF0055E5),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // ERREUR
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // BOUTON S'INSCRIRE
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0055E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                    shadowColor: const Color(0xFF0055E5).withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "S'inscrire",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: const [
                  Expanded(child: Divider(color: Color(0xFFD1D5DB))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Déjà un compte ?',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFFD1D5DB))),
                ],
              ),

              const SizedBox(height: 14),

              Center(
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(
                      color: Color(0xFF0055E5),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        color: Color(0xFF374151),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: Color(0xFF0D1B4B)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
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
      ),
    );
  }
}