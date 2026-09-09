import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import '../widgets/combined_key_item_widget.dart';
import '../widgets/pro_pass_dialog.dart';
import '../widgets/rotating_key_home_button.dart';
import 'card_codex_screen.dart';

/// 🔑 조합된 열쇠 보관함 (v4.1.0 Commercial)
/// - 무료 9슬롯(7일 TTL 순환) / PRO 99슬롯 대용량 확장(장기 보관)
/// - 슬롯 진행바, 삭제 2차 확인, 만료/전체 일괄 정리, 한도 도달 시 Pro 유도
class CombinedKeysScreen extends StatelessWidget {
  const CombinedKeysScreen({super.key});

  /// [💡 볼트 안내] 도움말 다이얼로그 (Zero-Login 원리 & 장기 보관 가이드)
  void _showVaultHelpDialog(BuildContext context) {
    final provider = context.read<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DokkeyTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: DokkeyTheme.gold, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: DokkeyTheme.gold),
            const SizedBox(width: 8),
            Text(
              isKo ? '💡 Zero-Login 볼트 안내' : (isJa ? '💡 ボルト案内' : '💡 Vault Guide'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHelpItem(
              icon: Icons.shield_outlined,
              title: isKo ? '완벽한 개인정보 보호 (No Server)' : '100% Privacy (Zero-Login)',
              desc: isKo
                  ? '회원가입이나 중앙 서버 없이, 모든 조합 키는 오직 내 기기 안에만 안전하게 보관됩니다.'
                  : 'No login, no server. Everything is stored locally on your device only.',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.push_pin_outlined,
              title: isKo
                  ? (provider.isProUser
                      ? '장기 보관 모드 (Pro)'
                      : '7일 자동 순환과 장기 보관 (📌)')
                  : (provider.isProUser
                      ? '10-Year Safe Lock (Pro)'
                      : '7-Day Cycle & 10-Year Safe Pin'),
              desc: isKo
                  ? (provider.isProUser
                      ? 'PRO로 조합 키가 장기 고정 보관되며, 원하지 않는 키는 언제든 개별 삭제하거나 일괄 정리할 수 있습니다.'
                      : '조합 키는 7일 후 자동 정리되어 슬롯이 순환됩니다. 마음에 드는 번호는 📌 핀 아이콘으로 장기 보관하거나 PRO로 슬롯을 99개까지 넓히세요.')
                  : (provider.isProUser
                      ? 'With the Pro Pass, keys are safely locked for 10 years. Delete or bulk-clean anytime.'
                      : 'Keys cycle out after 7 days. Pin favorites or upgrade to 99 slots with the Pro Pass.'),
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.delete_sweep_rounded,
              title: isKo ? '개별 삭제 & 일괄 정리' : 'Individual & Bulk Cleanup',
              desc: isKo
                  ? '🗑️ 버튼으로 개별 삭제(2차 확인), 우측 상단 🧹 메뉴로 만료/전체 키를 한 번에 정리할 수 있습니다. 도감 수집은 그대로 안전하게 유지됩니다.'
                  : 'Delete individually (with confirm) or bulk-clean via the 🧹 menu. Your codex collection stays 100% safe.',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.cloud_sync_outlined,
              title: isKo ? '기기 교체 & 백업/복원' : 'Backup & Restore Across Devices',
              desc: isKo
                  ? '우측 상단의 [☁️ 볼트 백업]을 누르면 백업 텍스트를 복사해 다른 기기나 브라우저로 1초 만에 복원할 수 있습니다.'
                  : 'Use [☁️ Vault Backup] to copy and restore your keys on any new device or browser instantly.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isKo ? '닫기' : 'Close', style: TextStyle(color: DokkeyTheme.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showCloudVaultBackupDialog(context);
            },
            icon: const Icon(Icons.cloud_download_rounded, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: DokkeyTheme.gold,
              foregroundColor: Colors.black,
            ),
            label: Text(
              isKo ? '지금 백업하기' : 'Backup Now',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: DokkeyTheme.goldLight, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: DokkeyTheme.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// [☁️ 볼트 백업] 실제 백업/복원 실행 다이얼로그
  void _showCloudVaultBackupDialog(BuildContext context) {
    final provider = context.read<DokkeyProvider>();
    final isKo = provider.lang == 'ko';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DokkeyTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: DokkeyTheme.gold, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.cloud_sync_outlined, color: DokkeyTheme.gold),
            const SizedBox(width: 8),
            Text(
              isKo ? 'Zero-Login 개인 볼트 백업' : 'Zero-Login Vault Backup',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isKo
                  ? '내가 완성한 소중한 조합 키와 수집 숫자를 안전하게 백업하고 복원합니다. 아래 버튼을 눌러 백업 데이터를 클립보드에 복사하세요.'
                  : 'Safely backup and restore your keys and collected numbers. Copy the backup data below to your clipboard.',
              style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final backupJson = provider.exportVaultBackup();
                Clipboard.setData(ClipboardData(text: backupJson));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isKo ? '조합 키 볼트 백업 JSON이 복사되었습니다! 📋' : 'Vault JSON copied to clipboard! 📋'),
                    backgroundColor: DokkeyTheme.surfaceDark,
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: DokkeyTheme.gold,
                foregroundColor: Colors.black,
              ),
              label: Text(
                isKo ? '볼트 백업 데이터 내보내기 (복사)' : 'Export Vault Backup',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isKo ? '닫기' : 'Close', style: TextStyle(color: DokkeyTheme.gold)),
          ),
        ],
      ),
    );
  }

  /// 개별 삭제 2차 확인 다이얼로그 (실수 방지)
  Future<void> _confirmDelete(BuildContext context, DokkeyProvider provider, String keyId) async {
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DokkeyTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: DokkeyTheme.dokFire, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: DokkeyTheme.dokFire),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isKo ? '조합 키 삭제' : (isJa ? 'キー削除' : 'Delete Key'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          isKo
              ? '이 조합 키를 삭제할까요?\n삭제 후에도 도감 수집률은 그대로 안전하게 유지됩니다.'
              : (isJa
                  ? 'このキーを削除しますか？\n図鑑コレクションはそのまま安全に保持されます。'
                  : 'Delete this combined key?\nYour codex collection stays 100% safe.'),
          style: TextStyle(color: DokkeyTheme.textMain, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isKo ? '취소' : (isJa ? 'キャンセル' : 'Cancel'),
                style: TextStyle(color: DokkeyTheme.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: DokkeyTheme.dokFire,
              foregroundColor: Colors.white,
            ),
            label: Text(isKo ? '삭제' : (isJa ? '削除' : 'Delete'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteCombinedKey(keyId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isKo ? '조합 키가 삭제되었습니다. (도감은 안전)' : 'Key deleted. (Codex safe)'),
            backgroundColor: DokkeyTheme.surfaceDark,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  /// 일괄 정리 메뉴 (만료 키 정리 / 전체 삭제)
  void _showCleanupMenu(BuildContext context, DokkeyProvider provider) {
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';
    final expiredCount = provider.expiredCombinedKeyCount;

    showModalBottomSheet(
      context: context,
      backgroundColor: DokkeyTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.cleaning_services_rounded, color: DokkeyTheme.gold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isKo ? '보관함 일괄 정리' : (isJa ? '一括整理' : 'Bulk Cleanup'),
                    style: TextStyle(
                      color: DokkeyTheme.goldLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ListTile(
                enabled: expiredCount > 0,
                leading: Icon(Icons.auto_delete_rounded,
                    color: expiredCount > 0 ? DokkeyTheme.gold : DokkeyTheme.textMuted),
                title: Text(
                  isKo
                      ? '만료된 키 정리 ($expiredCount개)'
                      : (isJa ? '期限切れキー整理 ($expiredCount)' : 'Clean expired ($expiredCount)'),
                  style: TextStyle(color: DokkeyTheme.textMain, fontSize: 13.5),
                ),
                subtitle: Text(
                  isKo ? '기간이 지난 오래된 조합 키를 한 번에 정리합니다.' : 'Remove all stale keys at once.',
                  style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                ),
                onTap: expiredCount > 0
                    ? () async {
                        final removed = await provider.clearExpiredCombinedKeys();
                        if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isKo ? '만료된 키 $removed개를 정리했습니다. 🧹' : '$removed keys cleaned. 🧹',
                              ),
                              backgroundColor: DokkeyTheme.surfaceDark,
                            ),
                          );
                        }
                      }
                    : null,
              ),
              ListTile(
                enabled: provider.combinedKeys.isNotEmpty,
                leading: Icon(Icons.delete_sweep_rounded, color: DokkeyTheme.dokFire),
                title: Text(
                  isKo ? '전체 삭제' : (isJa ? '全削除' : 'Delete All'),
                  style: TextStyle(color: DokkeyTheme.textMain, fontSize: 13.5),
                ),
                subtitle: Text(
                  isKo
                      ? '모든 조합 키를 삭제합니다. (도감은 안전하게 유지)'
                      : 'Delete all keys. (Codex stays safe)',
                  style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                ),
                onTap: provider.combinedKeys.isNotEmpty
                    ? () async {
                        // 전체 삭제는 반드시 2차 확인
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: DokkeyTheme.cardDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                              side: BorderSide(color: DokkeyTheme.dokFire, width: 1.5),
                            ),
                            title: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: DokkeyTheme.dokFire),
                                const SizedBox(width: 8),
                                Text(
                                  isKo ? '전체 삭제 확인' : (isJa ? '全削除確認' : 'Confirm Delete All'),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            content: Text(
                              isKo
                                  ? '정말 모든 조합 키를 삭제할까요?\n이 작업은 되돌릴 수 없습니다. (도감 수집은 유지)'
                                  : (isJa
                                      ? '本当にすべてのキーを削除しますか？\nこの操作は元に戻せません。（図鑑は維持）'
                                      : 'Really delete ALL keys?\nThis cannot be undone. (Codex preserved)'),
                              style: TextStyle(color: DokkeyTheme.textMain, fontSize: 13, height: 1.5),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: Text(isKo ? '취소' : 'Cancel',
                                    style: TextStyle(color: DokkeyTheme.textMuted)),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DokkeyTheme.dokFire,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(isKo ? '전체 삭제' : 'Delete All',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                        if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                        if (confirmed == true) {
                          final removed = await provider.clearAllCombinedKeys();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isKo ? '조합 키 $removed개를 전체 삭제했습니다. 🧹' : '$removed keys deleted. 🧹',
                                ),
                                backgroundColor: DokkeyTheme.surfaceDark,
                              ),
                            );
                          }
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';
    final keys = provider.combinedKeys;
    final max = provider.maxCombinedSlots;
    final usageRatio = keys.isEmpty ? 0.0 : (keys.length / max).clamp(0.0, 1.0);
    final isNearLimit = keys.length >= max - 1 && !provider.isProUser;
    final isAtLimit = keys.length >= max;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isKo
              ? '조합된 키 보관함 (${keys.length}/$max)'
              : (isJa ? '組合せキー保管箱 (${keys.length}/$max)' : 'Combined Keys (${keys.length}/$max)'),
        ),
        actions: [
          // [🎴 99 도감 바로가기]
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CardCodexScreen()),
              );
            },
            icon: Icon(Icons.menu_book_rounded, color: DokkeyTheme.goldLight),
            tooltip: isKo ? '99 그랜드 도감' : (isJa ? '99 グランド図鑑' : '99 Grand Codex'),
          ),
          // [🧹 일괄 정리] 메뉴
          IconButton(
            onPressed: () => _showCleanupMenu(context, provider),
            icon: Icon(Icons.cleaning_services_rounded, color: DokkeyTheme.gold),
            tooltip: isKo ? '일괄 정리' : (isJa ? '一括整理' : 'Bulk Cleanup'),
          ),
          // [☁️ 볼트 백업]
          IconButton(
            onPressed: () => _showCloudVaultBackupDialog(context),
            icon: Icon(Icons.cloud_download_outlined, color: DokkeyTheme.gold),
            tooltip: isKo ? '볼트 백업 / 내보내기' : 'Vault Backup',
          ),
          const RotatingKeyHomeButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: keys.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.vpn_key_off_outlined, size: 64, color: DokkeyTheme.textMuted.withOpacity(0.4)),
                    const SizedBox(height: 16),
                    Text(
                      isKo ? '아직 저장된 조합 키가 없습니다.' : 'No combined keys saved yet.',
                      style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isKo
                          ? '보관함 하단의 [연성하기] 버튼으로 첫 키를 만들어보세요!'
                          : 'Tap [Combine] in the Key Box to create your first key!',
                      style: TextStyle(color: DokkeyTheme.gold, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    // 볼트 안내 진입점 (빈 상태에서도 접근 가능)
                    TextButton.icon(
                      onPressed: () => _showVaultHelpDialog(context),
                      icon: Icon(Icons.help_outline_rounded, size: 16, color: DokkeyTheme.gold),
                      label: Text(
                        isKo ? '볼트 사용법 안내' : (isJa ? 'ボルトガイド' : 'Vault Guide'),
                        style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Subtitle guide header + Slot Progress Bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                    color: DokkeyTheme.surfaceDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isKo
                                      ? '총 ${keys.length}/$max개 조합'
                                      : '${keys.length}/$max Keys',
                                  style: TextStyle(
                                    color: DokkeyTheme.goldLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (!provider.isProUser) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => ProPassDialog.show(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: DokkeyTheme.gold.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: DokkeyTheme.gold, width: 0.8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.workspace_premium_rounded, size: 12, color: Colors.amber),
                                          SizedBox(width: 3),
                                          Text(
                                            'PRO 99',
                                            style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                if (provider.isProUser) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.amber),
                                ],
                              ],
                            ),
                            Text(
                              isKo ? '번호 터치 시 복사 📋' : 'Tap to copy 📋',
                              style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 슬롯 진행바 (한도 근접 시 경고색)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: usageRatio,
                            minHeight: 6,
                            backgroundColor: DokkeyTheme.borderDark,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isAtLimit
                                  ? DokkeyTheme.dokFire
                                  : (isNearLimit ? const Color(0xFFF0A500) : DokkeyTheme.gold),
                            ),
                          ),
                        ),
                        if (isAtLimit && !provider.isProUser) ...[
                          const SizedBox(height: 8),
                          // 무료 9/9 한도 도달 → Pro 업그레이드 유도
                          InkWell(
                            onTap: () => ProPassDialog.show(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: DokkeyTheme.dokFire.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: DokkeyTheme.dokFire.withOpacity(0.6)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.workspace_premium_rounded,
                                      color: Colors.amber, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isKo
                                          ? '무료 슬롯 9/9 꽉참! 지우거나 PRO로 99개로 확장하세요 →'
                                          : 'Free slots full (9/9)! Delete one or expand to 99 with Pro →',
                                      style: TextStyle(
                                        color: DokkeyTheme.goldLight,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 1-Line Card List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: keys.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, idx) {
                        final item = keys[idx];
                        return CombinedKeyItemWidget(
                          item: item,
                          onDelete: () => _confirmDelete(context, provider, item.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: DokkeyTheme.cardDark,
          border: Border(top: BorderSide(color: DokkeyTheme.borderDark)),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: DokkeyTheme.surfaceDark,
              foregroundColor: DokkeyTheme.textMain,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: DokkeyTheme.borderDark),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back_rounded, size: 18, color: DokkeyTheme.gold),
                const SizedBox(width: 8),
                Text(
                  isKo ? '보관함으로 돌아가기 (닫기)' : (isJa ? '保管箱に戻る (閉じる)' : 'Back to Key Box (Close)'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
