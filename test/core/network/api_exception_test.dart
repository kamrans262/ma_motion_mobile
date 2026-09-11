import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_exception.dart';

void main() {
  test('parses Laravel validation field errors', () {
    final error = ApiException.fromResponse(
      statusCode: 422,
      body: <String, dynamic>{
        'success': false,
        'message': 'The given data was invalid.',
        'errors': <String, dynamic>{
          'email': <String>['The email has already been taken.'],
          'password': <String>['The password is invalid.'],
        },
      },
    );

    expect(error.isValidation, isTrue);
    expect(error.message, 'The given data was invalid.');
    expect(error.fieldErrors['email'], <String>[
      'The email has already been taken.',
    ]);
  });

  test('recognizes unauthenticated API errors', () {
    final error = ApiException.fromResponse(
      statusCode: 401,
      body: <String, dynamic>{'message': 'Unauthenticated.'},
    );

    expect(error.isUnauthenticated, isTrue);
  });
}
