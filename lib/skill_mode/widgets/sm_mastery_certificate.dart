import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

/// Mastery Certificate overlay (SM-2.5.6).
///
/// Full-screen celebration + certificate card.
/// RepaintBoundary → PNG → native share sheet.
class SmMasteryCertificate extends StatefulWidget {
  final String playerName;
  final String deckTitle;
  final String creatorName;
  final int scorePct;
  final int daysToMaster;
  final VoidCallback? onDismiss;

  const SmMasteryCertificate({
    super.key,
    required this.playerName,
    required this.deckTitle,
    required this.creatorName,
    required this.scorePct,
    required this.daysToMaster,
    this.onDismiss,
  });

  /// Show as overlay.
  static void show(
    BuildContext context, {
    required String playerName,
    required String deckTitle,
    required String creatorName,
    required int scorePct,
    required int daysToMaster,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => SmMasteryCertificate(
        playerName: playerName,
        deckTitle: deckTitle,
        creatorName: creatorName,
        scorePct: scorePct,
        daysToMaster: daysToMaster,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<SmMasteryCertificate> createState() => _SmMasteryCertificateState();
}

class _SmMasteryCertificateState extends State<SmMasteryCertificate>
    with TickerProviderStateMixin {
  final _certificateKey = GlobalKey();
  late AnimationController _confettiController;
  late List<_CertConfetti> _confettiParticles;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();

    _confettiParticles = List.generate(80, (_) {
      return _CertConfetti(
        x: _rng.nextDouble(),
        dx: (_rng.nextDouble() - 0.5) * 200,
        dy: -_rng.nextDouble() * 400 - 150,
        rotation: _rng.nextDouble() * pi * 2,
        color: [
          const Color(0xFFFFD700),
          const Color(0xFFF59E0B),
          const Color(0xFF3B82F6),
          const Color(0xFF10B981),
          const Color(0xFF8B5CF6),
        ][_rng.nextInt(5)],
        size: _rng.nextDouble() * 8 + 3,
      );
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _shareCertificate() async {
    try {
      final boundary = _certificateKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final xFile = XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: 'mastery_certificate.png',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text:
              '${widget.playerName} mastered "${widget.deckTitle}" by ${widget.creatorName} — ${widget.scorePct}%!',
        ),
      );
    } catch (e) {
      // Non-blocking.
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

    return Material(
      color: Colors.black87,
      child: GestureDetector(
        onTap: widget.onDismiss,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Confetti.
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _CertConfettiPainter(
                    particles: _confettiParticles,
                    progress: _confettiController.value,
                  ),
                );
              },
            ),

            // Certificate card.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RepaintBoundary(
                    key: _certificateKey,
                    child: Container(
                      width: 320,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD700),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withAlpha(60),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Crown.
                          const Text('👑', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          const Text(
                            'MASTERY CERTIFICATE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB8860B),
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Divider.
                          Container(
                            height: 1,
                            color: const Color(0xFFFFD700).withAlpha(80),
                          ),
                          const SizedBox(height: 16),
                          // Player name.
                          Text(
                            widget.playerName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'mastered',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Deck title.
                          Text(
                            widget.deckTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'by ${widget.creatorName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 1,
                            color: const Color(0xFFFFD700).withAlpha(80),
                          ),
                          const SizedBox(height: 12),
                          // Stats row.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _certStat(
                                  '${widget.scorePct}%', 'Score'),
                              _certStat(
                                  '${widget.daysToMaster}', 'Days'),
                              _certStat(dateStr, 'Date'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Juku brand.
                          const Text(
                            'juku.pro',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.3, 0.3),
                        end: const Offset(1.0, 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: const Duration(milliseconds: 300)),
                  const SizedBox(height: 24),
                  // Share button.
                  FilledButton.icon(
                    onPressed: _shareCertificate,
                    icon: const Icon(Icons.share),
                    label: const Text('Share Certificate'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: const Color(0xFF1E293B),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _certStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _CertConfetti {
  final double x, dx, dy, rotation, size;
  final Color color;
  const _CertConfetti({
    required this.x,
    required this.dx,
    required this.dy,
    required this.rotation,
    required this.color,
    required this.size,
  });
}

class _CertConfettiPainter extends CustomPainter {
  final List<_CertConfetti> particles;
  final double progress;
  _CertConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final alpha = (255 * (1 - progress * 0.7)).round().clamp(0, 255);
      final paint = Paint()..color = p.color.withAlpha(alpha);
      final x = p.x * size.width + p.dx * progress;
      final y = size.height * 0.3 + p.dy * progress + 250 * progress * progress;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * pi * 3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CertConfettiPainter old) =>
      old.progress != progress;
}
