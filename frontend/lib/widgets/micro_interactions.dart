import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Simple press animation used across the app.
class PressScale extends StatefulWidget {
  final Widget child;
  final double scaleDown;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onTap;
  final bool enabled;

  const PressScale({
    super.key,
    required this.child,
    this.scaleDown = 0.96,
    this.duration = const Duration(milliseconds: 120),
    this.curve = Curves.easeOut,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(begin: 1, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _ctrl, curve: widget.curve),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down() {
    if (!widget.enabled) return;
    _ctrl.forward();
  }

  void _up() {
    if (!widget.enabled) return;
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _down(),
      onTapUp: (_) => _up(),
      onTapCancel: _up,
      onTap: widget.enabled
          ? () {
              HapticFeedback.selectionClick();
              widget.onTap?.call();
            }
          : null,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Transform.scale(
          scale: _anim.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Fades + slides a child in.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
    this.curve = Curves.easeOut,
    this.offsetY = 10,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1,
      duration: duration,
      curve: curve,
      child: TweenAnimationBuilder<double>(
        duration: duration,
        curve: curve,
        tween: Tween<double>(begin: offsetY, end: 0),
        builder: (context, value, child) => Transform.translate(
          offset: Offset(0, value),
          child: child,
        ),
        child: child,
      ),
    );
  }
}

/// Shared animated route for nicer page transitions.
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeSlidePageRoute({
    required this.page,
    super.settings,
    super.transitionDuration,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Curves.easeOut);
            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
            final slide =
                Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                    .animate(curved);
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        );
}

/// Subtle pulse ring for call status.
class PulseRing extends StatefulWidget {
  final bool active;
  final double size;
  final Color color;
  final Duration duration;

  const PulseRing({
    super.key,
    required this.active,
    this.size = 190,
    this.color = const Color(0xFFF44336),
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    if (widget.active) _ctrl.repeat(reverse: false);
  }

  @override
  void didUpdateWidget(covariant PulseRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _ctrl.repeat(reverse: false);
    } else if (!widget.active && oldWidget.active) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value;
          final scale = 0.92 + t * 0.14;
          final opacity = widget.active ? (1 - t).clamp(0.0, 1.0) : 0.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: widget.color.withOpacity(opacity), width: 3),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
