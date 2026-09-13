import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../models/motorcycle.dart';
import '../state/catalog_provider.dart';
import '../theme/app_theme.dart';

/// Shows a bike photo: the curated catalog URL, or one looked up on demand
/// from the Wikimedia Commons API, with a styled placeholder fallback.
class BikeImage extends StatelessWidget {
  const BikeImage({super.key, required this.bike, this.fit = BoxFit.cover, this.iconSize = 56});

  final Motorcycle bike;
  final BoxFit fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final url = bike.imageUrl;
    if (url != null) return NetworkBikeImage(url: url, fit: fit, iconSize: iconSize);
    return FutureBuilder<String?>(
      future: context.read<CatalogProvider>().imageFor(bike),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return BikeImagePlaceholder(iconSize: iconSize, loading: true);
        }
        final resolved = snapshot.data;
        if (resolved == null) return BikeImagePlaceholder(iconSize: iconSize);
        return NetworkBikeImage(url: resolved, fit: fit, iconSize: iconSize);
      },
    );
  }
}

class NetworkBikeImage extends StatelessWidget {
  const NetworkBikeImage({super.key, required this.url, this.fit = BoxFit.cover, this.iconSize = 56});

  final String url;
  final BoxFit fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: AppConfig.identityHeaders,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: (context, url) => BikeImagePlaceholder(iconSize: iconSize, loading: true),
      errorWidget: (context, url, error) => BikeImagePlaceholder(iconSize: iconSize),
    );
  }
}

class BikeImagePlaceholder extends StatelessWidget {
  const BikeImagePlaceholder({super.key, this.iconSize = 56, this.loading = false});

  final double iconSize;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F2433), Color(0xFF12141B)],
        ),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBright),
              )
            : Icon(Icons.two_wheeler_rounded, size: iconSize, color: AppColors.textMuted.withValues(alpha: 0.5)),
      ),
    );
  }
}
