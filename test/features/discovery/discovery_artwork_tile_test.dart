import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_artwork.dart';
import 'package:ma_motion_mobile/features/discovery/presentation/widgets/discovery_artwork_tile.dart';

void main() {
  testWidgets('orange show indicator appears only when the Maker has a show',
      (tester) async {
    Widget buildTile(bool hasShow) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 180,
              child: DiscoveryArtworkTile(
                artwork: DiscoveryArtwork(
                  id: 42,
                  title: 'Example artwork',
                  maker: DiscoveryMakerPreview(
                    id: 3,
                    name: 'Exhibiting artist',
                    hasCurrentOrUpcomingShow: hasShow,
                  ),
                ),
                onTap: () {},
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildTile(true));
    final indicatorFinder = find.byKey(
      const Key('artwork_show_indicator_42'),
    );
    expect(indicatorFinder, findsOneWidget);

    expect(
      find.descendant(of: indicatorFinder, matching: find.byType(SvgPicture)),
      findsOneWidget,
    );
    expect(tester.getSize(indicatorFinder), const Size.square(16));
    final tileRect = tester.getRect(find.byKey(const Key('artwork_tile_42')));
    final indicatorRect = tester.getRect(indicatorFinder);
    expect(tileRect.right - indicatorRect.right, 10);
    expect(tileRect.bottom - indicatorRect.bottom, 10);

    await tester.pumpWidget(buildTile(false));
    expect(indicatorFinder, findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('no show indicator when backend omits the show status', () {
    final maker = DiscoveryMakerPreview.fromMap(<String, dynamic>{
      'id': 3,
      'name': 'Exhibiting artist',
    });
    expect(maker.hasCurrentOrUpcomingShow, isFalse);
  });
}
