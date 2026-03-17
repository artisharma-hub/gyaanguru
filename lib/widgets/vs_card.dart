import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final myWinning  = myScore > opponentScore;
    final oppWinning = opponentScore > myScore;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _PlayerInfo(
            name: myName,
            avatarColor: myAvatarColor,
            score: myScore,
            isMe: true,
            isWinning: myWinning,
          ),
        ),
        // VS badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: 14,
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
                    letterSpacing: 1.5,
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.95, end: 1.05, duration: 900.ms, curve: Curves.easeInOut),
              if (myWinning || oppWinning) ...[
                const SizedBox(height: 6),
                Text(
                  myWinning ? '←' : '→',
                  style: TextStyle(
                    color: AppColors.correctGreen.withValues(alpha: 0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 400.ms)
                    .then(delay: 200.ms)
                    .fadeOut(duration: 400.ms),
              ],
            ],
          ),
        ),
        Expanded(
          child: _PlayerInfo(
            name: opponentName,
            avatarColor: opponentAvatarColor,
            score: opponentScore,
            isMe: false,
            isWinning: oppWinning,
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
  final bool isWinning;

  const _PlayerInfo({
    required this.name,
    required this.avatarColor,
    required this.score,
    required this.isMe,
    required this.isWinning,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (isMe) AvatarWidget(name: name, avatarColor: avatarColor),
            if (isMe) const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isWinning ? AppColors.primaryLight : ac.textSecondary,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (isMe)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Text(
                        'YOU',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!isMe) const SizedBox(width: 8),
            if (!isMe) AvatarWidget(name: name, avatarColor: avatarColor),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: isWinning ? 36 : 32,
          ),
          child: ShaderMask(
            shaderCallback: (b) => LinearGradient(
              colors: isWinning
                  ? [AppColors.gold, AppColors.goldLight]
                  : [AppColors.gold.withValues(alpha: 0.7), AppColors.gold.withValues(alpha: 0.5)],
            ).createShader(b),
            child: Text(
              '$score',
              textAlign: isMe ? TextAlign.left : TextAlign.right,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        if (isWinning)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Leading',
              textAlign: isMe ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                color: AppColors.correctGreen.withValues(alpha: 0.9),
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
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
          border: Border.all(color: base.withValues(alpha: 0.6), width: 2),
          boxShadow: [
            BoxShadow(color: base.withValues(alpha: 0.3), blurRadius: 8),
          ],
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
          colors: [base, base.withValues(alpha: 0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: base.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(color: base.withValues(alpha: 0.35), blurRadius: 10, spreadRadius: 1),
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
            shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
          ),
        ),
      ),
    );
  }
}
