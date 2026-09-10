import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../game/progress.dart';
import 'home.dart';

class MuseumHeistApp extends StatelessWidget {
  const MuseumHeistApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final settings = controller.settings;
        final themeMode = switch (settings.theme) {
          AppThemeSetting.system => ThemeMode.system,
          AppThemeSetting.light => ThemeMode.light,
          AppThemeSetting.dark => ThemeMode.dark,
        };
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Museum Heist',
          themeMode: themeMode,
          theme: _theme(Brightness.light, settings.skin),
          darkTheme: _theme(Brightness.dark, settings.skin),
          home: controller.state.onboardingDone
              ? MuseumHome(controller: controller)
              : OnboardingScreen(controller: controller),
        );
      },
    );
  }

  ThemeData _theme(Brightness brightness, MuseumSkin skin) {
    final seed = switch (skin) {
      MuseumSkin.classic => const Color(0xFF5546C8),
      MuseumSkin.noir => const Color(0xFF4D5668),
      MuseumSkin.emerald => const Color(0xFF087F5B),
      MuseumSkin.neon => const Color(0xFF8A2BE2),
    };
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Color.alphaBlend(
        scheme.primary.withValues(alpha: brightness == Brightness.dark ? 0.035 : 0.02),
        scheme.surface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pages = PageController();
  int _page = 0;

  static const _content = [
    (
      icon: Icons.museum_rounded,
      title: 'Plan the perfect heist',
      text: 'Put exactly one thief in every row, every column, and every colored security zone.',
    ),
    (
      icon: Icons.security_rounded,
      title: 'Never get spotted',
      text: 'Thieves cannot touch, even diagonally. Laser rooms are permanently off limits.',
    ),
    (
      icon: Icons.local_fire_department_rounded,
      title: 'Build your reputation',
      text: 'Crack the daily gallery, grow a streak, earn XP, unlock museum skins, and chase perfect clears.',
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduced = widget.controller.settings.reducedMotion;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.controller.completeOnboarding,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _content.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  final item = _content[index];
                  return Semantics(
                    header: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 116,
                            height: 116,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(36),
                            ),
                            child: Icon(item.icon, size: 58, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            item.text,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _content.length; i++)
                  AnimatedContainer(
                    duration: reduced ? Duration.zero : const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    if (_page < _content.length - 1) {
                      await _pages.nextPage(
                        duration: reduced ? Duration.zero : const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                      );
                    } else {
                      await widget.controller.completeOnboarding();
                    }
                  },
                  icon: Icon(_page == _content.length - 1
                      ? Icons.lock_open_rounded
                      : Icons.arrow_forward_rounded),
                  label: Text(_page == _content.length - 1 ? 'Start infiltrating' : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
