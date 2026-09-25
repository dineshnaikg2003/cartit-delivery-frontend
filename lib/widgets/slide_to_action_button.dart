import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/app_colors.dart';

class SlideToActionButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color actionColor;
  final Color trackColor;
  final Color textColor;
  final Future<void> Function() onSlideComplete;
  final bool isLoading;

  const SlideToActionButton({
    super.key,
    required this.text,
    this.icon = Icons.arrow_forward,
    this.actionColor = AppColors.primary,
    this.trackColor = const Color(0xFFE6F7EF),
    this.textColor = Colors.white,
    required this.onSlideComplete,
    this.isLoading = false,
  });

  @override
  State<SlideToActionButton> createState() => _SlideToActionButtonState();
}

class _SlideToActionButtonState extends State<SlideToActionButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  late AnimationController _animController;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _resetSlider() {
    if (!mounted) return;
    _anim = Tween<double>(begin: _dragPosition, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _dragPosition = _anim.value;
        });
      });
    _animController.forward(from: 0.0);
    _isCompleted = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const double height = 54.0;
    const double handleSize = 46.0;
    const double padding = 4.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - handleSize - (padding * 2);

        return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBorder : widget.trackColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.actionColor.withValues(alpha: isDark ? 0.4 : 0.25),
              width: 1.2,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Center Label with Shimmer-like styling
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isLoading) ...[
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.isLoading ? 'Processing...' : widget.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isDark
                            ? AppColors.darkTitle
                            : (widget.actionColor == AppColors.primary
                                ? AppColors.primaryDark
                                : AppColors.title),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: isDark
                          ? AppColors.darkSubtitle
                          : widget.actionColor.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),

              // Completed Progress Fill
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _dragPosition + handleSize + (padding * 2),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.actionColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),

              // Draggable Handle
              Positioned(
                left: padding + _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: widget.isLoading || _isCompleted
                      ? null
                      : (details) {
                          setState(() {
                            _dragPosition += details.delta.dx;
                            if (_dragPosition < 0) _dragPosition = 0;
                            if (_dragPosition > maxDrag) _dragPosition = maxDrag;
                          });
                        },
                  onHorizontalDragEnd: widget.isLoading || _isCompleted
                      ? null
                      : (details) async {
                          if (_dragPosition >= maxDrag * 0.75) {
                            HapticFeedback.heavyImpact();
                            setState(() {
                              _dragPosition = maxDrag;
                              _isCompleted = true;
                            });
                            try {
                              await widget.onSlideComplete();
                            } finally {
                              _resetSlider();
                            }
                          } else {
                            HapticFeedback.lightImpact();
                            _resetSlider();
                          }
                        },
                  child: Container(
                    width: handleSize,
                    height: handleSize,
                    decoration: BoxDecoration(
                      color: widget.actionColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.actionColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.textColor,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
