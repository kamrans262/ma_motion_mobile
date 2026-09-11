import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/artwork_detail.dart';

class ArtworkMakerInfoPage extends StatelessWidget {
  const ArtworkMakerInfoPage({super.key, required this.artwork});

  final ArtworkDetail artwork;

  @override
  Widget build(BuildContext context) {
    final maker = artwork.maker;
    final year = artwork.createdAt?.year;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth < 360 ? 18.0 : 28.0;
        final avatarSize = constraints.maxWidth < 360 ? 68.0 : 82.0;

        return SingleChildScrollView(
          key: const Key('artwork_maker_info_scroll'),
          padding: EdgeInsets.fromLTRB(horizontal, 76, horizontal, 28),
          child: Column(
            children: [
              _Avatar(url: maker?.profileImageUrl, size: avatarSize),
              const SizedBox(height: 46),
              Material(
                key: const Key('artwork_maker_info_card'),
                color: AppColors.inputFill,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artwork.title,
                        key: const Key('artwork_maker_info_title'),
                        style: AppTextStyles.onboardingHelper.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if ((maker?.name ?? '').isNotEmpty) maker!.name,
                          if (year != null) '$year',
                        ].join(' · '),
                        style: AppTextStyles.onboardingHelper.copyWith(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                      if ((maker?.bio ?? '').isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          maker!.bio!,
                          key: const Key('artwork_maker_info_bio'),
                          style: AppTextStyles.onboardingHelper.copyWith(
                            color: AppColors.white,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Divider(
                        height: 1,
                        color: AppColors.mutedText.withValues(alpha: 0.35),
                      ),
                      if ((maker?.websiteUrl ?? '').isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Website',
                          style: AppTextStyles.onboardingHelper.copyWith(
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          maker!.websiteUrl!,
                          key: const Key('artwork_maker_info_website'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.onboardingHelper.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                      if ((maker?.contactEmail ?? '').isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Email',
                          style: AppTextStyles.onboardingHelper.copyWith(
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          maker!.contactEmail!,
                          key: const Key('artwork_maker_info_email'),
                          style: AppTextStyles.onboardingHelper.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                      if ((maker?.location ?? '').isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Location',
                          style: AppTextStyles.onboardingHelper.copyWith(
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          maker!.location!,
                          key: const Key('artwork_maker_info_location'),
                          style: AppTextStyles.onboardingHelper.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite_border_rounded,
                            size: 23,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '${maker?.savedCount ?? 0}',
                            key: const Key('artwork_maker_saved_count'),
                            style: AppTextStyles.onboardingHelper.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.ios_share_outlined,
                            size: 21,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Share',
                            style: AppTextStyles.onboardingHelper.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              if ((maker?.contactEmail ?? '').isEmpty)
                Text(
                  'Contact email is kept private unless the Maker shares it.',
                  key: const Key('artwork_private_email_notice'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.onboardingHelper.copyWith(
                    fontSize: 11,
                    color: AppColors.mutedText.withValues(alpha: 0.78),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = url?.trim() ?? '';

    return Container(
      key: const Key('artwork_maker_avatar'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 5),
      ),
      clipBehavior: Clip.antiAlias,
      child: trimmed.isEmpty
          ? const Icon(
              Icons.person_outline_rounded,
              color: AppColors.white,
              size: 34,
            )
          : Image.network(
              trimmed,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.white,
                  size: 34,
                );
              },
            ),
    );
  }
}
