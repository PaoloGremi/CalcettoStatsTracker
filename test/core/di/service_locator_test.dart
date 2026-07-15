import 'package:calcetto_tracker/core/di/service_locator.dart';
import 'package:calcetto_tracker/services/data_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  test('registers DataService as a lazy singleton', () {
    setupServiceLocator();

    expect(getIt.isRegistered<DataService>(), isTrue);
    expect(getIt<DataService>(), same(getIt<DataService>()));
  });

  test('calling setupServiceLocator twice does not re-register or throw', () {
    setupServiceLocator();
    final first = getIt<DataService>();

    expect(() => setupServiceLocator(), returnsNormally);
    expect(getIt<DataService>(), same(first));
  });
}
