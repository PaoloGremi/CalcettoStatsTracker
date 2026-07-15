import 'package:calcetto_tracker/core/error/failure.dart';
import 'package:calcetto_tracker/core/error/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('success carries the value and reports isSuccess', () {
      final result = Result<int>.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.fold((v) => v, (f) => -1), 42);
    });

    test('failure carries the Failure and reports isFailure', () {
      const failure = CacheFailure('box not found');
      final result = Result<int>.failure(failure);

      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.fold((v) => 'value', (f) => f.message), 'box not found');
    });

    test('fold dispatches to the matching branch only', () {
      final success = Result<String>.success('ok');
      final failure =
          Result<String>.failure(const ValidationFailure('bad input'));

      expect(success.fold((v) => v, (f) => throw StateError('should not run')),
          'ok');
      expect(
        failure.fold(
            (v) => throw StateError('should not run'), (f) => f.message),
        'bad input',
      );
    });
  });

  group('Failure subtypes', () {
    test('expose the message they were constructed with', () {
      expect(const CacheFailure('a').message, 'a');
      expect(const NetworkFailure('b').message, 'b');
      expect(const ValidationFailure('c').message, 'c');
    });
  });
}
