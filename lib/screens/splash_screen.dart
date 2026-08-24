import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn  = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideUp = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();

    // ── Vérification de session après animation ───────────────────
    // On attend 2,5 s (animation) puis on tente de récupérer la session.
    // Si la session est expirée on tente un refresh silencieux.
    Future.delayed(const Duration(milliseconds: 2500), _redirect);
  }

  Future<void> _redirect() async {
    if (!mounted) return;

    final supabase = Supabase.instance.client;
    Session? session = supabase.auth.currentSession;

    // Si la session existe mais est expirée → refresh
    if (session != null && session.isExpired) {
      try {
        final refreshed = await supabase.auth.refreshSession();
        session = refreshed.session;
      } catch (_) {
        session = null; // refresh échoué → retour login
      }
    }

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      session != null ? '/home' : '/login',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F4FF), Color(0xFFE8EFFE)],
          ),
        ),
        child: Stack(
          children: [
            // Vague bleue en bas
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: ClipPath(
                clipper: _WaveClipper(),
                child: Container(
                  height: 220,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0055E5), Color(0xFF003BB5)],
                    ),
                  ),
                ),
              ),
            ),

            // Contenu animé
            FadeTransition(
              opacity: _fadeIn,
              child: AnimatedBuilder(
                animation: _slideUp,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _slideUp.value),
                  child: child,
                ),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Logo wordmark
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Edu',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0D1B4B),
                              letterSpacing: -1,
                            ),
                          ),
                          TextSpan(
                            text: 'Scan',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0055E5),
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tagline
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _TaglineDot(text: 'Vérifiez'),
                        _TaglineBullet(),
                        _TaglineDot(text: 'Gérez'),
                        _TaglineBullet(),
                        _TaglineDot(text: 'Réussissez'),
                      ],
                    ),

                    const Spacer(flex: 3),

                    // Loader
                    Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white.withOpacity(0.85),
                              backgroundColor:
                              Colors.white.withOpacity(0.3),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Chargement...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaglineDot extends StatelessWidget {
  final String text;
  const _TaglineDot({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF4A5568),
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _TaglineBullet extends StatelessWidget {
  const _TaglineBullet();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '•',
        style: TextStyle(
          color: Color(0xFF0055E5),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.45);
    path.quadraticBezierTo(
        size.width * 0.25, 0, size.width * 0.5, size.height * 0.25);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.5, size.width, size.height * 0.2);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}