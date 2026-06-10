import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_images.dart';
import '../../../core/theme/app_colors.dart';

/// Datos de una página del onboarding.
class OnboardingPageData {
  const OnboardingPageData({
    required this.imagePath,
    required this.title,
    required this.description,
    this.isLastPage = false,
    this.imageScale = 1,
  });

  final String imagePath;
  final String title;
  final String description;
  final bool isLastPage;
  final double imageScale;
}

/// Página individual del onboarding estilo bienvenida.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.data, required this.isActive});

  final OnboardingPageData data;
  final bool isActive;

  static const _panelStart = Color(0xFFF58A8A);
  static const _panelEnd = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final panelHeight = (size.height * 0.34).clamp(270.0, 330.0);
    final topHeight = size.height - panelHeight;
    final imageWidth = ((size.width * 0.68) * data.imageScale).clamp(
      220.0,
      360.0,
    );
    final watermarkSize = (size.width * 1.18).clamp(420.0, 600.0);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Colors.white),
            child: Stack(
              children: [
                Positioned(
                  top: topHeight * 0.05,
                  right: -watermarkSize * 0.38,
                    child: Opacity(
                      opacity: 0.055,
                      child: Image.asset(
                        AppImages.logo,
                        width: watermarkSize,
                        height: watermarkSize,
                        fit: BoxFit.contain,
                        cacheWidth: watermarkSize.toInt(),
                        cacheHeight: watermarkSize.toInt(),
                      ),
                    ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topHeight + 24,
          child: Align(
            alignment: const Alignment(0, 0.34),
            child: _BouncyOnboardingImage(
              imagePath: data.imagePath,
              width: imageWidth,
              isActive: isActive,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: panelHeight + bottomInset,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_panelStart, _panelEnd],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(42),
                topRight: Radius.circular(42),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(28, 42, 28, bottomInset + 88),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                        data.title,
                        style: GoogleFonts.nunito(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.15,
                        ),
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(duration: 300.ms, delay: 80.ms)
                      .slideY(begin: 0.06, end: 0, duration: 300.ms),
                  const SizedBox(height: 16),
                  Text(
                        data.description,
                        style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(duration: 300.ms, delay: 140.ms)
                      .slideY(begin: 0.06, end: 0, duration: 300.ms),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BouncyOnboardingImage extends StatefulWidget {
  const _BouncyOnboardingImage({
    required this.imagePath,
    required this.width,
    required this.isActive,
  });

  final String imagePath;
  final double width;
  final bool isActive;

  @override
  State<_BouncyOnboardingImage> createState() => _BouncyOnboardingImageState();
}

class _BouncyOnboardingImageState extends State<_BouncyOnboardingImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _verticalOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.04,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 58,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.04,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 42,
      ),
    ]).animate(_controller);
    _verticalOffset = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 14.0,
          end: -10.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 58,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -10.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 42,
      ),
    ]).animate(_controller);

    if (widget.isActive) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _BouncyOnboardingImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final becameActive = widget.isActive && !oldWidget.isActive;
    final changedImage = widget.imagePath != oldWidget.imagePath;
    if (becameActive || (widget.isActive && changedImage)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: Image.asset(
          widget.imagePath,
          width: widget.width,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        ),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _verticalOffset.value),
            child: Transform.scale(scale: _scale.value, child: child),
          );
        },
      ),
    );
  }
}
