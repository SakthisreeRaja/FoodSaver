import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// QR Scan screen — volunteers scan a QR code on a pickup slip to confirm pickup.
/// Since mobile_scanner is not in pubspec, we provide manual entry with QR UI.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen>
    with TickerProviderStateMixin {
  final _codeCtrl = TextEditingController();
  bool _isSearching = false;
  late AnimationController _scanLineCtrl;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupPickup(String code) async {
    if (code.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      // Try to find pickup by ID directly
      final doc = await FirebaseFirestore.instance
          .collection('pickups')
          .doc(code.trim())
          .get();

      if (!doc.exists) {
        // Try query by donationId
        final snap = await FirebaseFirestore.instance
            .collection('pickups')
            .where('donationId', isEqualTo: code.trim())
            .limit(1)
            .get();

        if (snap.docs.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('❌ Pickup not found. Check the code.'),
                  backgroundColor: Colors.red),
            );
          }
          return;
        }

        final pickup = {...snap.docs.first.data(), 'id': snap.docs.first.id};
        if (mounted) context.push('/pickup-details', extra: pickup);
        return;
      }

      final pickup = {...doc.data()!, 'id': doc.id};
      if (mounted) context.push('/pickup-details', extra: pickup);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Code',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Camera viewfinder background
          Container(
            color: Colors.black87,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // QR frame
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      children: [
                        // Corner decorations
                        ..._corners(),
                        // Scan line animation
                        AnimatedBuilder(
                          animation: _scanLineCtrl,
                          builder: (_, __) {
                            return Positioned(
                              top: _scanLineCtrl.value * 240,
                              left: 10,
                              right: 10,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.withOpacity(0),
                                      Colors.green,
                                      Colors.green.withOpacity(0),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.green.withOpacity(0.5),
                                        blurRadius: 6,
                                        spreadRadius: 2),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Center icon
                        Center(
                          child: Icon(Icons.qr_code_scanner,
                              size: 80,
                              color: Colors.white.withOpacity(0.15)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Align QR code within the frame',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The camera scanner requires mobile_scanner package.\nUse manual entry below.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Bottom panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Enter Pickup ID Manually',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    'Type the pickup ID or donation ID from the slip',
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeCtrl,
                          decoration: InputDecoration(
                            hintText: 'Pickup ID or Donation ID',
                            prefixIcon: const Icon(Icons.qr_code),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          onSubmitted: _lookupPickup,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isSearching
                            ? null
                            : () => _lookupPickup(_codeCtrl.text),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Find'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => context.push('/volunteer-history'),
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('View My Pickups'),
                  ),
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
    const width = 3.0;
    const color = Colors.green;

    return [
      // Top-left
      Positioned(
          top: 0,
          left: 0,
          child: _corner(top: true, left: true, size: size, w: width, c: color)),
      // Top-right
      Positioned(
          top: 0,
          right: 0,
          child: _corner(top: true, left: false, size: size, w: width, c: color)),
      // Bottom-left
      Positioned(
          bottom: 0,
          left: 0,
          child: _corner(top: false, left: true, size: size, w: width, c: color)),
      // Bottom-right
      Positioned(
          bottom: 0,
          right: 0,
          child: _corner(top: false, left: false, size: size, w: width, c: color)),
    ];
  }

  Widget _corner({
    required bool top,
    required bool left,
    required double size,
    required double w,
    required Color c,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
            isTop: top, isLeft: left, strokeWidth: w, color: c),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;
  final double strokeWidth;
  final Color color;

  _CornerPainter(
      {required this.isTop,
      required this.isLeft,
      required this.strokeWidth,
      required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (isTop && isLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
