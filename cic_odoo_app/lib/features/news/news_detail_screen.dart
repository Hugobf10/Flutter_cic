import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/ui/app_components.dart';
import '../../theme/app_theme.dart';

class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.excerpt,
    required this.content,
    required this.link,
    required this.imageUrl,
    required this.dateLabel,
  });

  final String title;
  final String excerpt;
  final String content;
  final Uri? link;
  final Uri? imageUrl;
  final String dateLabel;
}

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key, required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final body = article.content.isEmpty ? article.excerpt : article.content;
    return AppScaffold(
      title: 'Novedad',
      child: ListView(
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: AppTheme.radiusMd,
              child: SizedBox(
                height: 230,
                width: double.infinity,
                child: article.imageUrl == null
                    ? const _NewsDetailFallback()
                    : Image.network(
                        article.imageUrl.toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _NewsDetailFallback(),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const AppStatusChip(label: 'COMUNICADO', color: AppTheme.primary),
              const Spacer(),
              Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: AppTheme.textMutedFor(context),
              ),
              const SizedBox(width: 7),
              Text(
                article.dateLabel,
                style: TextStyle(
                  color: AppTheme.textMutedFor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            article.title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 27, height: 1.18),
          ),
          if (article.excerpt.isNotEmpty && article.excerpt != body) ...[
            const SizedBox(height: 12),
            Text(
              article.excerpt,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondaryFor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 22),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppIconSurface(
                  icon: Icons.article_outlined,
                  color: AppTheme.primary,
                  size: 44,
                  iconSize: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SelectableText(
                    body,
                    style: TextStyle(
                      color: AppTheme.textSecondaryFor(context),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (article.link != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: 'Abrir noticia original',
                icon: Icons.open_in_new_rounded,
                onPressed: () => launchUrl(
                  article.link!,
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _NewsDetailFallback extends StatelessWidget {
  const _NewsDetailFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Center(
        child: NeumorphicSurface(
          color: Colors.white.withValues(alpha: 0.13),
          showBorder: false,
          subtle: true,
          borderRadius: BorderRadius.circular(28),
          padding: const EdgeInsets.all(20),
          child: SvgPicture.asset(
            'assets/branding/cic_mark.svg',
            width: 54,
            height: 54,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
