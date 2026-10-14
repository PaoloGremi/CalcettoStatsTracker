import 'package:calcetto_tracker/core/util/player_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty or blank query matches every name', () {
    expect(matchesPlayerQuery('Mario', ''), isTrue);
    expect(matchesPlayerQuery('Mario', '   '), isTrue);
  });

  test('matches substrings ignoring case and surrounding spaces', () {
    expect(matchesPlayerQuery('Mario Rossi', 'ross'), isTrue);
    expect(matchesPlayerQuery('Mario Rossi', ' MAR '), isTrue);
    expect(matchesPlayerQuery('Mario Rossi', 'luigi'), isFalse);
  });

  test('ignores accents on both sides', () {
    expect(matchesPlayerQuery('Nicolò', 'nicolo'), isTrue);
    expect(matchesPlayerQuery('Nicolo', 'nicolò'), isTrue);
  });
}
