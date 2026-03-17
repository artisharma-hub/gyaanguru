import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../app/theme.dart';

void showShareSheet(
  BuildContext context, {
  required String link,
  required String challengerName,
  required String category,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ShareSheet(
      link: link,
      challengerName: challengerName,
      category: category,
    ),
  );
}

class _ShareSheet extends StatelessWidget {
  final String link;
  final String challengerName;
  final String category;

  const _ShareSheet({
    required this.link,
    required this.challengerName,
    required this.category,
  });

  String get _shareText =>
      '$challengerName ne tumhe Gyaan Guru $category quiz mein challenge kiya! 🎯\n'
      'Accept karo: $link';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share Challenge',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      link,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Nunito',
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied!')),
                      );
                    },
                    child: const Icon(Icons.copy,
                        color: AppColors.primary, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ShareOption(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => Share.share(_shareText),
                ),
                _ShareOption(
                  icon: Icons.sms,
                  label: 'SMS',
                  color: AppColors.primary,
                  onTap: () => Share.share(_shareText),
                ),
                _ShareOption(
                  icon: Icons.photo_camera,
                  label: 'Instagram',
                  color: const Color(0xFFE1306C),
                  onTap: () => Share.share(_shareText),
                ),
                _ShareOption(
                  icon: Icons.link,
                  label: 'Copy Link',
                  color: AppColors.gold,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: link));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Nunito',
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
