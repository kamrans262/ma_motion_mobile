import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/public_maker_detail_repository.dart';

class PublicMakerDetailScreen extends ConsumerWidget {
  const PublicMakerDetailScreen({
    super.key,
    required this.makerId,
    this.onClose,
  });

  final int makerId;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMaker = ref.watch(publicMakerDetailProvider(makerId));

    return Scaffold(
      key: const Key('public_maker_detail_screen'),
      backgroundColor: AppColors.black,
      body: asyncMaker.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => Center(
          child: IconButton(
            key: const Key('public_maker_detail_close'),
            onPressed: onClose,
            color: const Color(0xFFF0F0F0),
            iconSize: 18,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        data: (maker) => LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = (35 * constraints.maxWidth / 430)
                .clamp(18.0, 35.0)
                .toDouble();

            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                child: Material(
                  color: const Color(0xFF101A18),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 34),
                              child: Text(
                                maker.name,
                                key: const Key('public_maker_detail_name'),
                                style: const TextStyle(
                                  fontFamily: 'Fraunces',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFF0F0F0),
                                ),
                              ),
                            ),
                            if (maker.createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${maker.createdAt!.year}',
                                style: const TextStyle(
                                  fontFamily: 'Instrument Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFF0F0F0),
                                ),
                              ),
                            ],
                            if ((maker.bio ?? '').isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Text(
                                maker.bio!,
                                key: const Key('public_maker_detail_bio'),
                                style: const TextStyle(
                                  fontFamily: 'Instrument Sans',
                                  fontSize: 16,
                                  height: 1.35,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFF0F0F0),
                                ),
                              ),
                            ],
                            if ((maker.location ?? '').isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Divider(
                                height: 1,
                                color: const Color(0xFFF0F0F0)
                                    .withValues(alpha: 0.25),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Location',
                                style: TextStyle(
                                  fontFamily: 'Instrument Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFBDBDBD),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                maker.location!,
                                style: const TextStyle(
                                  fontFamily: 'Instrument Sans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFF0F0F0),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Positioned(
                          top: -10,
                          right: -10,
                          child: SizedBox.square(
                            dimension: 44,
                            child: IconButton(
                              key: const Key('public_maker_detail_close'),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
