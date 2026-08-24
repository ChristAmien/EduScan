import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  // ── Données lues depuis Supabase (userMetadata + email) ──────────
  String _fullName = '';
  String _email    = '';
  String _phone    = '';
  String _role     = '';
  String _initials = '';
  bool   _loading  = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Supabase stocke les données directement dans currentUser.
    // On appelle getUserById pour s'assurer d'avoir les données à jour
    // (utile si les metadata ont été mises à jour côté serveur).
    try {
      final supabase = Supabase.instance.client;

      // Rafraîchir la session pour avoir les metadata les plus récentes
      await supabase.auth.refreshSession();

      final user = supabase.auth.currentUser;
      if (user == null) return;

      final meta     = user.userMetadata ?? {};
      final fullName = (meta['full_name'] as String? ?? '').trim();
      final phone    = (meta['phone']     as String? ?? '').trim();
      final role     = (meta['role']      as String? ?? '').trim();
      final email    = user.email ?? '';

      // Calcul des initiales (max 2 lettres)
      final parts    = fullName.split(' ').where((w) => w.isNotEmpty).toList();
      final initials = parts.length >= 2
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : (parts.isNotEmpty ? parts[0][0].toUpperCase() : '??');

      if (mounted) {
        setState(() {
          _fullName = fullName.isNotEmpty ? fullName : 'Utilisateur';
          _email    = email;
          _phone    = phone.isNotEmpty   ? phone   : 'Non renseigné';
          _role     = role.isNotEmpty    ? role    : 'Admin';
          _initials = initials;
          _loading  = false;
        });
      }
    } catch (_) {
      // Fallback si refresh échoue (pas de réseau, etc.)
      final user = Supabase.instance.client.auth.currentUser;
      final meta = user?.userMetadata ?? {};
      setState(() {
        _fullName = (meta['full_name'] as String? ?? 'Utilisateur').trim();
        _email    = user?.email ?? '';
        _phone    = (meta['phone'] as String? ?? 'Non renseigné').trim();
        _role     = (meta['role']  as String? ?? 'Admin').trim();
        _initials = _fullName.isNotEmpty ? _fullName[0].toUpperCase() : '?';
        _loading  = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FD),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header bleu ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: const BoxDecoration(
                color: Color(0xFF0055E5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Barre du haut : retour + titre
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
                      const Expanded(
                        child: Text(
                          'Paramètres',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Avatar + infos utilisateur
                  _loading
                      ? const SizedBox(
                    height: 64,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  )
                      : Row(
                    children: [
                      // Avatar avec initiales
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              color: Color(0xFF0055E5),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Nom + email + rôle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _email,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Badge rôle
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _role,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Contenu scrollable ──────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0055E5)))
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Compte ──────────────────────────────────
                    _SettingsGroup(
                      title: 'Compte',
                      items: [
                        _SettingsTile(
                          icon: Icons.person_outline,
                          label: 'Nom complet',
                          trailing: _TrailingText(_fullName),
                        ),
                        _SettingsTile(
                          icon: Icons.alternate_email,
                          label: 'Adresse email',
                          trailing: _TrailingText(_email),
                        ),
                        _SettingsTile(
                          icon: Icons.phone_android,
                          label: 'Numéro de téléphone',
                          trailing: _TrailingText(_phone),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Sécurité ─────────────────────────────────
                    _SettingsGroup(
                      title: 'Sécurité',
                      items: [
                        _SettingsTile(
                          icon: Icons.lock_outline,
                          label: 'Changer le mot de passe',
                          onTap: () => _showChangePasswordDialog(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Notifications ────────────────────────────
                    _SettingsGroup(
                      title: 'Notifications',
                      items: [
                        _SettingsTile(
                          icon: Icons.notifications_active_outlined,
                          label: 'Notification push',
                          subtitle: "Recevoir des notifications sur l'app",
                          onTap: () {},
                        ),
                        _SettingsTile(
                          icon: Icons.email_outlined,
                          label: 'Notification par email',
                          subtitle: "Recevoir des emails d'EduScan",
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Aide ─────────────────────────────────────
                    _SettingsGroup(
                      title: 'Aide',
                      items: [
                        _SettingsTile(
                          icon: Icons.help_outline,
                          label: 'FAQ',
                          onTap: () {},
                        ),
                        _SettingsTile(
                          icon: Icons.headset_mic_outlined,
                          label: 'Nous contacter',
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Bouton déconnexion ────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _logout(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(
                              color: Colors.red, width: 1.5),
                          padding:
                          const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Se déconnecter',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _BottomNav(
        activeIndex: 4,
        onTap: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, '/home');
          if (i == 1) Navigator.pushNamed(context, '/admin');
          if (i == 2) Navigator.pushNamed(context, '/scanner');
        },
      ),
    );
  }

  // ── Dialog changement de mot de passe ──────────────────────────────
  void _showChangePasswordDialog(BuildContext context) {
    final passCtrl    = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure1 = true;
    bool obscure2 = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nouveau mot de passe',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passCtrl,
                obscureText: obscure1,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscure1 ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setDlgState(() => obscure1 = !obscure1),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: obscure2,
                decoration: InputDecoration(
                  labelText: 'Confirmer',
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscure2 ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setDlgState(() => obscure2 = !obscure2),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0055E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (passCtrl.text != confirmCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Les mots de passe ne correspondent pas.'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                try {
                  await Supabase.instance.client.auth
                      .updateUser(UserAttributes(password: passCtrl.text));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Mot de passe mis à jour !'),
                      backgroundColor: Colors.green,
                    ));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Erreur : ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ));
                  }
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Widgets internes
// ────────────────────────────────────────────────────────────────────────────

class _TrailingText extends StatelessWidget {
  final String text;
  const _TrailingText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0055E5),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04), blurRadius: 10),
            ],
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              return Column(
                children: [
                  items[i],
                  if (i < items.length - 1)
                    const Divider(
                        height: 1, indent: 56, color: Color(0xFFF3F4F6)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF0055E5).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF0055E5), size: 18),
      ),
      title: Text(
        label,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D1B4B)),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400))
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: Colors.grey.shade400)
              : null),
    );
  }
}

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
                        color:
                        const Color(0xFF0055E5).withOpacity(0.1),
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