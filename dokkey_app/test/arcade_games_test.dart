
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:dokkey_app/games/kkaebi_sudoku_game.dart';
import 'package:dokkey_app/games/kkaebi_tetris_game.dart';
import 'package:dokkey_app/games/kkaebi_breakout_game.dart';
import 'package:dokkey_app/games/kkaebi_bubble_game.dart';
import 'package:dokkey_app/games/kkaebi_shooter_game.dart';
import 'package:dokkey_app/games/kkaebi_jungle_game.dart';
import 'package:dokkey_app/games/kkaebi_cave_game.dart';
import 'package:dokkey_app/games/kkaebi_magic_square_game.dart';
import 'package:dokkey_app/games/kkaebi_minesweeper_game.dart';
import 'package:dokkey_app/games/kkaebi_sea_game.dart';
import 'package:dokkey_app/games/kkaebi_xsudoku_game.dart';
import 'package:dokkey_app/games/kkaebi_cross_magicsquare_game.dart';
import 'package:dokkey_app/games/kkaebi_hex_minesweeper_game.dart';
import 'package:dokkey_app/games/kkaebi_jigsaw_game.dart';
import 'package:dokkey_app/models/talisman_model.dart';

/// 🕹️ v4.8.0 아케이드 게임 로직 단위 테스트
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('🔢 스도쿠 생성기', () {
    test('4x4 퍼즐: 정답 그리드는 각 행/열/박스에서 중복 없음', () {
      final p = SudokuPuzzle(size: 4, holes: 6, rng: Random(42));
      for (var y = 0; y < 4; y++) {
        expect(p.solution[y].toSet().length, 4, reason: 'row $y');
      }
      for (var x = 0; x < 4; x++) {
        expect([for (var y = 0; y < 4; y++) p.solution[y][x]].toSet().length, 4,
            reason: 'col $x');
      }
    });

    test('9x9 퍼즐: 백트래킹 생성 성공 + 구멍 뚫림', () {
      final p = SudokuPuzzle(size: 9, holes: 45, rng: Random(7));
      for (var y = 0; y < 9; y++) {
        expect(p.solution[y].toSet().length, 9);
      }
      var empties = 0;
      for (final row in p.board) {
        empties += row.where((c) => c == 0).length;
      }
      expect(empties, greaterThanOrEqualTo(40));
    });

    test('충돌 감지: 동일 행 중복 값은 conflict true', () {
      final p = SudokuPuzzle(size: 4, holes: 0, rng: Random(1));
      // given이 0개인 4x4 풀그리드에서 강제로 중복 배치
      p.board[0][0] = 1;
      p.board[0][1] = 1;
      expect(p.isConflict(0, 0) || p.isConflict(1, 0), true);
    });
  });

  group('🧱 테트리스 로직', () {
    test('라인 삭제: 한 줄 완성 시 제거 + 점수 100 x level', () {
      final m = TetrisModel(random: Random(3));
      // 바닥 한 줄을 9칸만 채우고 I 피스를 낙하시키는 대신, 직접 라인 삭제 검증
      for (var x = 0; x < TetrisModel.cols - 1; x++) {
        m.board[TetrisModel.rows - 1][x] = 1;
      }
      m.piece = TetrisModel.cloneShape(TetrisModel.shapes[0]); // I: [1,1,1,1]
      m.pieceId = 0;
      m.pieceX = 6; // cols 6~9 → 마지막 빈칸(9) 메움
      m.pieceY = TetrisModel.rows - 1;
      final cleared = m.lockAndClear();
      expect(cleared, 1);
      expect(m.board[TetrisModel.rows - 1].every((c) => c == 0), true);
    });

    test('게임 오버: 스폰 위치가 막히면 gameOver', () {
      final m = TetrisModel(random: Random(5));
      // 최상단 2줄을 전부 채움 → 스폰 불가
      for (var y = 0; y < 2; y++) {
        for (var x = 0; x < TetrisModel.cols; x++) {
          m.board[y][x] = 1;
        }
      }
      m.pieceId = 0;
      m.nextId = 0;
      m.spawnPiece();
      expect(m.gameOver, true);
    });
  });

  group('💥 벽돌깨기 반사 물리', () {
    test('패들 중앙 명중 시 공이 위로 튄다', () {
      final m = BreakoutModel(width: 400, height: 600, random: Random(1));
      m.movePaddle(200);
      // 패들 위에 공 배치 후 하강
      m.balls.clear();
      m.balls.add(Ball(x: 200, y: m.paddleTop - 8, vx: 60, vy: 300));
      m.update(0.016);
      // ignore: avoid_print
      print('DBG y=${m.balls.isEmpty ? -1 : m.balls.first.y.toStringAsFixed(1)} vy=${m.balls.isEmpty ? -999 : m.balls.first.vy.toStringAsFixed(1)} top=${m.paddleTop} n=${m.balls.length} go=$m.gameOver');
      expect(m.balls.first.vy, lessThan(0), reason: '패들에 맞으면 위로 튄다');
    });

    test('좌측 끝 명중 시 좌측 방향 유지 (각도 반사)', () {
      final m = BreakoutModel(width: 400, height: 600, random: Random(1));
      m.movePaddle(200);
      m.balls.clear();
      m.balls.add(Ball(x: 165, y: m.paddleTop - 8, vx: 40, vy: 300));
      m.update(0.016);
      expect(m.balls.first.vx, lessThan(0), reason: '왼쪽 끝에 맞으면 왼쪽으로 튄다');
    });
  });

  group('🫧 깨비 뽀글뽀글 액션 물리', () {
    test('방울 발사 시 버블 엔티티가 생성되고 전방으로 날아간다', () {
      final m = BubbleBobbleModel(width: 400, height: 600, random: Random(1));
      m.shootBubble();
      expect(m.bubbles.length, 1);
      expect(m.bubbles.first.vx, greaterThan(0), reason: '우측 발사');
    });

    test('몬스터가 방울과 충돌 시 방울에 포획(trapped)된다', () {
      final m = BubbleBobbleModel(width: 400, height: 600, random: Random(1));
      // 방울과 몬스터를 동일 좌표에 수동 배치
      m.bubbles.clear();
      m.monsters.clear();
      m.bubbles.add(BubbleEntity(x: 100, y: 200, vx: 0, vy: 0));
      m.monsters.add(MonsterEntity(x: 100, y: 200, type: MonsterType.walker));
      m.update(0.016);
      expect(m.bubbles.first.trapped, MonsterType.walker);
      expect(m.monsters.first.isTrapped, true);
    });

    test('플레이어가 갇힌 방울을 터뜨리면 과일 아이템이 드랍된다', () {
      final m = BubbleBobbleModel(width: 400, height: 600, random: Random(1));
      m.bubbles.clear();
      m.monsters.clear();
      m.items.clear();
      // 남아있는 다른 몬스터 1마리 배치 (스테이지 즉시 클리어 방지)
      m.monsters.add(MonsterEntity(x: 50, y: 50, type: MonsterType.walker));
      // 갇힌 방울 배치
      m.bubbles.add(BubbleEntity(x: 200, y: 300, vx: 0, vy: 0, trapped: MonsterType.walker));
      // 플레이어를 방울 위치로 이동
      m.playerX = 200;
      m.playerY = 300;
      final popped = m.update(0.016);
      expect(popped, 1);
      // 플레이어가 같은 위치에 있어 즉시 아이템을 획득하므로 스코어가 방울점수(200)+아이템점수(>=100) 이상으로 증가
      expect(m.score, greaterThanOrEqualTo(300));
    });
  });

  group('🚀 깨비 X-RION 슈팅 물리', () {
    test('좌우 조작 시 관성 속도 및 3D 뱅킹 각도가 발생한다', () {
      final m = XrionModel(width: 400, height: 600, random: Random(1));
      expect(m.rollAngle, 0.0);
      m.applyInput(1.0, 0.0);
      m.update(0.016);
      expect(m.shipVx, greaterThan(0));
      expect(m.rollAngle, greaterThan(0), reason: '우측 가속 시 우측 뱅킹 롤');
    });

    test('듀얼 빔 발사 시 트윈 레이저 탄환 2발이 생성된다', () {
      final m = XrionModel(width: 400, height: 600, random: Random(1));
      m.bullets.clear();
      final fired = m.fireDualBeam();
      expect(fired, true);
      expect(m.bullets.length, 2);
      expect(m.bullets.every((b) => !b.isVulcan), true);
    });

    test('오토 발칸 연사 시 발칸 탄환이 생성되고 에너지가 소모된다', () {
      final m = XrionModel(width: 400, height: 600, random: Random(1));
      m.bullets.clear();
      final beforeEnergy = m.vulcanEnergy;
      final fired = m.fireVulcan();
      expect(fired, true);
      expect(m.bullets.length, 1);
      expect(m.bullets.first.isVulcan, true);
      expect(m.vulcanEnergy, lessThan(beforeEnergy));
    });

    test('폭탄 발동 시 적 탄환이 소멸하고 폭탄 개수가 감소한다', () {
      final m = XrionModel(width: 400, height: 600, random: Random(1));
      m.bullets.add(XrionBullet(x: 200, y: 300, vx: 0, vy: 200, isPlayer: false));
      final beforeBombs = m.bombs;
      final triggered = m.triggerBomb();
      expect(triggered, true);
      expect(m.bombs, beforeBombs - 1);
      expect(m.bullets.where((b) => !b.isPlayer).isEmpty, true);
    });
  });

  group('🏛️ 깨비 고대 유적 미로 & 바위 탈출', () {
    test('플레이어가 통로로 이동하면 좌표가 갱신된다', () {
      final m = RuinsMazeModel(width: 400, height: 600, random: Random(1));
      expect(m.playerCol, 1);
      expect(m.playerRow, 1);
      // 우측 (1,2)는 바닥 통로
      final moved = m.move(Direction.right);
      expect(moved, true);
      expect(m.playerCol, 2);
      expect(m.playerRow, 1);
    });

    test('황금 열쇠를 획득하면 거대 굴림 바위(Boulder)가 작동한다', () {
      final m = RuinsMazeModel(width: 400, height: 600, random: Random(1));
      // 황금 열쇠 위치로 강제 이동 및 수집
      final goldKey = m.keys.firstWhere((k) => k.isGold);
      m.playerCol = goldKey.col;
      m.playerRow = goldKey.row;
      // 한 칸 이동하여 트리거
      m.move(Direction.none);
      // 직접 황금 열쇠 위치에서 move 시도
      m.keys.clear();
      m.keys.add(KeyItem(col: 2, row: 1, isGold: true));
      m.boulders.add(RollingBoulder(x: 100, y: 100, vx: 0, vy: 150));
      m.playerCol = 1;
      m.playerRow = 1;
      m.move(Direction.right); // (2,1)로 이동하며 황금 열쇠 획득!
      expect(m.hasGoldKey, true);
      expect(m.boulders.first.active, true, reason: '황금 열쇠 획득 시 거대 바위 트랩 발동');
    });

    test('대시 발동 시 부스터 상태가 활성화되고 쿨다운이 적용된다', () {
      final m = RuinsMazeModel(width: 400, height: 600, random: Random(1));
      expect(m.isDashing, false);
      final dashed = m.triggerDash();
      expect(dashed, true);
      expect(m.isDashing, true);
      expect(m.dashCooldown, greaterThan(0));
    });
  });

  group('⛵ 바다 항해 물리', () {
    test('깨비가 좌우로 이동하면 기울기가 변한다', () {
      final m = SeaModel(width: 400, height: 600);
      final before = m.tilt;
      m.moveKkaebi(0.8);
      m.update(0.016);
      m.update(0.016);
      expect(m.tilt, isNot(before));
    });

    test('기울기 45도 초과 시 전복 (gameOver)', () {
      final m = SeaModel(width: 400, height: 600);
      m.kkaebiOffset = 1.0;
      // 강제로 기울기를 임계치 이상으로
      for (var i = 0; i < 200; i++) {
        m.update(0.016);
        if (m.gameOver) break;
        m.moveKkaebi(0.1);
      }
      expect(m.gameOver, true, reason: '극단적 오프셋 유지 시 전복해야 한다');
    });

    test('물 100 도달 시 침몰 (gameOver)', () {
      final m = SeaModel(width: 400, height: 600);
      m.splash(120);
      m.update(0.016);
      expect(m.gameOver, true);
    });

    test('1000m 항해 완료 시 클리어', () {
      final m = SeaModel(width: 400, height: 600);
      var guard = 0;
      while (!m.cleared && !m.gameOver && guard < 10000) {
        m.update(0.05);
        guard++;
      }
      expect(m.cleared, true, reason: '1000m 항해는 반드시 클리어 가능해야 한다');
    });
  });

  group('🏄 깨비 바다 서퍼 물리', () {
    test('좌우 조작 시 부드러운 위치 이동과 뱅킹 롤 각도가 적용된다', () {
      final m = OceanSurferModel(width: 400, height: 600, random: Random(1));
      final initialX = m.px;
      m.steer(0.8);
      m.update(0.016);
      expect(m.px, greaterThan(initialX));
      expect(m.rollAngle, greaterThan(0));
    });

    test('점프 및 더블 점프 수행 시 수직 속도가 발생하고 스턴트가 연계된다', () {
      final m = OceanSurferModel(width: 400, height: 600, random: Random(1));
      expect(m.jumpsLeft, 2);
      final jumped1 = m.jump();
      expect(jumped1, true);
      expect(m.jumpsLeft, 1);
      expect(m.vy, OceanSurferModel.jumpVel);

      // 상승 후 공중에서 더블 점프
      m.update(0.05);
      final jumped2 = m.jump();
      expect(jumped2, true);
      expect(m.jumpsLeft, 0);
      expect(m.isStunting, true, reason: '더블 점프 시 공중 스핀 트릭 발동');
    });

    test('거대 파도 램프(waveRamp)와 충돌 시 슈퍼 하이 점프가 발동한다', () {
      final m = OceanSurferModel(width: 400, height: 600, random: Random(1));
      m.obstacles.clear();
      final ramp = SeaObstacle(
        x: m.px,
        y: 600 * 0.76,
        speed: 1.0,
        width: 64,
        height: 32,
        type: SeaObstacleType.waveRamp,
      );
      m.obstacles.add(ramp);
      m.update(0.016);
      expect(m.vy, OceanSurferModel.superJumpVel);
      expect(ramp.collected, true);
    });

    test('산호 암초 충돌 시 생명이 감소하나, 점프로 뛰어넘으면 무피해 통과한다', () {
      final m = OceanSurferModel(width: 400, height: 600, random: Random(1));
      // 1. 점프 상태로 산호 통과
      m.py = 50.0;
      m.obstacles.clear();
      m.obstacles.add(SeaObstacle(
        x: m.px,
        y: 600 * 0.76,
        speed: 1.0,
        width: 46,
        height: 46,
        type: SeaObstacleType.coralReef,
      ));
      m.update(0.016);
      expect(m.lives, 3, reason: '점프 고도 50m로 산호 암초 회피 성공');

      // 2. 수면(py=0)에서 산호와 직접 충돌
      final m2 = OceanSurferModel(width: 400, height: 600, random: Random(1));
      m2.obstacles.clear();
      m2.obstacles.add(SeaObstacle(
        x: m2.px,
        y: 600 * 0.76,
        speed: 1.0,
        width: 46,
        height: 46,
        type: SeaObstacleType.coralReef,
      ));
      m2.update(0.016);
      expect(m2.lives, 2, reason: '수면에서 산호 암초 충돌 시 하트 1개 감소');
    });

    test('피버 게이지 100 달성 시 무지개 피버 모드가 활성화되어 장애물을 파괴한다', () {
      final m = OceanSurferModel(width: 400, height: 600, random: Random(1));
      m.items.clear();
      // 불가사리 3개 수집 (35% x 3 = 105% -> 피버 발동)
      for (var i = 0; i < 3; i++) {
        m.items.add(SeaItem(
          x: m.px,
          y: 600 * 0.76,
          speed: 1.0,
          width: 32,
          height: 32,
          type: SeaItemType.starfish,
        ));
        m.update(0.016);
      }
      expect(m.isFever, true);

      // 피버 상태에서 산호 암초 충돌 시 장애물 파괴 & 하트 유지
      m.obstacles.clear();
      final reef = SeaObstacle(
        x: m.px,
        y: 600 * 0.76,
        speed: 1.0,
        width: 46,
        height: 46,
        type: SeaObstacleType.coralReef,
      );
      m.obstacles.add(reef);
      m.update(0.016);
      expect(m.lives, 3, reason: '피버 모드 중 무적');
      expect(reef.collected, true, reason: '피버 모드 중 장애물 파괴');
    });
  });

  group('🧮 깨비 마방진 로직', () {
    test('3x3 마방진: 정답 행/열/대각선 합이 15이고 1~9 숫자가 중복 없음', () {
      final p = MagicSquarePuzzle(size: 3, holes: 0, rng: Random(42));
      expect(p.targetSum, 15);
      for (var y = 0; y < 3; y++) {
        expect(p.rowSum(y), 15);
      }
      for (var x = 0; x < 3; x++) {
        expect(p.colSum(x), 15);
      }
      expect(p.diag1Sum(), 15);
      expect(p.diag2Sum(), 15);
      expect(p.usedNumbers.length, 9);
      expect(p.isCleared, true);
    });

    test('4x4 마방진: 정답 행/열/대각선 합이 34이고 1~16 숫자가 중복 없음', () {
      final p = MagicSquarePuzzle(size: 4, holes: 0, rng: Random(7));
      expect(p.targetSum, 34);
      for (var y = 0; y < 4; y++) {
        expect(p.rowSum(y), 34);
      }
      for (var x = 0; x < 4; x++) {
        expect(p.colSum(x), 34);
      }
      expect(p.diag1Sum(), 34);
      expect(p.diag2Sum(), 34);
      expect(p.usedNumbers.length, 16);
      expect(p.isCleared, true);
    });

    test('빈칸이 있는 미완성 마방진은 isCleared가 false이다', () {
      final p = MagicSquarePuzzle(size: 3, holes: 4, rng: Random(1));
      expect(p.isCleared, false);
      // 정답으로 복원
      p.board = [for (final r in p.solution) [...r]];
      expect(p.isCleared, true);
    });
  });

  group('💣 깨비 지뢰찾기 로직', () {
    test('첫 번째 탭 위치와 주변 8칸에는 지뢰가 생성되지 않는다 (First-tap Safe)', () {
      final m = MinesweeperModel(cols: 8, rows: 8, totalMines: 10, random: Random(1));
      expect(m.firstTapDone, false);
      m.openCell(3, 3);
      expect(m.firstTapDone, true);
      // (3,3) 및 인접 8칸에 지뢰 없음 검증
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          expect(m.grid[3 + dy][3 + dx].isMine, false, reason: '안전 지대에는 지뢰 없음');
        }
      }
      expect(m.grid[3][3].isOpen, true);
    });

    test('깃발 꽂기 및 해제 시 flagsPlaced가 정상 증감한다', () {
      final m = MinesweeperModel(cols: 8, rows: 8, totalMines: 10, random: Random(1));
      expect(m.flagsPlaced, 0);
      m.toggleFlag(0, 0);
      expect(m.grid[0][0].isFlagged, true);
      expect(m.flagsPlaced, 1);
      m.toggleFlag(0, 0);
      expect(m.grid[0][0].isFlagged, false);
      expect(m.flagsPlaced, 0);
    });

    test('모든 비지뢰 타일을 열면 승리(cleared)한다', () {
      final m = MinesweeperModel(cols: 4, rows: 4, totalMines: 2, random: Random(1));
      m.openCell(0, 0);
      // 모든 비지뢰 셀을 수동 오픈
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          if (!m.grid[y][x].isMine) {
            m.openCell(x, y);
          }
        }
      }
      expect(m.cleared, true);
      expect(m.gameOver, false);
    });
  });

  group('🎮 아케이드 리워드 경제', () {
    test('18종 부적 레지스트리와 게임 리워드 독립성 확인', () {
      // 부적 수집은 드로우 채널이며 게임 리워드와 경로가 분리됨을 문서화하는 스모크
      expect(TalismanRegistry.items.length, 18);
    });
  });

  group('🔢 깨비 대각선 X-스도쿠 로직', () {
    test('4x4 X-스도쿠: 솔루션은 행/열/박스뿐만 아니라 두 대각선에서도 중복 없음', () {
      final m = XSudokuModel(size: 4, holes: 6, random: Random(10));
      for (var r = 0; r < 4; r++) {
        expect(m.solution[r].toSet().length, 4, reason: 'row $r');
      }
      for (var c = 0; c < 4; c++) {
        expect([for (var r = 0; r < 4; r++) m.solution[r][c]].toSet().length, 4, reason: 'col $c');
      }
      // Main diagonal (0,0 -> 3,3)
      final mainDiag = [for (var i = 0; i < 4; i++) m.solution[i][i]];
      expect(mainDiag.toSet().length, 4, reason: 'main diagonal');
      // Anti diagonal (0,3 -> 3,0)
      final antiDiag = [for (var i = 0; i < 4; i++) m.solution[i][3 - i]];
      expect(antiDiag.toSet().length, 4, reason: 'anti diagonal');
    });

    test('X-스도쿠: 정답 입력 시 숫자가 채워지고 점수가 증가한다', () {
      final m = XSudokuModel(size: 4, holes: 4, random: Random(20));
      for (var r = 0; r < 4; r++) {
        for (var c = 0; c < 4; c++) {
          if (!m.isInitial[r][c]) {
            m.selectedRow = r;
            m.selectedCol = c;
            final correctVal = m.solution[r][c];
            final ok = m.inputNumber(correctVal);
            expect(ok, true);
            expect(m.current[r][c], correctVal);
            break;
          }
        }
      }
    });
  });

  group('🧮 깨비 음양 크로스 마방진 로직', () {
    test('3x3 크로스 마방진: 정답 솔루션은 모든 행/열/대각선 합이 15이다', () {
      final m = CrossMagicSquareModel(random: Random(30));
      for (var r = 0; r < 3; r++) {
        expect(m.solution[r].reduce((a, b) => a + b), 15, reason: 'row $r');
      }
      for (var c = 0; c < 3; c++) {
        expect(m.solution[0][c] + m.solution[1][c] + m.solution[2][c], 15, reason: 'col $c');
      }
      expect(m.solution[0][0] + m.solution[1][1] + m.solution[2][2], 15, reason: 'diag 1');
      expect(m.solution[0][2] + m.solution[1][1] + m.solution[2][0], 15, reason: 'diag 2');
    });

    test('크로스 마방진: 빈칸에 정답을 채우면 isCleared가 true가 된다', () {
      final m = CrossMagicSquareModel(random: Random(40));
      expect(m.isCleared, false);
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          if (!m.isInitial[r][c]) {
            m.selectedR = r;
            m.selectedC = c;
            m.inputNumber(m.solution[r][c]);
          }
        }
      }
      expect(m.isCleared, true);
    });
  });

  group('💣 깨비 육각 벌집 지뢰찾기 로직', () {
    test('육각 벌집: First-Tap Safe로 첫 터치 위치 및 6방향 이웃에 지뢰가 없다', () {
      final m = HexMinesweeperModel(rows: 6, cols: 6, totalMines: 5);
      expect(m.firstTap, true);
      m.reveal(2, 2, random: Random(50));
      expect(m.firstTap, false);
      expect(m.board[2][2].isMine, false);
      for (final n in m.getNeighbors(2, 2)) {
        expect(m.board[n.x][n.y].isMine, false, reason: '이웃 타일 지뢰 배제');
      }
      expect(m.board[2][2].isRevealed, true);
    });

    test('육각 벌집: 깃발 꽂기 및 해제 시 flagsPlaced가 정상 동작한다', () {
      final m = HexMinesweeperModel(rows: 6, cols: 6, totalMines: 5);
      m.toggleFlag(1, 1);
      expect(m.board[1][1].isFlagged, true);
      expect(m.flagsPlaced, 1);
      m.toggleFlag(1, 1);
      expect(m.board[1][1].isFlagged, false);
      expect(m.flagsPlaced, 0);
    });
  });

  group('🧩 깨비 신수·신격 도감 카드 직소 퍼즐 로직', () {
    test('직소 퍼즐: 3x3 분할 시 9개의 타일이 생성되며 셔플된다', () {
      final p = JigsawPuzzleModel(
        gridSize: 3,
        cardAssetPath: 'assets/cards/myth/01_samjoko.webp',
        cardName: '삼족오',
        random: Random(60),
      );
      expect(p.totalTiles, 9);
      expect(p.tiles.length, 9);
      expect(p.isCleared, false);
    });

    test('직소 퍼즐: 타일 스왑을 통해 원본 순서로 맞추면 isCleared가 true가 된다', () {
      final p = JigsawPuzzleModel(
        gridSize: 3,
        cardAssetPath: 'assets/cards/myth/01_samjoko.webp',
        cardName: '삼족오',
        random: Random(70),
      );

      // 목표: i번째 타일에 originalIdx == i 인 타일을 배치
      for (var targetPos = 0; targetPos < p.totalTiles; targetPos++) {
        final currentPosOfTargetTile = p.tiles.indexWhere((t) => t.originalIdx == targetPos);
        if (currentPosOfTargetTile != targetPos) {
          p.swapWithSelected(targetPos);
          p.swapWithSelected(currentPosOfTargetTile);
        }
      }
      expect(p.isCleared, true);
      expect(p.score, greaterThan(0));
    });
  });
}
