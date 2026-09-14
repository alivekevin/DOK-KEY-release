import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../models/timelab_models.dart';
import 'velocity_grid_engine.dart';

/// 📜 9-레인 그리드 스톱워치 기록 보관함 다이얼로그 (PRO 전용)
class VelocityRecordsDialog extends StatefulWidget {
  final VelocityGridEngine engine;

  const VelocityRecordsDialog({super.key, required this.engine});

  static Future<void> show(BuildContext context, VelocityGridEngine engine) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => VelocityRecordsDialog(engine: engine),
    );
  }

  @override
  State<VelocityRecordsDialog> createState() => _VelocityRecordsDialogState();
}

class _VelocityRecordsDialogState extends State<VelocityRecordsDialog> {
  String _formatLapTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$ms';
  }

  String _formatDate(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  void _shareRecord(VelocityRecord record) {
    final sorted = [...record.results]..sort((a, b) {
        if (a.rank == null) return 1;
        if (b.rank == null) return -1;
        return a.rank!.compareTo(b.rank!);
      });

    final buffer = StringBuffer();
    buffer.writeln('⏱️ [DOK-KEY] 스톱워치 공식 기록표');
    buffer.writeln('📌 ${record.title} (${record.laneCount}인 레인)');
    buffer.writeln('📅 ${_formatDate(record.date)}');
    buffer.writeln('---------------------------');

    for (final r in sorted) {
      String rankStr = '${r.rank}위';
      if (r.rank == 1) rankStr = '🥇 1위';
      if (r.rank == 2) rankStr = '🥈 2위';
      if (r.rank == 3) rankStr = '🥉 3위';
      final lapStr = r.lapTime != null ? _formatLapTime(r.lapTime!) : '--:--.--';
      buffer.writeln('$rankStr | ${r.name} : $lapStr');
    }
    buffer.writeln('---------------------------');
    buffer.writeln('🔥 DOK-KEY 시네마틱 타임 랩에서 측정됨');

    Share.share(buffer.toString());
  }

  @override
  Widget build(BuildContext context) {
    final records = widget.engine.savedRecords;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        decoration: BoxDecoration(
          color: const Color(0xFF101522),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text('📜', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 8),
                      Text(
                        '스톱워치 기록 보관함',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Content List or Empty State
            Expanded(
              child: records.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history_toggle_off_rounded, size: 56, color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 14),
                            const Text(
                              '저장된 기록이 없습니다',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '스톱워치 완주 후 [기록 저장]을 누르면\n이곳에 영구 보관됩니다.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, idx) => _buildRecordCard(records[idx]),
                    ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Bottom Close Button
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F293D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(VelocityRecord record) {
    final sorted = [...record.results]..sort((a, b) {
        if (a.rank == null) return 1;
        if (b.rank == null) return -1;
        return a.rank!.compareTo(b.rank!);
      });

    final winner = sorted.isNotEmpty ? sorted.first : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C394F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: const TextStyle(
                        color: Color(0xFFFFE66D),
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDate(record.date)} · ${record.laneCount}인 레인',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white70, size: 18),
                    tooltip: '공유하기',
                    onPressed: () => _shareRecord(record),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                    tooltip: '기록 삭제',
                    onPressed: () => _confirmDelete(record.id),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Podium Winner Highlight Chip
          if (winner != null && winner.lapTime != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🥇', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        winner.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ],
                  ),
                  Text(
                    _formatLapTime(winner.lapTime!),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFFFE66D),
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Collapsible or Compact List of Remaining Runners
          if (sorted.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: sorted.skip(1).map((r) {
                  final lapStr = r.lapTime != null ? _formatLapTime(r.lapTime!) : '--:--.--';
                  String rankStr = '${r.rank}위';
                  if (r.rank == 2) rankStr = '🥈 2위';
                  if (r.rank == 3) rankStr = '🥉 3위';

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$rankStr ${r.name} $lapStr',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2333),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('기록 삭제', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('이 스톱워치 기록을 완전히 삭제하시겠습니까?', style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              HapticFeedback.lightImpact();
              await widget.engine.deleteRecord(id);
              if (mounted) setState(() {});
            },
            child: const Text('삭제', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
