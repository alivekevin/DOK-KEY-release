import 'dart:math';
import 'package:dokkey_app/games/kkaebi_breakout_game.dart';

void main() {
  final m = BreakoutModel(width: 400, height: 600, random: Random(1));
  m.movePaddle(200);
  m.balls.clear();
  m.balls.add(Ball(x: 200, y: m.paddleTop - 8, vx: 60, vy: 300));
  print('BEFORE: y=${m.balls.first.y} vy=${m.balls.first.vy} paddleTop=${m.paddleTop}');
  m.update(0.016);
  print('AFTER: y=${m.balls.first.y} vy=${m.balls.first.vy} lives=${m.lives}');
}
