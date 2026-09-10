import 'package:flutter/material.dart';

import '../app_controller.dart';

class ProPage extends StatelessWidget {
  const ProPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = _lifetimeProduct();
    return Scaffold(
      appBar: AppBar(title: const Text('Museum Heist Pro')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 82,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                'One unlock. Cleaner heists.',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 24),
              const _Benefit(
                icon: Icons.block_rounded,
                title: 'No advertising',
                detail: 'Remove banners, paced interstitials, and rewarded-ad hint gates.',
              ),
              const _Benefit(
                icon: Icons.lightbulb_rounded,
                title: 'Unlimited logical hints',
                detail: 'Use forced-move and contradiction explanations whenever you need them.',
              ),
              const _Benefit(
                icon: Icons.favorite_rounded,
                title: 'Support development',
                detail: 'Fund more locations, mechanics, polish, and accessibility features.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: controller.isPro || !controller.purchases.storeAvailable
                    ? null
                    : () async {
                        await controller.buyLifetime();
                        if (context.mounted && controller.isPro) {
                          Navigator.pop(context);
                        }
                      },
                icon: const Icon(Icons.lock_open_rounded),
                label: Text(
                  controller.isPro
                      ? 'Pro unlocked'
                      : product == null
                          ? 'Lifetime unlock'
                          : 'Lifetime unlock · ${product.price}',
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: controller.purchases.storeAvailable
                    ? controller.restorePurchases
                    : null,
                child: const Text('Restore purchase'),
              ),
              const SizedBox(height: 8),
              if (!controller.purchases.storeAvailable)
                Text(
                  'Purchases appear on Android, iOS, and macOS after the lifetime product is configured in the store console.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ValueListenableBuilder<String?>(
                valueListenable: controller.purchases.error,
                builder: (context, error, _) => error == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          error,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
              ),
            ],
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
  const _Benefit({required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(detail),
      );
}
