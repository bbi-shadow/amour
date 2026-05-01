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
    this.colors = AppColors.gradientPrimary,
    this.width,
    this.height = 56,
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
            BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
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
      decoration: const BoxDecoration(color: AppColors.info, shape: BoxShape.circle),
      child: Icon(Icons.check, color: Colors.white, size: size * 0.7),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PremiumBadge — Badge Premium (Đã loại bỏ emoji)
// ══════════════════════════════════════════════════════════════
class PremiumBadge extends StatelessWidget {
  final String plan;
  const PremiumBadge({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (plan.toLowerCase()) {
      case 'platinum':
        color = const Color(0xFFB9A0FF); icon = Icons.diamond_outlined;
        break;
      case 'gold':
        color = AppColors.gold; icon = Icons.star_rounded;
        break;
      default:
        color = AppColors.secondary; icon = Icons.auto_awesome_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(plan.toUpperCase(),
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
  const OnlineIndicator({super.key, required this.isOnline, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: isOnline ? AppColors.success : Colors.grey.shade400,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
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
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: AppColors.gradientPrimary),
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.lightCard,
            backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
            child: photoUrl?.isNotEmpty != true
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold,
                        fontSize: radius * 0.8))
                : null,
          ),
        ),
        if (showOnline)
          Positioned(
            bottom: 2,
            right: 2,
            child: OnlineIndicator(isOnline: isOnline),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// InterestChip — Chip sở thích
// ══════════════════════════════════════════════════════════════
class InterestChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const InterestChip({
    super.key,
    this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(colors: AppColors.gradientPrimary) : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: selected ? [
            BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
          ] : [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ],
          border: selected ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: selected ? Colors.white : AppColors.primary),
            const SizedBox(width: 8),
          ],
          Text(label, style: TextStyle(
            color: selected ? Colors.white : AppColors.lightText,
            fontWeight: FontWeight.w700, fontSize: 14,
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
    this.opacity = 0.1,
    this.borderRadius = 24,
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
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 72, color: AppColors.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.lightText)),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(
                  color: AppColors.lightSubtext, fontSize: 16, height: 1.5)),
            ],
            if (buttonLabel != null && onButtonTap != null) ...[
              const SizedBox(height: 32),
              GradientButton(label: buttonLabel!, onTap: onButtonTap, width: 200),
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
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 5),
              if (message != null) ...[
                const SizedBox(height: 20),
                Text(message!, style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.lightText)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
