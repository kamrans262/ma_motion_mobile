import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/features/artwork_viewer/domain/artwork_detail.dart';

void main() {
  test('public Maker contact email remains opt-in', () {
    final hidden = ArtworkDetailMaker.fromMap(<String, dynamic>{
      'id': 1,
      'name': 'Maker',
      'website_url': 'https://artist.example',
      'contact_email': null,
      'show_shows_on_info_page': true,
    });

    final shared = ArtworkDetailMaker.fromMap(<String, dynamic>{
      'id': 1,
      'name': 'Maker',
      'contact_email': 'public@artist.example',
      'show_shows_on_info_page': false,
    });

    expect(hidden.contactEmail, isNull);
    expect(hidden.showShowsOnInfoPage, isTrue);
    expect(shared.contactEmail, 'public@artist.example');
    expect(shared.showShowsOnInfoPage, isFalse);
  });
}
