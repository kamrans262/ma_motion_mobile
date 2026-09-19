import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ma_svg_asset.dart';
import '../../data/maker_current_show_repository.dart';
import '../../domain/artwork_detail.dart';

class ArtworkMakerInfoPage extends ConsumerWidget {
  const ArtworkMakerInfoPage({
    super.key,
    required this.artwork,
    required this.isSaved,
    required this.isSaving,
    required this.onSavedTap,
    required this.onShare,
  });

  final ArtworkDetail artwork;
  final bool isSaved;
  final bool isSaving;
  final VoidCallback onSavedTap;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maker = artwork.maker;
    final currentShow = maker == null || !maker.showShowsOnInfoPage
        ? null
        : ref.watch(makerCurrentShowProvider(maker.id));

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          key: const Key('artwork_maker_info_scroll'),
          physics: const ClampingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxWidth: 396,
              ),
              child: IntrinsicHeight(
                child: Container(
                  key: const Key('artwork_maker_info_card'),
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Color(0xFF121212)),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 42),
                        child: Text(
                          artwork.title,
                          key: const Key('artwork_maker_info_title'),
                          style: const TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 24,
                            height: 1.08,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFF0F0F0),
                          ),
                        ),
                      ),
                      if (_makerMeta(artwork).isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _makerMeta(artwork),
                          key: const Key('artwork_maker_info_meta'),
                          style: const TextStyle(
                            fontFamily: 'Instrument Sans',
                            fontSize: 15,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFF0F0F0),
                          ),
                        ),
                      ],
                      if ((maker?.bio ?? '').isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          maker!.bio!,
                          key: const Key('artwork_maker_info_bio'),
                          style: const TextStyle(
                            fontFamily: 'Instrument Sans',
                            fontSize: 14,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFF0F0F0),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      const Divider(
                        key: Key('artwork_maker_info_divider'),
                        height: 1,
                        thickness: 1,
                        color: Color(0xFF494949),
                      ),
                      if ((maker?.websiteUrl ?? '').isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const _InfoLabel('Website'),
                        const SizedBox(height: 5),
                        Text(
                          maker!.websiteUrl!,
                          key: const Key('artwork_maker_info_website'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const _InfoValueStyle(),
                        ),
                      ],
                      if ((maker?.contactEmail ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const _InfoLabel('Email'),
                        const SizedBox(height: 5),
                        Text(
                          maker!.contactEmail!,
                          key: const Key('artwork_maker_info_email'),
                          style: const _InfoValueStyle(),
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
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _InfoLabel('Current Show'),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Currently exhibiting at ${show.name}$through.',
                                    key: const Key('artwork_maker_current_show'),
                                    style: const _InfoValueStyle(),
                                  ),
                                ],
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (error, stackTrace) => const SizedBox.shrink(),
                        ),
                      const SizedBox(height: 28),
                      const Spacer(),
                      Row(
                        children: [
                          Semantics(
                            button: true,
                            selected: isSaved,
                            label: isSaved
                                ? 'Remove saved artwork'
                                : 'Save artwork',
                            child: InkResponse(
                              key: const Key('artwork_maker_info_save_button'),
                              onTap: isSaving ? null : onSavedTap,
                              radius: 24,
                              child: SizedBox.square(
                                dimension: 44,
                                child: Center(
                                  child: SizedBox.square(
                                    key: const Key('artwork_maker_info_heart'),
                                    dimension: 24,
                                    child: isSaved
                                        ? const Icon(
                                            Icons.favorite_rounded,
                                            key: Key(
                                              'artwork_maker_info_heart_filled',
                                            ),
                                            size: 24,
                                            color: AppColors.primary,
                                          )
                                        : const MaSvgAsset(
                                            assetName: 'assets/icons/heart.svg',
                                            fallbackAssetName: 'assets/heart.svg',
                                            color: Color(0xFFF0F0F0),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            key: const Key('artwork_maker_info_share_button'),
                            onPressed: onShare,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFF0F0F0),
                              minimumSize: const Size(44, 44),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            child: const Text(
                              'Share',
                              style: TextStyle(
                                fontFamily: 'Instrument Sans',
                                fontSize: 18,
                                height: 1,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFF0F0F0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _makerMeta(ArtworkDetail artwork) {
    final makerName = artwork.maker?.name.trim() ?? '';
    final year = artwork.createdAt?.year;

    if (makerName.isEmpty) {
      return year == null ? '' : '$year';
    }

    return year == null ? makerName : '$makerName · $year';
  }
}

class _InfoLabel extends StatelessWidget {
  const _InfoLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Instrument Sans',
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w500,
        color: Color(0xFFBDBDBD),
      ),
    );
  }
}

class _InfoValueStyle extends TextStyle {
  const _InfoValueStyle()
    : super(
        fontFamily: 'Fraunces',
        fontSize: 17,
        height: 1.25,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFF0F0F0),
      );
}
