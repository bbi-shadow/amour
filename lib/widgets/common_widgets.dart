import 'dart:io';
import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

// ══════════════════════════════════════════════════════════════
// GradientButton — Nút gradient chung
// ══════════════════════════════════════════════════════════════
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final List<Color> colors;
  final double? width;
  final double height;
  final bool isLoading;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.colors = AppColors.gradientPink,
    this.width,
    this.height = 54,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: colors.first.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 5)),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// VerifiedBadge — Badge xác minh
// ══════════════════════════════════════════════════════════════
class VerifiedBadge extends StatelessWidget {
  final double size;
  const VerifiedBadge({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
      child: Icon(Icons.check, color: Colors.white, size: size * 0.65),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PremiumBadge — Badge Premium
// ══════════════════════════════════════════════════════════════
class PremiumBadge extends StatelessWidget {
  final String plan;
  const PremiumBadge({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    Color color;
    String emoji;
    switch (plan.toLowerCase()) {
      case 'platinum':
        color = const Color(0xFFB9A0FF); emoji = '💎';
      case 'gold':
        color = const Color(0xFFFFD700); emoji = '⭐';
      default:
        color = const Color(0xFF667EEA); emoji = '✨';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 3),
        Text(plan[0].toUpperCase() + plan.substring(1),
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// OnlineIndicator — Chấm xanh online
// ══════════════════════════════════════════════════════════════
class OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;
  const OnlineIndicator({super.key, required this.isOnline, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: isOnline ? AppColors.online : AppColors.offline,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size * 0.2),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// UserAvatar — Avatar user với online indicator
// ══════════════════════════════════════════════════════════════
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final bool showOnline;
  final bool isOnline;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 28,
    this.showOnline = false,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary.withOpacity(0.15),
          backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
          child: photoUrl?.isNotEmpty != true
              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold,
                      fontSize: radius * 0.7))
              : null,
        ),
        if (showOnline)
          Positioned(
            bottom: radius * 0.05,
            right: radius * 0.05,
            child: OnlineIndicator(isOnline: isOnline, size: radius * 0.55),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// InterestChip — Chip sở thích
// ══════════════════════════════════════════════════════════════
class InterestChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const InterestChip({
    super.key,
    required this.emoji,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(25),
          border: selected ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            color: selected ? Colors.white : AppColors.lightText,
            fontWeight: FontWeight.w600, fontSize: 13,
          )),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// GlassCard — Glassmorphism card
// ══════════════════════════════════════════════════════════════
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double opacity;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.opacity = 0.15,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: AppGradients.glass(opacity: opacity, radius: borderRadius),
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// EmptyState — Trạng thái rỗng tái sử dụng
// ══════════════════════════════════════════════════════════════
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.lightText)),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(
                  color: AppColors.lightSubtext, fontSize: 15, height: 1.5)),
            ],
            if (buttonLabel != null && onButtonTap != null) ...[
              const SizedBox(height: 24),
              GradientButton(label: buttonLabel!, onTap: onButtonTap, width: 160),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// LoadingOverlay — Loading overlay toàn màn hình
// ══════════════════════════════════════════════════════════════
class LoadingOverlay extends StatelessWidget {
  final String? message;
  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message!, style: const TextStyle(
                    fontSize: 14, color: AppColors.lightSubtext)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SwipeIndicator — Hiện nhãn LIKE / NOPE khi kéo card
// ══════════════════════════════════════════════════════════════
class SwipeIndicator extends StatelessWidget {
  final bool isLike;
  final double opacity;

  const SwipeIndicator({super.key, required this.isLike, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: (isLike ? Colors.green : Colors.red).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLike ? Colors.green : Colors.red,
            width: 3,
          ),
        ),
        child: Text(
          isLike ? 'THÍCH 💕' : 'BỎ QUA 👎',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// IceBreakerChip — Gợi ý câu mở đầu
// ══════════════════════════════════════════════════════════════
class IceBreakerChips extends StatelessWidget {
  final ValueChanged<String> onSelected;
  const IceBreakerChips({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const messages = [
      '👋 Chào bạn!',
      '☕ Cà phê không?',
      '🎵 Nhạc gì đang nghe?',
      '😄 Kể chuyện vui đi!',
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: messages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onSelected(messages[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(messages[i], style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
      ),
    );
  }
}
