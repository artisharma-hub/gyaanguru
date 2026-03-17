import 'dart:io';
import 'package:flutter/material.dart';
import '../app/theme.dart';

class VsCard extends StatelessWidget {
  final String myName;
  final String myAvatarColor;
  final int myScore;
  final String opponentName;
  final String opponentAvatarColor;
  final int opponentScore;

  const VsCard({
    super.key,
    required this.myName,
    required this.myAvatarColor,
    required this.myScore,
    required this.opponentName,
    required this.opponentAvatarColor,
    required this.opponentScore,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PlayerInfo(
            name: myName,
            avatarColor: myAvatarColor,
            score: myScore,
            isMe: true,
          ),
        ),
        // VS badge with gradient
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Text(
            'VS',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: _PlayerInfo(
            name: opponentName,
            avatarColor: opponentAvatarColor,
            score: opponentScore,
            isMe: false,
          ),
        ),
      ],
    );
  }
}

class _PlayerInfo extends StatelessWidget {
  final String name;
  final String avatarColor;
  final int score;
  final bool isMe;

  const _PlayerInfo({
    required this.name,
    required this.avatarColor,
    required this.score,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (isMe) AvatarWidget(name: name, avatarColor: avatarColor),
            if (isMe) const SizedBox(width: 8),
            Flexible(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            if (!isMe) const SizedBox(width: 8),
            if (!isMe) AvatarWidget(name: name, avatarColor: avatarColor),
          ],
        ),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AppColors.gold, AppColors.goldLight],
          ).createShader(b),
          child: Text(
            '$score',
            textAlign: isMe ? TextAlign.left : TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 32,
            ),
          ),
        ),
      ],
    );
  }
}

class AvatarWidget extends StatelessWidget {
  final String name;
  final String avatarColor;
  final double radius;
  final String? imagePath;

  const AvatarWidget({
    super.key,
    required this.name,
    required this.avatarColor,
    this.radius = 20,
    this.imagePath,
  });

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = _parseColor(avatarColor);

    if (imagePath != null && imagePath!.isNotEmpty) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: base.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(File(imagePath!)),
          backgroundColor: base,
        ),
      );
    }

    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').take(2).join()
        : '?';

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [base, base.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: base.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: radius * 0.65,
          ),
        ),
      ),
    );
  }
}
