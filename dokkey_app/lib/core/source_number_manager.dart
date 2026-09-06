import '../models/vault_models.dart';

class SourceNumberManager {
  /// Converts any integer or string to standard 2-digit format ("01" ~ "99")
  static String formatNumber(dynamic num) {
    if (num is int) {
      return num.toString().padLeft(2, '0');
    }
    final parsed = int.tryParse(num.toString()) ?? 1;
    return parsed.toString().padLeft(2, '0');
  }

  /// Adds or updates a drawn number in the source pool with fortune metadata
  static List<SourceNumberItem> addOrUpdateNumber({
    required List<SourceNumberItem> currentPool,
    required dynamic rawNumber,
    String cardId = '',
    String cardName = '',
    String timeslotId = '',
    String toneName = '',
    String toneColor = '#F0A500',
    String headline = '',
  }) {
    final formatted = formatNumber(rawNumber);
    final list = List<SourceNumberItem>.from(currentPool);
    final existingIndex = list.indexWhere((item) => item.numberStr == formatted);

    if (existingIndex != -1) {
      // Existing number: increment count and update metadata
      final existing = list[existingIndex];
      existing.count += 1;
      existing.lastAcquiredAt = DateTime.now();
      if (cardId.isNotEmpty) existing.lastCardId = cardId;
      if (cardName.isNotEmpty) existing.lastCardName = cardName;
      if (timeslotId.isNotEmpty) existing.lastTimeslotId = timeslotId;
      if (toneName.isNotEmpty) existing.lastToneName = toneName;
      if (toneColor.isNotEmpty) existing.lastToneColor = toneColor;
      if (headline.isNotEmpty) existing.lastHeadline = headline;
    } else {
      // New number item
      list.add(SourceNumberItem(
        numberStr: formatted,
        count: 1,
        lastAcquiredAt: DateTime.now(),
        lastCardId: cardId,
        lastCardName: cardName,
        lastTimeslotId: timeslotId,
        lastToneName: toneName,
        lastToneColor: toneColor,
        lastHeadline: headline,
      ));
    }

    // Sort: Pinned first, then sorted by numberStr ("01" -> "99")
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return a.numberStr.compareTo(b.numberStr);
    });

    return list;
  }
}