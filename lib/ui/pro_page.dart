import 'package:flutter/material.dart';

import '../app_controller.dart';
import 'game_style.dart';

class ProPage extends StatelessWidget {
  const ProPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = _lifetimeProduct();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('THE PRIVATE VAULT')),
      body: HeistBackdrop(
        safeArea: false,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 28),
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.10),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.68),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.16),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.diamond_rounded,
                      size: 52,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'MUSEUM HEIST PRO',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'One key. Every vault.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A permanent lifetime upgrade for players who want uninterrupted cases and unlimited intel.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  const HeistPanel(
                    emphasis: true,
                    child: Column(
                      children: [
                        _Benefit(
                          icon: Icons.visibility_off_rounded,
                          title: 'No surveillance interruptions',
                          detail: 'Remove banners, interstitials, and rewarded-ad gates.',
                        ),
                        SizedBox(height: 18),
                        _Benefit(
                          icon: Icons.lightbulb_rounded,
                          title: 'Unlimited intelligence',
                          detail: 'Use logical hints and contradiction explanations whenever needed.',
                        ),
                        SizedBox(height: 18),
                        _Benefit(
                          icon: Icons.location_city_rounded,
                          title: 'Fund new museums',
                          detail: 'Support more locations, mechanics, visual polish, and accessibility.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: HeistButton(
                      label: controller.isPro
                          ? 'VAULT ACCESS GRANTED'
                          : product == null
                              ? 'UNLOCK LIFETIME'
                              : 'UNLOCK · ${product.price}',
                      icon: controller.isPro
                          ? Icons.verified_rounded
                          : Icons.key_rounded,
                      onPressed: controller.isPro ||
                              !controller.purchases.storeAvailable
                          ? null
                          : () async {
                              await controller.buyLifetime();
                              if (context.mounted && controller.isPro) {
                                Navigator.pop(context);
                              }
                            },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: controller.purchases.storeAvailable
                          ? controller.restorePurchases
                          : null,
                      child: const Text('RESTORE PURCHASE'),
                    ),
                  ),
                  if (!controller.purchases.storeAvailable) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Store access appears on Android, iOS, and macOS after the lifetime product is configured.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                  ValueListenableBuilder<String?>(
                    valueListenable: controller.purchases.error,
                    builder: (context, error, _) => error == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: HeistPanel(
                              accent: theme.colorScheme.error,
                              child: Text(
                                error,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  dynamic _lifetimeProduct() {
    for (final product in controller.purchases.products) {
      if (product.id == 'museum_heist_pro_lifetime') return product;
    }
    return null;
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withValues(alpha: 0.11),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(
                detail,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
