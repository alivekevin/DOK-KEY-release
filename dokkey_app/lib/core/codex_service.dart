import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/codex_models.dart';

class CodexService {
  static final CodexService _instance = CodexService._internal();
  factory CodexService() => _instance;
  CodexService._internal();

  List<CodexCardItem> _zodiacCards = [];
  List<CodexCardItem> _mythCards = [];
  List<CustomCodexCard> _customCards = [];
  bool _isLoaded = false;
  final ImagePicker _picker = ImagePicker();

  List<CodexCardItem> get zodiacCards => _zodiacCards;
  List<CodexCardItem> get mythCards => _mythCards;
  List<CustomCodexCard> get customCards => _customCards;
  bool get isLoaded => _isLoaded;

  static const String _customCardsKey = 'dokkey_custom_codex_cards_v4';
  static const String _unlockedCardsKey = 'dokkey_unlocked_codex_cards_v4';

  final Set<String> _unlockedCardKeys = {};

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/common/codex_metadata.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      
      final cardsMap = data['cards'] as Map<String, dynamic>? ?? {};
      final zList = cardsMap['zodiac'] as List<dynamic>? ?? [];
      final mList = cardsMap['myth'] as List<dynamic>? ?? [];

      _zodiacCards = zList.map((e) => CodexCardItem.fromJson(e as Map<String, dynamic>)).toList();
      _mythCards = mList.map((e) => CodexCardItem.fromJson(e as Map<String, dynamic>)).toList();

      await _loadCustomCards();
      await _loadUnlockedCards();
      _isLoaded = true;
    } catch (e) {
      _isLoaded = true;
    }
  }

  /// 1~99번 숫자를 1:1 도감 카드로 매핑 반환
  CodexCardItem? getCardByNumber(int number) {
    if (number >= 1 && number <= 33) {
      if (number - 1 < _zodiacCards.length) {
        return _zodiacCards[number - 1];
      }
    } else if (number >= 34 && number <= 66) {
      final mythIndex = number - 34;
      if (mythIndex < _mythCards.length) {
        return _mythCards[mythIndex];
      }
    }
    return null;
  }

  /// 열쇠 번호(1~99) 획득 시 해당 도감 카드 즉시 10년 안심 해금
  Future<bool> unlockNumber(int number) async {
    String? cardKey;
    if (number >= 1 && number <= 33) {
      cardKey = 'zodiac_$number';
    } else if (number >= 34 && number <= 66) {
      final mythSlot = number - 33;
      cardKey = 'myth_$mythSlot';
    }

    if (cardKey != null && !_unlockedCardKeys.contains(cardKey)) {
      _unlockedCardKeys.add(cardKey);
      await _persistUnlockedCards();
      return true; // Newly unlocked
    }
    return false;
  }

  bool isCardUnlocked(String tab, int slot) {
    // 1번 슬롯(기본 쥐 / 산신령)은 항상 기본 해금되거나 수집 목록 확인
    final key = '${tab}_$slot';
    return _unlockedCardKeys.contains(key);
  }

  int getUnlockedCount(String tab) {
    return _unlockedCardKeys.where((k) => k.startsWith('${tab}_')).length;
  }

  Future<void> unlockAllCards() async {
    for (int i = 1; i <= 33; i++) {
      _unlockedCardKeys.add('zodiac_$i');
      _unlockedCardKeys.add('myth_$i');
    }
    await _persistUnlockedCards();
  }

  Future<void> _loadUnlockedCards() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_unlockedCardsKey);
    if (list != null && list.isNotEmpty) {
      _unlockedCardKeys.addAll(list);
    }
  }

  /// 도감 수집 상태를 초기 리셋 (테스트용)
  Future<void> resetUnlockedCards() async {
    _unlockedCardKeys.clear();
    await _persistUnlockedCards();
  }

  Future<void> _persistUnlockedCards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_unlockedCardsKey, _unlockedCardKeys.toList());
  }

  Future<void> _loadCustomCards() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customCardsKey);
    if (raw != null) {
      try {
        final list = json.decode(raw) as List<dynamic>;
        _customCards = list.map((e) => CustomCodexCard.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _initEmptyCustomCards();
      }
    } else {
      _initEmptyCustomCards();
    }
  }

  void _initEmptyCustomCards() {
    _customCards = List.generate(
      33,
      (idx) => CustomCodexCard(slotIndex: idx, isEmpty: true),
    );
  }

  /// 스마트폰 앨범 또는 웹에서 사진을 선택하고 400x600 비율로 자동 센터 크롭하여 Base64 반환
  Future<String?> pickAndCropCardImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 2400,
        imageQuality: 90,
      );
      if (file == null) return null;

      final Uint8List rawBytes = await file.readAsBytes();
      return await cropToCardRatio400x600(rawBytes);
    } catch (e) {
      return null;
    }
  }

  /// 400x600 (가로 2 : 세로 3) 규격으로 하드웨어 가속 자동 센터 크롭 엔진
  Future<String> cropToCardRatio400x600(Uint8List rawBytes) async {
    final codec = await ui.instantiateImageCodec(rawBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final srcW = image.width.toDouble();
    final srcH = image.height.toDouble();

    // 목표 종횡비 2 : 3 (400 : 600)
    const targetAspect = 400.0 / 600.0;
    final srcAspect = srcW / srcH;

    double cropW, cropH, cropX, cropY;

    if (srcAspect > targetAspect) {
      // 가로가 더 넓은 경우 -> 좌우를 잘라내어 중앙 추출
      cropH = srcH;
      cropW = srcH * targetAspect;
      cropX = (srcW - cropW) / 2.0;
      cropY = 0.0;
    } else {
      // 세로가 더 긴 경우 -> 상하를 잘라내어 중앙 추출
      cropW = srcW;
      cropH = srcW / targetAspect;
      cropX = 0.0;
      cropY = (srcH - cropH) / 2.0;
    }

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 400, 600));

    final srcRect = ui.Rect.fromLTWH(cropX, cropY, cropW, cropH);
    const dstRect = ui.Rect.fromLTWH(0, 0, 400, 600);
    final paint = ui.Paint()..filterQuality = ui.FilterQuality.high;

    canvas.drawImageRect(image, srcRect, dstRect, paint);

    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(400, 600);
    final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return base64Encode(rawBytes);
    }

    final croppedBytes = byteData.buffer.asUint8List();
    return base64Encode(croppedBytes);
  }

  Future<void> saveCustomCard(
    int slotIndex, {
    String? localUri,
    String? imageBase64,
    required String title,
    String? memo,
  }) async {
    if (slotIndex < 0 || slotIndex >= 33) return;
    final now = DateTime.now().toIso8601String();
    final updated = CustomCodexCard(
      slotIndex: slotIndex,
      isEmpty: false,
      localImageUri: localUri,
      imageBase64: imageBase64,
      title: title,
      memo: memo,
      updatedAt: now,
    );
    _customCards[slotIndex] = updated;
    await _persistCustomCards();
  }

  Future<void> deleteCustomCard(int slotIndex) async {
    if (slotIndex < 0 || slotIndex >= 33) return;
    // Tombstone policy: keep slot index, mark as empty
    _customCards[slotIndex] = CustomCodexCard(slotIndex: slotIndex, isEmpty: true);
    await _persistCustomCards();
  }

  Future<void> _persistCustomCards() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_customCards.map((e) => e.toJson()).toList());
    await prefs.setString(_customCardsKey, encoded);
  }
}