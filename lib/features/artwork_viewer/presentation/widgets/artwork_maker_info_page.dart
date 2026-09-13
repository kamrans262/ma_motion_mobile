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
        final horizontal = (constraints.maxWidth * 0.104)
            .clamp(24.0, 40.0)
            .toDouble();
        final top = (constraints.maxHeight * 0.22)
            .clamp(128.0, 180.0)
            .toDouble();

        return Padding(
          key: const Key('artwork_maker_info_scroll'),
          padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, 92),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              key: const Key('artwork_maker_info_card'),
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 340),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3D413E),
                    Color(0xFF332F28),
                    Color(0xFF2A2118),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    maker?.name.isNotEmpty == true
                        ? maker!.name
                        : artwork.title,
                    key: const Key('artwork_maker_info_title'),
                    style: const TextStyle(
                      fontFamily: 'Instrument Sans',
                      fontSize: 24,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF0F0F0),
                    ),
                  ),
                  if ((maker?.location ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      maker!.location!,
                      key: const Key('artwork_maker_info_meta'),
                      style: const TextStyle(
                        fontFamily: 'Instrument Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFBDBDBD),
                      ),
                    ),
                  ],
                  if ((maker?.bio ?? '').isNotEmpty) ...[
                    const SizedBox(height: 26),
                    Text(
                      maker!.bio!,
                      key: const Key('artwork_maker_info_bio'),
                      style: const TextStyle(
                        fontFamily: 'Instrument Sans',
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFF0F0F0),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Divider(height: 1, color: Color(0x45F0F0F0)),
                  if ((maker?.websiteUrl ?? '').isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const _InfoLabel('WEBSITE'),
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
                    const SizedBox(height: 14),
                    const _InfoLabel('EMAIL'),
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
                          padding: const EdgeInsets.only(top: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _InfoLabel('CURRENT SHOW'),
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
                          key: const Key('artwork_maker_info_save_button'),
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
                        key: const Key('artwork_maker_info_share_button'),
                        onPressed: onShare,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFF0F0F0),
                          minimumSize: const Size(44, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: const Text(
                          'SHARE',
                          style: TextStyle(
                            fontFamily: 'Instrument Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFBDBDBD),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: Color(0xFFBDBDBD),
      ),
    );
  }
}

class _InfoValueStyle extends TextStyle {
  const _InfoValueStyle()
    : super(
        fontFamily: 'Instrument Sans',
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFF0F0F0),
      );
}
