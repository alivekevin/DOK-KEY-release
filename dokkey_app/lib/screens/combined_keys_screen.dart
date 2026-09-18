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
    final lang = provider.lang;
    final isPro = provider.isProUser;

    final String dialogTitle = switch (lang) {
      'ja' => '💡 Zero-Login 保管箱案内',
      'zh' => '💡 零登录保险库指南',
      'de' => '💡 Zero-Login Tresor-Leitfaden',
      'hi' => '💡 जीरो-लॉगिन वॉल्ट गाइड',
      'en' => '💡 Zero-Login Vault Guide',
      _ => '💡 Zero-Login 볼트 안내',
    };

    final String pTitle = switch (lang) {
      'ja' => '完全なプライバシー保護 (No Server)',
      'zh' => '完全隐私保护 (无服务器)',
      'de' => '100% Privatsphäre (Kein Server)',
      'hi' => '100% गोपनीयता (कोई सर्वर नहीं)',
      'en' => '100% Privacy (Zero-Login)',
      _ => '완벽한 개인정보 보호 (No Server)',
    };
    final String pDesc = switch (lang) {
      'ja' => '会員登録や中央サーバー不要で、すべての鍵は端末内にのみ安全に保管されます。',
      'zh' => '无需注册或中央服务器，所有组合钥匙仅安全保存在您的设备上。',
      'de' => 'Kein Login, kein Server. Alles wird nur sicher auf deinem Gerät gespeichert.',
      'hi' => 'कोई लॉगिन या सर्वर नहीं। सब कुछ केवल आपके डिवाइस पर सुरक्षित रूप से संग्रहीत है।',
      'en' => 'No login, no server. Everything is stored locally on your device only.',
      _ => '회원가입이나 중앙 서버 없이, 모든 조합 키는 오직 내 기기 안에만 안전하게 보관됩니다.',
    };

    final String rTitle = isPro
        ? switch (lang) {
            'ja' => '長期保管モード (Pro)',
            'zh' => '长期保存模式 (Pro)',
            'de' => '10-Jahre Tresor (Pro)',
            'hi' => 'दीर्घकालिक वॉल्ट (Pro)',
            'en' => '10-Year Safe Lock (Pro)',
            _ => '장기 보관 모드 (Pro)',
          }
        : switch (lang) {
            'ja' => '7日自動循環と長期保管 (📌)',
            'zh' => '7天自动循环与长期保存 (📌)',
            'de' => '7-Tage-Zyklus & 10-Jahre-Pin (📌)',
            'hi' => '7-दिवसीय चक्र और 10-वर्षीय पिन (📌)',
            'en' => '7-Day Cycle & 10-Year Safe Pin',
            _ => '7일 자동 순환과 장기 보관 (📌)',
          };

    final String rDesc = isPro
        ? switch (lang) {
            'ja' => 'PROで組合せキーが長期安全保管され、不要なキーはいつでも削除・整理できます。',
            'zh' => 'PRO模式下组合钥匙可长期安全保存，随时可单项删除或批量整理。',
            'de' => 'Mit Pro Pass bleiben Schlüssel 10 Jahre sicher gespeichert. Jederzeit löschen oder bereinigen.',
            'hi' => 'प्रो पास के साथ कुंजियाँ 10 साल तक सुरक्षित रहती हैं। कभी भी हटाएं।',
            'en' => 'With the Pro Pass, keys are safely locked for 10 years. Delete or bulk-clean anytime.',
            _ => 'PRO로 조합 키가 장기 고정 보관되며, 원하지 않는 키는 언제든 개별 삭제하거나 일괄 정리할 수 있습니다.',
          }
        : switch (lang) {
            'ja' => 'キーは7日後に自動整理されます。お気に入りは📌ピン留めするか、PROで99スロットに拡張してください。',
            'zh' => '钥匙将在7天后自动整理循环。喜欢的话请用📌固定或升级PRO扩至99槽位。',
            'de' => 'Schlüssel verfallen nach 7 Tagen. Favoriten anpinnen oder mit Pro Pass auf 99 Plätze erweitern.',
            'hi' => 'कुंजियाँ 7 दिनों के बाद साफ़ हो जाती हैं। पसंदीदा को पिन करें या 99 स्लॉट पाएँ।',
            'en' => 'Keys cycle out after 7 days. Pin favorites or upgrade to 99 slots with the Pro Pass.',
            _ => '조합 키는 7일 후 자동 정리되어 슬롯이 순환됩니다. 마음에 드는 번호는 📌 핀 아이콘으로 장기 보관하거나 PRO로 슬롯을 99개까지 넓히세요.',
          };

    final String cTitle = switch (lang) {
      'ja' => '個別削除・一括整理',
      'zh' => '单项删除与批量整理',
      'de' => 'Einzel- & Massenlöschung',
      'hi' => 'व्यक्तिगत व बल्क सफ़ाई',
      'en' => 'Individual & Bulk Cleanup',
      _ => '개별 삭제 & 일괄 정리',
    };
    final String cDesc = switch (lang) {
      'ja' => '🗑️ボタンで個別削除、右上の🧹メニューで一括整理できます。図鑑コレクションは安全に保持されます。',
      'zh' => '🗑️按钮单独删除，右上角🧹菜单一键整理。图鉴收藏始终安全保留。',
      'de' => 'Einzeln löschen oder über das 🧹-Menü aufräumen. Deine Codex-Sammlung bleibt zu 100% sicher.',
      'hi' => 'व्यक्तिगत रूप से हटाएं या 🧹 मेनू से साफ़ करें। आपका कोडेक्स 100% सुरक्षित रहता है।',
      'en' => 'Delete individually (with confirm) or bulk-clean via the 🧹 menu. Your codex collection stays 100% safe.',
      _ => '🗑️ 버튼으로 개별 삭제(2차 확인), 우측 상단 🧹 메뉴로 만료/전체 키를 한 번에 정리할 수 있습니다. 도감 수집은 그대로 안전하게 유지됩니다.',
    };

    final String bTitle = switch (lang) {
      'ja' => '端末移行・バックアップ/復元',
      'zh' => '设备更换与备份/恢复',
      'de' => 'Gerätewechsel & Backup/Wiederherstellung',
      'hi' => 'डिवाइस बैकअप और रीस्टोर',
      'en' => 'Backup & Restore Across Devices',
      _ => '기기 교체 & 백업/복원',
    };
    final String bDesc = switch (lang) {
      'ja' => '右上の[☁️ バックアップ]でデータをコピーし、他端末やブラウザへ即時復元可能です。',
      'zh' => '点击右上角[☁️ 保险库备份]复制文本，即可在其他设备或浏览器秒级恢复。',
      'de' => 'Nutze [☁️ Tresor-Backup], um deine Schlüssel sofort auf jedem neuen Gerät oder Browser wiederherzustellen.',
      'hi' => '[☁️ वॉल्ट बैकअप] का उपयोग करके नए डिवाइस या ब्राउज़र पर तुरंत रीस्टोर करें।',
      'en' => 'Use [☁️ Vault Backup] to copy and restore your keys on any new device or browser instantly.',
      _ => '우측 상단의 [☁️ 볼트 백업]을 누르면 백업 텍스트를 복사해 다른 기기나 브라우저로 1초 만에 복원할 수 있습니다.',
    };

    final String closeLabel = switch (lang) {
      'ja' => '閉じる',
      'zh' => '关闭',
      'de' => 'Schließen',
      'hi' => 'बंद करें',
      'en' => 'Close',
      _ => '닫기',
    };
    final String backupNowLabel = switch (lang) {
      'ja' => '今すぐバックアップ',
      'zh' => '立即备份',
      'de' => 'Jetzt sichern',
      'hi' => 'अभी बैकअप लें',
      'en' => 'Backup Now',
      _ => '지금 백업하기',
    };

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
              dialogTitle,
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
              title: pTitle,
              desc: pDesc,
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.push_pin_outlined,
              title: rTitle,
              desc: rDesc,
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.delete_sweep_rounded,
              title: cTitle,
              desc: cDesc,
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.cloud_sync_outlined,
              title: bTitle,
              desc: bDesc,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(closeLabel, style: TextStyle(color: DokkeyTheme.textMuted)),
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
              backupNowLabel,
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
    final lang = provider.lang;

    final title = switch (lang) {
      'ja' => 'Zero-Login 個人保管箱バックアップ',
      'zh' => 'Zero-Login 个人保险库备份',
      'de' => 'Zero-Login Persönliches Tresor-Backup',
      'hi' => 'जीरो-लॉगिन व्यक्तिगत वॉल्ट बैकअप',
      'en' => 'Zero-Login Personal Vault Backup',
      _ => 'Zero-Login 개인 볼트 백업',
    };
    final desc = switch (lang) {
      'ja' => '完成させた大切な組合せキーと収集数字を安全にバックアップ・復元します。下のボタンでデータをクリップボードにコピーしてください。',
      'zh' => '安全备份和恢复您收集的组合钥匙和数字。点击下方按钮将备份数据复制到剪贴板。',
      'de' => 'Sichere und stelle deine wertvollen Schlüssel und gesammelten Zahlen wieder her. Kopiere das Backup mit dem Button unten in die Zwischenablage.',
      'hi' => 'अपनी मूल्यवान कुंजियों और संख्याओं का बैकअप लें व रीस्टोर करें। नीचे दिए गए बटन से डेटा कॉपी करें।',
      'en' => 'Safely backup and restore your keys and collected numbers. Copy the backup data below to your clipboard.',
      _ => '내가 완성한 소중한 조합 키와 수집 숫자를 안전하게 백업하고 복원합니다. 아래 버튼을 눌러 백업 데이터를 클립보드에 복사하세요.',
    };
    final exportLabel = switch (lang) {
      'ja' => '保管箱データを書き出し (コピー)',
      'zh' => '导出保险库数据 (复制)',
      'de' => 'Tresordaten exportieren (Kopieren)',
      'hi' => 'वॉल्ट डेटा निर्यात करें (कॉपी)',
      'en' => 'Export Vault Backup',
      _ => '볼트 백업 데이터 내보내기 (복사)',
    };
    final copiedToast = switch (lang) {
      'ja' => '保管箱バックアップJSONをコピーしました！📋',
      'zh' => '保险库备份JSON已复制！📋',
      'de' => 'Tresor-Backup JSON kopiert! 📋',
      'hi' => 'वॉल्ट बैकअप JSON कॉपी हो गया! 📋',
      'en' => 'Vault JSON copied to clipboard! 📋',
      _ => '조합 키 볼트 백업 JSON이 복사되었습니다! 📋',
    };
    final closeLabel = switch (lang) {
      'ja' => '閉じる',
      'zh' => '关闭',
      'de' => 'Schließen',
      'hi' => 'बंद करें',
      'en' => 'Close',
      _ => '닫기',
    };

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
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              desc,
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
                    content: Text(copiedToast),
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
                exportLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(closeLabel, style: TextStyle(color: DokkeyTheme.gold)),
          ),
        ],
      ),
    );
  }

  /// 개별 삭제 2차 확인 다이얼로그 (실수 방지)
  Future<void> _confirmDelete(BuildContext context, DokkeyProvider provider, String keyId) async {
    final lang = provider.lang;

    final delTitle = switch (lang) {
      'ja' => 'キー削除',
      'zh' => '删除钥匙',
      'de' => 'Schlüssel löschen',
      'hi' => 'कुंजी हटाएं',
      'en' => 'Delete Key',
      _ => '조합 키 삭제',
    };
    final delContent = switch (lang) {
      'ja' => 'この組合せキーを削除しますか？\n削除後も図鑑コレクションはそのまま安全に保持されます。',
      'zh' => '确定删除此组合钥匙吗？\n删除后图鉴收藏仍会安全保留。',
      'de' => 'Diesen Schlüssel löschen?\nDeine Codex-Sammlung bleibt dabei sicher erhalten.',
      'hi' => 'क्या आप इस कुंजी को हटाना चाहते हैं?\nहटाने के बाद भी आपका कोडेक्स सुरक्षित रहेगा।',
      'en' => 'Delete this combined key?\nYour codex collection stays 100% safe.',
      _ => '이 조합 키를 삭제할까요?\n삭제 후에도 도감 수집률은 그대로 안전하게 유지됩니다.',
    };
    final cancelLabel = switch (lang) {
      'ja' => 'キャンセル',
      'zh' => '取消',
      'de' => 'Abbrechen',
      'hi' => 'रद्द करें',
      'en' => 'Cancel',
      _ => '취소',
    };
    final deleteLabel = switch (lang) {
      'ja' => '削除',
      'zh' => '删除',
      'de' => 'Löschen',
      'hi' => 'हटाएं',
      'en' => 'Delete',
      _ => '삭제',
    };
    final deletedToast = switch (lang) {
      'ja' => 'キーを削除しました。（図鑑は安全）',
      'zh' => '组合钥匙已删除。（图鉴已安全保留）',
      'de' => 'Schlüssel gelöscht. (Codex bleibt sicher)',
      'hi' => 'कुंजी हटा दी गई। (कोडेक्स सुरक्षित)',
      'en' => 'Key deleted. (Codex safe)',
      _ => '조합 키가 삭제되었습니다. (도감은 안전)',
    };

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
                delTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          delContent,
          style: TextStyle(color: DokkeyTheme.textMain, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel, style: TextStyle(color: DokkeyTheme.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: DokkeyTheme.dokFire,
              foregroundColor: Colors.white,
            ),
            label: Text(deleteLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteCombinedKey(keyId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deletedToast),
            backgroundColor: DokkeyTheme.surfaceDark,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  /// 일괄 정리 메뉴 (만료 키 정리 / 전체 삭제)
  void _showCleanupMenu(BuildContext context, DokkeyProvider provider) {
    final lang = provider.lang;
    final expiredCount = provider.expiredCombinedKeyCount;

    final menuTitle = switch (lang) {
      'ja' => '保管箱一括整理',
      'zh' => '保险库一键整理',
      'de' => 'Tresor aufräumen',
      'hi' => 'वॉल्ट की सफ़ाई',
      'en' => 'Bulk Cleanup',
      _ => '보관함 일괄 정리',
    };
    final cleanExpTitle = switch (lang) {
      'ja' => '期限切れキー整理 ($expiredCount個)',
      'zh' => '整理过期钥匙 ($expiredCount个)',
      'de' => 'Abgelaufene löschen ($expiredCount)',
      'hi' => 'समाप्त कुंजियाँ साफ़ करें ($expiredCount)',
      'en' => 'Clean expired ($expiredCount)',
      _ => '만료된 키 정리 ($expiredCount개)',
    };
    final cleanExpSub = switch (lang) {
      'ja' => '期間が過ぎた古い組合せキーを一度に整理します。',
      'zh' => '一键清理所有过期的旧组合钥匙。',
      'de' => 'Entfernt alle abgelaufenen Schlüssel auf einmal.',
      'hi' => 'पुरानी समाप्त कुंजियों को एक साथ साफ़ करें।',
      'en' => 'Remove all stale keys at once.',
      _ => '기간이 지난 오래된 조합 키를 한 번에 정리합니다.',
    };
    final delAllTitle = switch (lang) {
      'ja' => '全削除',
      'zh' => '全部删除',
      'de' => 'Alles löschen',
      'hi' => 'सभी हटाएं',
      'en' => 'Delete All',
      _ => '전체 삭제',
    };
    final delAllSub = switch (lang) {
      'ja' => 'すべての組合せキーを削除します。（図鑑は維持）',
      'zh' => '删除所有组合钥匙。（图鉴安全保留）',
      'de' => 'Löscht alle Schlüssel. (Codex bleibt erhalten)',
      'hi' => 'सभी कुंजियाँ हटाएं। (कोडेक्स सुरक्षित)',
      'en' => 'Delete all keys. (Codex stays safe)',
      _ => '모든 조합 키를 삭제합니다. (도감은 안전하게 유지)',
    };

    final confirmAllTitle = switch (lang) {
      'ja' => '全削除の確認',
      'zh' => '确认全部删除',
      'de' => 'Gesamtlöschung bestätigen',
      'hi' => 'सभी हटाने की पुष्टि करें',
      'en' => 'Confirm Delete All',
      _ => '전체 삭제 확인',
    };
    final confirmAllDesc = switch (lang) {
      'ja' => '本当にすべてのキーを削除しますか？\nこの操作は元に戻せません。（図鑑は維持）',
      'zh' => '真的要删除所有组合钥匙吗？\n此操作不可撤销。（图鉴收藏保持不变）',
      'de' => 'Wirklich ALLE Schlüssel löschen?\nDies kann nicht rückgängig gemacht werden. (Codex bleibt sicher)',
      'hi' => 'क्या आप वाकई सभी कुंजियाँ हटाना चाहते हैं?\nयह वापस नहीं लाया जा सकता। (कोडेक्स सुरक्षित)',
      'en' => 'Really delete ALL keys?\nThis cannot be undone. (Codex preserved)',
      _ => '정말 모든 조합 키를 삭제할까요?\n이 작업은 되돌릴 수 없습니다. (도감 수집은 유지)',
    };
    final cancelLabel = switch (lang) {
      'ja' => 'キャンセル',
      'zh' => '取消',
      'de' => 'Abbrechen',
      'hi' => 'रद्द करें',
      'en' => 'Cancel',
      _ => '취소',
    };

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
                    menuTitle,
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
                  cleanExpTitle,
                  style: TextStyle(color: DokkeyTheme.textMain, fontSize: 13.5),
                ),
                subtitle: Text(
                  cleanExpSub,
                  style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                ),
                onTap: expiredCount > 0
                    ? () async {
                        final removed = await provider.clearExpiredCombinedKeys();
                        if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                        if (context.mounted) {
                          final msg = switch (lang) {
                            'ja' => '期限切れキー $removed個を整理しました。🧹',
                            'zh' => '已清理 $removed 个过期钥匙。🧹',
                            'de' => '$removed abgelaufene Schlüssel aufgeräumt. 🧹',
                            'hi' => '$removed समाप्त कुंजियाँ साफ़ की गईं। 🧹',
                            'en' => '$removed expired keys cleaned. 🧹',
                            _ => '만료된 키 $removed개를 정리했습니다. 🧹',
                          };
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(msg),
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
                  delAllTitle,
                  style: TextStyle(color: DokkeyTheme.textMain, fontSize: 13.5),
                ),
                subtitle: Text(
                  delAllSub,
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
                                  confirmAllTitle,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            content: Text(
                              confirmAllDesc,
                              style: TextStyle(color: DokkeyTheme.textMain, fontSize: 13, height: 1.5),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: Text(cancelLabel, style: TextStyle(color: DokkeyTheme.textMuted)),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DokkeyTheme.dokFire,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(delAllTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                        if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                        if (confirmed == true) {
                          final removed = await provider.clearAllCombinedKeys();
                          if (context.mounted) {
                            final msg = switch (lang) {
                              'ja' => '組合せキー $removed個をすべて削除しました。🧹',
                              'zh' => '已全部删除 $removed 个组合钥匙。🧹',
                              'de' => '$removed Schlüssel komplett gelöscht. 🧹',
                              'hi' => '$removed कुंजियाँ पूरी तरह हटा दी गईं। 🧹',
                              'en' => '$removed keys deleted. 🧹',
                              _ => '조합 키 $removed개를 전체 삭제했습니다. 🧹',
                            };
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
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
    final lang = provider.lang;
    final keys = provider.combinedKeys;
    final max = provider.maxCombinedSlots;
    final usageRatio = keys.isEmpty ? 0.0 : (keys.length / max).clamp(0.0, 1.0);
    final isNearLimit = keys.length >= max - 1 && !provider.isProUser;
    final isAtLimit = keys.length >= max;

    final appbarTitle = switch (lang) {
      'ja' => '組合せキー保管箱 (${keys.length}/$max)',
      'zh' => '组合钥匙保管箱 (${keys.length}/$max)',
      'de' => 'Kombinierter Tresor (${keys.length}/$max)',
      'hi' => 'संयोजित वॉल्ट (${keys.length}/$max)',
      'en' => 'Combined Keys (${keys.length}/$max)',
      _ => '조합된 키 보관함 (${keys.length}/$max)',
    };

    final codexTooltip = switch (lang) {
      'ja' => '99 グランド図鑑',
      'zh' => '99 宏伟图鉴',
      'de' => '99 Grand Codex',
      'hi' => '99 ग्रैंड कोडेक्स',
      'en' => '99 Grand Codex',
      _ => '99 그랜드 도감',
    };

    final cleanupTooltip = switch (lang) {
      'ja' => '一括整理',
      'zh' => '一键整理',
      'de' => 'Tresor aufräumen',
      'hi' => 'सफ़ाई मेनू',
      'en' => 'Bulk Cleanup',
      _ => '일괄 정리',
    };

    final backupTooltip = switch (lang) {
      'ja' => '保管箱バックアップ',
      'zh' => '保险库备份',
      'de' => 'Tresor-Backup',
      'hi' => 'वॉल्ट बैकअप',
      'en' => 'Vault Backup',
      _ => '볼트 백업 / 내보내기',
    };

    final emptyTitle = switch (lang) {
      'ja' => 'まだ保存された組合せキーがありません。',
      'zh' => '还没有保存任何组合钥匙。',
      'de' => 'Noch keine kombinierten Schlüssel gespeichert.',
      'hi' => 'अभी तक कोई संयोजित कुंजी सहेजी नहीं गई।',
      'en' => 'No combined keys saved yet.',
      _ => '아직 저장된 조합 키가 없습니다.',
    };

    final emptySubtitle = switch (lang) {
      'ja' => '保管箱下の[錬成する]ボタンで最初の鍵を作りましょう！',
      'zh' => '点击保管箱底部的[炼制]按钮创造第一枚钥匙吧！',
      'de' => 'Tippe im Tresor auf [Kombinieren], um deinen ersten Schlüssel zu schmieden!',
      'hi' => 'कुंजी बॉक्स में [संयोजित करें] पर टैप करके अपनी पहली कुंजी बनाएं!',
      'en' => 'Tap [Combine] in the Key Box to create your first key!',
      _ => '보관함 하단의 [연성하기] 버튼으로 첫 키를 만들어보세요!',
    };

    final guideBtnLabel = switch (lang) {
      'ja' => 'ボルトガイド',
      'zh' => '保险库指南',
      'de' => 'Tresor-Leitfaden',
      'hi' => 'वॉल्ट गाइड',
      'en' => 'Vault Guide',
      _ => '볼트 사용법 안내',
    };

    final totalCountLabel = switch (lang) {
      'ja' => '合計 ${keys.length}/$max個の組合せ',
      'zh' => '共 ${keys.length}/$max 个组合',
      'de' => 'Gesamt ${keys.length}/$max Schlüssel',
      'hi' => 'कुल ${keys.length}/$max संयोजन',
      'en' => '${keys.length}/$max Keys Total',
      _ => '총 ${keys.length}/$max개 조합',
    };

    final tapToCopyLabel = switch (lang) {
      'ja' => 'タップでコピー 📋',
      'zh' => '点击即可复制 📋',
      'de' => 'Tippen zum Kopieren 📋',
      'hi' => 'कॉपी करने के लिए टैप करें 📋',
      'en' => 'Tap to copy 📋',
      _ => '번호 터치 시 복사 📋',
    };

    final slotFullAlertLabel = switch (lang) {
      'ja' => '無料スロット9/9満杯！削除するかPROで99個に拡張 →',
      'zh' => '免费槽位9/9已满！请删除或升级PRO至99个 →',
      'de' => 'Gratis-Plätze voll (9/9)! Löschen oder mit Pro auf 99 erweitern →',
      'hi' => 'मुफ़्त 9/9 स्लॉट भरे हैं! हटाएं या Pro से 99 स्लॉट पाएँ →',
      'en' => 'Free slots full (9/9)! Delete one or expand to 99 with Pro →',
      _ => '무료 슬롯 9/9 꽉참! 지우거나 PRO로 99개로 확장하세요 →',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(appbarTitle),
        actions: [
          // [🎴 99 도감 바로가기]
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CardCodexScreen()),
              );
            },
            icon: Icon(Icons.menu_book_rounded, color: DokkeyTheme.goldLight),
            tooltip: codexTooltip,
          ),
          // [🧹 일괄 정리] 메뉴
          IconButton(
            onPressed: () => _showCleanupMenu(context, provider),
            icon: Icon(Icons.cleaning_services_rounded, color: DokkeyTheme.gold),
            tooltip: cleanupTooltip,
          ),
          // [☁️ 볼트 백업]
          IconButton(
            onPressed: () => _showCloudVaultBackupDialog(context),
            icon: Icon(Icons.cloud_download_outlined, color: DokkeyTheme.gold),
            tooltip: backupTooltip,
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
                      emptyTitle,
                      style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptySubtitle,
                      style: TextStyle(color: DokkeyTheme.gold, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    // 볼트 안내 진입점 (빈 상태에서도 접근 가능)
                    TextButton.icon(
                      onPressed: () => _showVaultHelpDialog(context),
                      icon: Icon(Icons.help_outline_rounded, size: 16, color: DokkeyTheme.gold),
                      label: Text(
                        guideBtnLabel,
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
                                  totalCountLabel,
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
                              tapToCopyLabel,
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
                                      slotFullAlertLabel,
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
                  switch (lang) {
                    'ja' => '保管箱に戻る (閉じる)',
                    'zh' => '返回保管箱 (关闭)',
                    'de' => 'Zurück zur Schlüsselbox (Schließen)',
                    'hi' => 'कुंजी बॉक्स पर वापस (बंद करें)',
                    'en' => 'Back to Key Box (Close)',
                    _ => '보관함으로 돌아가기 (닫기)',
                  },
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
