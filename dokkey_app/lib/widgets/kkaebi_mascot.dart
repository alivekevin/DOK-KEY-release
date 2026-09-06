import 'package:flutter/material.dart';
import 'kkaebi_face_widget.dart';

enum KkaebiExpression { neutral, comic, horror, hope, passion, calm, lonely, mystery }

/// 깨비 고화질 페이스 마스코트 컴포넌트 (v4.0.0)
class KkaebiMascot extends StatelessWidget {
  final double size;
  final KkaebiExpression expression;
  final bool talking;
  final Color? accent;

  const KkaebiMascot({
    super.key,
    this.size = 120,
    this.expression = KkaebiExpression.neutral,
    this.talking = false,
    this.accent,
  });

  KkaebiFaceMode get _mode {
    if (talking) return KkaebiFaceMode.talking;
    switch (expression) {
      case KkaebiExpression.comic:
      case KkaebiExpression.hope:
      case KkaebiExpression.passion:
        return KkaebiFaceMode.joy;
      case KkaebiExpression.horror:
      case KkaebiExpression.mystery:
        return KkaebiFaceMode.surprise;
      case KkaebiExpression.calm:
      case KkaebiExpression.lonely:
      case KkaebiExpression.neutral:
        return KkaebiFaceMode.idle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KkaebiFaceWidget(
      size: size,
      mode: _mode,
      enableGlow: accent != null,
      glowColor: accent,
    );
  }
}
