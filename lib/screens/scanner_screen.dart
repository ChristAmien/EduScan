import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/student_service.dart';
import '../models/etudiant.dart';
import 'student_details_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {

  bool _processing = false;
  final StudentService _service = StudentService();

  Future<void> _handleScan(String qrCode) async {
    if (_processing) return;
    _processing = true;
    try {
      Student student = await _service.getStudentByQr(qrCode);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentDetailsScreen(studentId: student.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Étudiant introuvable'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _processing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              final qrCode = barcode.rawValue;
              if (qrCode != null) _handleScan(qrCode);
            },
          ),

          // Overlay gradient top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          // Back button + title
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Scanner QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scanner frame
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF0055E5), width: 3),
                  ),
                  child: Stack(
                    children: [
                      // Corner decorations
                      ..._corners(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom overlay + hint
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 180,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Placez le QR Code dans le cadre',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    const size = 24.0;
    const thickness = 4.0;
    const color = Color(0xFF0055E5);
    return [
      // Top left
      Positioned(top: 0, left: 0, child: _Corner(size: size, thickness: thickness, color: color, topLeft: true)),
      Positioned(top: 0, right: 0, child: _Corner(size: size, thickness: thickness, color: color, topRight: true)),
      Positioned(bottom: 0, left: 0, child: _Corner(size: size, thickness: thickness, color: color, bottomLeft: true)),
      Positioned(bottom: 0, right: 0, child: _Corner(size: size, thickness: thickness, color: color, bottomRight: true)),
    ];
  }
}

class _Corner extends StatelessWidget {
  final double size;
  final double thickness;
  final Color color;
  final bool topLeft, topRight, bottomLeft, bottomRight;

  const _Corner({
    required this.size,
    required this.thickness,
    required this.color,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          thickness: thickness,
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool topLeft, topRight, bottomLeft, bottomRight;

  _CornerPainter({
    required this.color,
    required this.thickness,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (topLeft) {
      canvas.drawLine(Offset(0, size.height), Offset(0, 0), paint);
      canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);
    }
    if (bottomLeft) {
      canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);
    }
    if (bottomRight) {
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}