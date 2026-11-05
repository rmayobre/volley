import 'package:test/test.dart';
import 'package:volley_api/volley_api.dart';

final class _Msg with DistinctMessage {}

final class _Wrapper implements MapEncodableMessage {
  final RegExp re;
  final BigInt big;
  _Wrapper(this.re, this.big);

  @override
  Map<String, Object?> toMap() => {
    're': regExpToMap(re),
    'big': bigIntToMap(big),
  };
}

void main() {
  group('DistinctMessage', () {
    test('each instance has a unique, stable id', () {
      final a = _Msg(), b = _Msg();
      expect(a.id, isNot(b.id));
      expect(a.id, a.id);
      expect(a.id, hasLength(36));
    });
  });

  group('map codecs', () {
    test('RegExp round-trips all flags', () {
      final original = RegExp(
        r'a.b\d+',
        multiLine: true,
        caseSensitive: false,
        unicode: true,
        dotAll: true,
      );
      final copy = regExpFromMap(regExpToMap(original));
      expect(copy.pattern, original.pattern);
      expect(copy.isMultiLine, isTrue);
      expect(copy.isCaseSensitive, isFalse);
      expect(copy.isUnicode, isTrue);
      expect(copy.isDotAll, isTrue);
    });

    test('RegExp defaults flags when absent from the map', () {
      final re = regExpFromMap({'pattern': 'x'});
      expect(re.isMultiLine, isFalse);
      expect(re.isCaseSensitive, isTrue);
      expect(re.isUnicode, isFalse);
      expect(re.isDotAll, isFalse);
    });

    test('regExpToMap only contains primitive values', () {
      final map = regExpToMap(RegExp('x'));
      expect(map.values, everyElement(anyOf(isA<String>(), isA<bool>())));
    });

    test('BigInt round-trips, including values beyond 64 bits', () {
      for (final v in [
        BigInt.zero,
        BigInt.from(-42),
        BigInt.parse('123456789012345678901234567890'),
        -BigInt.two.pow(100),
      ]) {
        expect(bigIntFromMap(bigIntToMap(v)), v);
      }
    });

    test('MapEncodableMessage output is composed of encodable types', () {
      final map = _Wrapper(RegExp('q'), BigInt.from(5)).toMap();
      expect(map['big'], '5');
      expect(map['re'], isA<Map<String, Object?>>());
    });
  });

  group('UnsendableMessageException', () {
    test('toString mentions the message type and the cause', () {
      const e = UnsendableMessageException(_Msg, 'bad port');
      expect(e.messageType, _Msg);
      expect(e.cause, 'bad port');
      expect(e.toString(), allOf(contains('_Msg'), contains('bad port')));
    });
  });

  group('CoroutineDisposedException', () {
    test('toString describes the failure', () {
      expect(
        const CoroutineDisposedException().toString(),
        contains('disposed before completion'),
      );
    });
  });
}
