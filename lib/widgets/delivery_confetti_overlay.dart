import 'dart:math';
import 'package:flutter/material.dart';
import '../app/app_colors.dart';

class DeliveryCelebrationDialog extends StatefulWidget {
  final String orderNumber;
  final double earnedAmount;
  final double tipAmount;
  final VoidCallback onDismiss;

  const DeliveryCelebrationDialog({
    super.key,
    required this.orderNumber,
    required this.earnedAmount,
    required this.tipAmount,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required String orderNumber,
    required double earnedAmount,
    required double tipAmount,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DeliveryCelebrationDialog(
        orderNumber: orderNumber,
        earnedAmount: earnedAmount,
        tipAmount: tipAmount,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<DeliveryCelebrationDialog> createState() =>
      _DeliveryCelebrationDialogState();
}

class _DeliveryCelebrationDialogState extends State<DeliveryCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated Confetti Canvas
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(progress: _controller.value),
                  );
                },
              ),
            ),

            // Dialog Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Trophy Badge
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Order Delivered!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.orderNumber} successfully completed',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Earnings Summary Box
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkHeaderBg
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'PAYOUT CREDITED TO WALLET',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+₹${(widget.earnedAmount + widget.tipAmount).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        if (widget.tipAmount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.favorite,
                                  color: Colors.pinkAccent, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Includes ₹${widget.tipAmount.toStringAsFixed(0)} customer tip!',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.pinkAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'READY FOR NEXT ORDER',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles = List.generate(
    40,
    (i) => _ConfettiParticle(Random(i * 17)),
  );

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0));
      final double x = size.width / 2 + (p.dx * progress * size.width * 0.6);
      final double y = size.height / 2 +
          (p.dy * progress * size.height * 0.6) +
          (progress * progress * 80);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.rotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

class _ConfettiParticle {
  late double dx;
  late double dy;
  late double size;
  late double rotation;
  late Color color;

  _ConfettiParticle(Random random) {
    final double angle = random.nextDouble() * 2 * pi;
    final double speed = 0.5 + random.nextDouble() * 0.7;
    dx = cos(angle) * speed;
    dy = sin(angle) * speed;
    size = 6.0 + random.nextDouble() * 8.0;
    rotation = (random.nextDouble() - 0.5) * 10;

    final colors = [
      AppColors.primary,
      AppColors.secondary,
      Colors.blueAccent,
      Colors.pinkAccent,
      Colors.amber,
      Colors.purpleAccent,
    ];
    color = colors[random.nextInt(colors.length)];
  }
}
