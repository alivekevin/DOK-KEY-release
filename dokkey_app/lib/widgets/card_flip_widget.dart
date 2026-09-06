import 'dart:math';
import 'package:flutter/material.dart';
import '../models/dokkey_models.dart';
import 'oriental_card_painter.dart';

class CardFlipWidget extends StatefulWidget {
  final CardModel card;
  final int number;
  final ToneModel tone;
  final bool initialFront;
  final bool autoFlip;
  final double width;
  final double height;
  final VoidCallback? onFlipped;

  const CardFlipWidget({
    super.key,
    required this.card,
    required this.number,
    required this.tone,
    this.initialFront = false,
    this.autoFlip = false,
    this.width = 250,
    this.height = 380,
    this.onFlipped,
  });

  @override
  State<CardFlipWidget> createState() => _CardFlipWidgetState();
}

class _CardFlipWidgetState extends State<CardFlipWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = false;

  @override
  void initState() {
    super.initState();
    _isFront = widget.initialFront;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animation = Tween<double>(
      begin: _isFront ? pi : 0.0,
      end: _isFront ? pi : pi,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    if (widget.autoFlip) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          flip();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void flip() {
    if (_isFront) {
      _animation = Tween<double>(begin: pi, end: 0.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
      );
      _controller.forward(from: 0.0).then((_) {
        setState(() => _isFront = false);
        widget.onFlipped?.call();
      });
    } else {
      _animation = Tween<double>(begin: 0.0, end: pi).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
      );
      _controller.forward(from: 0.0).then((_) {
        setState(() => _isFront = true);
        widget.onFlipped?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: GestureDetector(
        onTap: flip,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final angle = _animation.value;
            final isUnder = (angle > pi / 2);

            // 3D Perspective Matrix Transformation
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle);

            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: isUnder
                  ? Transform(
                      // Correct mirror reflection for front face
                      transform: Matrix4.identity()..rotateY(pi),
                      alignment: Alignment.center,
                      child: OrientalCardWidget(
                        card: widget.card,
                        number: widget.number,
                        tone: widget.tone,
                        isFront: true,
                        width: widget.width,
                        height: widget.height,
                      ),
                    )
                  : OrientalCardWidget(
                      card: widget.card,
                      number: widget.number,
                      tone: widget.tone,
                      isFront: false,
                      width: widget.width,
                      height: widget.height,
                    ),
            );
          },
        ),
      ),
    );
  }
}