/// DOK-KEY Korean Particle (Josa) Auto-Correction Engine in Dart
/// Accurately resolves unicode syllable final consonants (batchim)
/// and digits 1-45 Korean phonetic pronunciation batchim:
/// {조사:이/가}, {조사:은/는}, {조사:을/를}, {조사:과/와}, {조사:으로/로}

class JosaInfo {
  final bool hasBatchim;
  final bool isRieul;

  const JosaInfo({required this.hasBatchim, required this.isRieul});
}

class KoreanJosa {
  static const Map<String, JosaInfo> _numJosaMap = {
    '0': JosaInfo(hasBatchim: true, isRieul: false), // 영 (ㅇ)
    '1': JosaInfo(hasBatchim: true, isRieul: true),  // 일 (ㄹ)
    '2': JosaInfo(hasBatchim: false, isRieul: false),// 이
    '3': JosaInfo(hasBatchim: true, isRieul: false), // 삼 (ㅁ)
    '4': JosaInfo(hasBatchim: false, isRieul: false),// 사
    '5': JosaInfo(hasBatchim: false, isRieul: false),// 오
    '6': JosaInfo(hasBatchim: true, isRieul: false), // 육 (ㄱ)
    '7': JosaInfo(hasBatchim: true, isRieul: true),  // 칠 (ㄹ)
    '8': JosaInfo(hasBatchim: true, isRieul: true),  // 팔 (ㄹ)
    '9': JosaInfo(hasBatchim: false, isRieul: false),// 구
  };

  static JosaInfo analyzeChar(String char) {
    if (char.isEmpty) {
      return const JosaInfo(hasBatchim: false, isRieul: false);
    }

    if (RegExp(r'^\d$').hasMatch(char)) {
      return _numJosaMap[char] ?? const JosaInfo(hasBatchim: false, isRieul: false);
    }

    final code = char.codeUnitAt(0);
    // Hangul Syllable Unicode range: 0xAC00 ~ 0xD7A3
    if (code >= 0xAC00 && code <= 0xD7A3) {
      final jongseongIndex = (code - 0xAC00) % 28;
      final hasBatchim = jongseongIndex > 0;
      final isRieul = (jongseongIndex == 8); // 8 is 'ㄹ'
      return JosaInfo(hasBatchim: hasBatchim, isRieul: isRieul);
    }

    // Latin alphabet rough phonetics
    final lower = char.toLowerCase();
    if ('lmnr'.contains(lower)) {
      return JosaInfo(hasBatchim: true, isRieul: 'lr'.contains(lower));
    }

    return const JosaInfo(hasBatchim: false, isRieul: false);
  }

  static String resolveJosa(String targetWord, String josaPair) {
    final cleaned = targetWord.replaceAll(RegExp(r'[\s*_`()\[\]<>]+$'), '');
    if (cleaned.isEmpty) {
      return josaPair.split('/').first;
    }

    final lastChar = cleaned[cleaned.length - 1];
    final info = analyzeChar(lastChar);
    final parts = josaPair.split('/');
    if (parts.length != 2) return josaPair;

    final first = parts[0];
    final second = parts[1];

    if (josaPair == '으로/로' || josaPair == '로/으로') {
      if (!info.hasBatchim || info.isRieul) {
        return '로';
      }
      return '으로';
    }

    return info.hasBatchim ? first : second;
  }

  static String format(String template, Map<String, dynamic> variables) {
    var result = template;
    for (final entry in variables.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value.toString());
    }

    final regex = RegExp(r'\{조사:([^}]+)\}');
    final matches = regex.allMatches(result).toList();
    if (matches.isEmpty) return result;

    final buffer = StringBuffer();
    var lastIndex = 0;

    for (final match in matches) {
      final matchIndex = match.start;
      final josaPair = match.group(1)!;
      final precedingChunk = result.substring(lastIndex, matchIndex);
      final resolved = resolveJosa(precedingChunk, josaPair);

      buffer.write(precedingChunk);
      buffer.write(resolved);
      lastIndex = match.end;
    }

    buffer.write(result.substring(lastIndex));
    return buffer.toString();
  }
}