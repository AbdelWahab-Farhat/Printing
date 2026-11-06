import 'package:flutter/material.dart';

/// ردُّ الضغط الوحيد على بطاقة الموظف: ما يُضغط يخفت لحظة — كبريمولا. لا `InkWell`: ظلُّه الرماديّ
/// على التدرّج لطخة، والتموّجُ لا سطحَ له هنا.
class CardPressable extends StatefulWidget {
  const CardPressable({required this.onTap, required this.child, super.key});

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<CardPressable> createState() => _CardPressableState();
}

class _CardPressableState extends State<CardPressable> {
  bool _pressed = false;

  void _set(bool pressed) => setState(() => _pressed = pressed);

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      child: AnimatedOpacity(
        opacity: _pressed ? 0.55 : 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}
