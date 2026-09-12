import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ma_svg_asset.dart';
import '../../data/maker_current_show_repository.dart';
import '../../domain/artwork_detail.dart';
import 'artwork_viewer_dots.dart';

class ArtworkMakerInfoPage extends ConsumerWidget {
  const ArtworkMakerInfoPage({
    super.key,
    required this.artwork,
    required this.currentIndex,
    required this.pageCount,
    required this.isSaved,
    required this.isSaving,
    required this.onSavedTap,
    required this.onShare,
    required this.onClose,
  });

  final ArtworkDetail artwork;
  final int currentIndex;
  final int pageCount;
  final bool isSaved;
  final bool isSaving;
  final VoidCallback onSavedTap;
  final VoidCallback onShare;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maker = artwork.maker;
    final currentShow = maker == null
        ? null
        : ref.watch(makerCurrentShowProvider(maker.id));

    return LayoutBuilder(
      builder: (context, constraints) {
        final widthScale = (constraints.maxWidth / 430).clamp(0.78, 1.08);
        final horizontal = (35 * widthScale).clamp(18.0, 35.0).toDouble();
        final cardTop = (305 * constraints.maxHeight / 932)
            .clamp(140.0, 305.0)
            .toDouble();

        return SingleChildScrollView(
          key: const Key('artwork_maker_info_scroll'),
          padding: EdgeInsets.fromLTRB(horizontal, cardTop, horizontal, 28),
          child: Column(
            children: [
              Material(
                key: const Key('artwork_maker_info_card'),
                color: const Color(0xFF101A18),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 34),
                            child: Text(
                              artwork.title,
                              key: const Key('artwork_maker_info_title'),
                              style: const TextStyle(
                                fontFamily: 'Fraunces',
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFF0F0F0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if ((maker?.name ?? '').isNotEmpty) maker!.name,
                              if (artwork.createdAt != null)
                                '${artwork.createdAt!.year}',
                            ].join(' · '),
                            key: const Key('artwork_maker_info_meta'),
                            style: const TextStyle(
                              fontFamily: 'Instrument Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFF0F0F0),
                            ),
                          ),
                          if ((maker?.bio ?? '').isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Text(
                              maker!.bio!,
                              key: const Key('artwork_maker_info_bio'),
                              style: const TextStyle(
                                fontFamily: 'Instrument Sans',
                                fontSize: 16,
                                height: 1.35,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFF0F0F0),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Divider(
                            height: 1,
                            color: const Color(0xFFF0F0F0)
                                .withValues(alpha: 0.25),
                          ),
                          if ((maker?.websiteUrl ?? '').isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Website',
                              style: TextStyle(
                                fontFamily: 'Instrument Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFBDBDBD),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              maker!.websiteUrl!,
                              key: const Key('artwork_maker_info_website'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Fraunces',
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFF0F0F0),
                              ),
                            ),
                          ],
                          if ((maker?.contactEmail ?? '').isNotEmpty) ...[
                            const SizedBox(height: 14),
                            const Text(
                              'Email',
                              style: TextStyle(
                                fontFamily: 'Instrument Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFBDBDBD),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              maker!.contactEmail!,
                              key: const Key('artwork_maker_info_email'),
                              style: const TextStyle(
                                fontFamily: 'Fraunces',
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFF0F0F0),
                              ),
                            ),
                          ],
                          if (currentShow != null)
                            currentShow.when(
                              data: (show) {
                                if (show == null || show.name.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                final through = show.endDate == null
                                    ? ''
                                    : ' through ${DateFormat.yMMMM().format(show.endDate!)}';

                                return Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Current Show',
                                        style: TextStyle(
                                          fontFamily: 'Instrument Sans',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFFBDBDBD),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Currently exhibiting at ${show.name}$through.',
                                        key: const Key(
                                          'artwork_maker_current_show',
                                        ),
                                        style: const TextStyle(
                                          fontFamily: 'Fraunces',
                                          fontSize: 16,
                                          height: 1.15,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFFF0F0F0),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Semantics(
                                button: true,
                                selected: isSaved,
                                label: isSaved
                                    ? 'Remove saved artwork'
                                    : 'Save artwork',
                                child: InkResponse(
                                  key: const Key(
                                    'artwork_maker_info_save_button',
                                  ),
                                  onTap: isSaving ? null : onSavedTap,
                                  radius: 24,
                                  child: SizedBox.square(
                                    dimension: 44,
                                    child: Center(
                                      child: isSaving
                                          ? const SizedBox.square(
                                              dimension: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primary,
                                              ),
                                            )
                                          : SizedBox.square(
                                              key: const Key(
                                                'artwork_maker_info_heart',
                                              ),
                                              dimension: 24,
                                              child: MaSvgAsset(
                                                assetName: 'assets/heart.svg',
                                                fallbackAssetName:
                                                    'assets/icons/heart.svg',
                                                color: isSaved
                                                    ? AppColors.primary
                                                    : const Color(0xFFF0F0F0),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                key: const Key(
                                  'artwork_maker_info_share_button',
                                ),
                                onPressed: onShare,
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFF0F0F0),
                                  minimumSize: const Size(44, 44),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                child: const Text(
                                  'Share',
                                  style: TextStyle(
                                    fontFamily: 'Instrument Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFF0F0F0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: -10,
                        right: -10,
                        child: SizedBox.square(
                          dimension: 44,
                          child: IconButton(
                            key: const Key('artwork_maker_info_close_button'),
                            onPressed: onClose,
                            padding: EdgeInsets.zero,
                            iconSize: 12,
                            color: const Color(0xFFF0F0F0),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              ArtworkViewerDots(count: pageCount, currentIndex: currentIndex),
            ],
          ),
        );
      },
    );
  }
}
