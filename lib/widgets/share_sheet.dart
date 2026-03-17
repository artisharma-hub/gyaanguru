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
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
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
      '$challengerName ne tumhe Gyaan Guru $category quiz mein challenge kiya!\n'
      'Accept karo: $link';

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Container(
      decoration: BoxDecoration(
        color: ac.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: ac.border, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ac.border2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Share Challenge',
                style: TextStyle(
                  color: ac.textPrimary,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Invite a friend to battle!',
                style: TextStyle(
                  color: ac.textSecondary,
                  fontFamily: 'Nunito',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              // Link display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: ac.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ac.border, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        link,
                        style: TextStyle(
                          color: ac.textSecondary,
                          fontFamily: 'Nunito',
                          fontSize: 12,
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
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Share options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ShareOption(
                    icon: Icons.chat_rounded,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () => Share.share(_shareText),
                  ),
                  _ShareOption(
                    icon: Icons.sms_rounded,
                    label: 'SMS',
                    color: AppColors.primary,
                    onTap: () => Share.share(_shareText),
                  ),
                  _ShareOption(
                    icon: Icons.photo_camera_rounded,
                    label: 'Instagram',
                    color: const Color(0xFFE1306C),
                    onTap: () => Share.share(_shareText),
                  ),
                  _ShareOption(
                    icon: Icons.link_rounded,
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
    final ac = context.ac;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              color: ac.textSecondary,
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
