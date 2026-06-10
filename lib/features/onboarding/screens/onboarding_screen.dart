import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ScaleEffect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/onboarding_page.dart';
import '../../auth/providers/auth_provider.dart';

const Color _brandRed = AppColors.primary;
const Color _buttonText = Color(0xFF1F2937);

/// Pantalla de onboarding/bienvenida - 5 páginas.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _didPrecacheImages = false;

  static const _pages = [
    OnboardingPageData(
      imagePath: AppImages.onboarding1,
      title: AppStrings.onboardingTitle1,
      description: AppStrings.onboardingDesc1,
    ),
    OnboardingPageData(
      imagePath: AppImages.onboarding2,
      title: AppStrings.onboardingTitle2,
      description: AppStrings.onboardingDesc2,
    ),
    OnboardingPageData(
      imagePath: AppImages.onboarding3,
      title: AppStrings.onboardingTitle3,
      description: AppStrings.onboardingDesc3,
    ),
    OnboardingPageData(
      imagePath: AppImages.onboarding4,
      title: AppStrings.onboardingTitle4,
      description: AppStrings.onboardingDesc4,
    ),
    OnboardingPageData(
      imagePath: AppImages.onboarding5,
      title: AppStrings.onboardingTitle5,
      description: AppStrings.onboardingDesc5,
      isLastPage: true,
      imageScale: 1.16,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didPrecacheImages) return;
    _didPrecacheImages = true;

    for (final page in _pages) {
      precacheImage(AssetImage(page.imagePath), context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _onFinish();
    }
  }

  Future<void> _onFinish() async {
    await ref.read(authProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }
  
  void _onSkip() => _onFinish();

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _brandRed,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (_, index) => OnboardingPage(
                data: _pages[index],
                isActive: index == _currentPage,
              ),
            ),
            if (!_isLastPage)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 22,
                right: 34,
                child: _SkipButton(onPressed: _onSkip),
              ),
            Positioned(
              left: 28,
              right: 28,
              bottom: bottomPadding + 34,
              child: _isLastPage ? _buildCtaButton() : _buildNormalControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SmoothPageIndicator(
          controller: _pageController,
          count: _pages.length,
          effect: ScaleEffect(
            activeDotColor: Colors.white,
            dotColor: Colors.white.withValues(alpha: 0.36),
            dotHeight: 12,
            dotWidth: 12,
            scale: 1.75,
            spacing: 10,
          ),
        ),
        _ContinueButton(onPressed: _onNext),
      ],
    );
  }

  Widget _buildCtaButton() {
    return GestureDetector(
          onTap: _onFinish,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.onboardingCta,
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _buttonText,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: _buttonText,
                  size: 22,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 280.ms, delay: 80.ms)
        .slideY(begin: 0.1, end: 0, duration: 280.ms);
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          AppStrings.onboardingSkip,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _buttonText,
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.onboardingContinue,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _buttonText,
              ),
            ),
            const SizedBox(width: 13),
            const Icon(
              Icons.arrow_forward_rounded,
              color: _buttonText,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
