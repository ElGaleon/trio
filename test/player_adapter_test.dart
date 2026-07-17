// ignore_for_file: experimental_member_use

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trio/src/features/players/data/player_adapter.dart';
import 'package:trio/src/features/players/domain/player_line_preference.dart';
import 'package:trio/src/features/players/domain/player_role.dart';

void main() {
  test('reads legacy string values for line and role', () {
    final reader = _FakeBinaryReader([
      8,
      0,
      'player-1',
      1,
      'Legacy Player',
      2,
      1000.0,
      3,
      0,
      4,
      0,
      5,
      0,
      6,
      'offence',
      7,
      'handler',
    ]);

    final player = PlayerAdapter().read(reader);

    expect(player.linePreference, PlayerLinePreference.offense);
    expect(player.role, PlayerRole.handler);
  });

  test('reads optional jersey number', () {
    final reader = _FakeBinaryReader([
      11,
      0,
      'player-2',
      1,
      'Numbered Player',
      2,
      1000.0,
      3,
      0,
      4,
      0,
      5,
      0,
      6,
      PlayerLinePreference.defense.index,
      7,
      PlayerRole.cutter.index,
      8,
      null,
      9,
      false,
      10,
      23,
    ]);

    final player = PlayerAdapter().read(reader);

    expect(player.jerseyNumber, 23);
  });

  test('reads null line preference', () {
    final reader = _FakeBinaryReader([
      11,
      0,
      'player-3',
      1,
      'Null Line Player',
      2,
      1000.0,
      3,
      0,
      4,
      0,
      5,
      0,
      6,
      null,
      7,
      PlayerRole.cutter.index,
      8,
      null,
      9,
      false,
      10,
      null,
    ]);

    final player = PlayerAdapter().read(reader);

    expect(player.linePreference, isNull);
  });
}

class _FakeBinaryReader extends BinaryReader {
  _FakeBinaryReader(this._values);

  final List<Object?> _values;
  int _index = 0;

  @override
  int get availableBytes => _values.length - _index;

  @override
  int get usedBytes => _index;

  @override
  dynamic read([int? typeId]) => _values[_index++];

  @override
  int readByte() => _values[_index++]! as int;

  @override
  bool readBool() => read() as bool;

  @override
  Uint8List readByteList([int? length]) =>
      Uint8List.fromList(read() as List<int>);

  @override
  double readDouble() => read() as double;

  @override
  List<double> readDoubleList([int? length]) => read() as List<double>;

  @override
  HiveList readHiveList([int? length]) => throw UnimplementedError();

  @override
  int readInt() => read() as int;

  @override
  int readInt32() => read() as int;

  @override
  List<int> readIntList([int? length]) => read() as List<int>;

  @override
  List readList([int? length]) => read() as List;

  @override
  Map readMap([int? length]) => read() as Map;

  @override
  String readString([
    int? byteCount,
    Converter<List<int>, String> decoder = BinaryReader.utf8Decoder,
  ]) => read() as String;

  @override
  List<String> readStringList([
    int? length,
    Converter<List<int>, String> decoder = BinaryReader.utf8Decoder,
  ]) => read() as List<String>;

  @override
  int readUint32() => read() as int;

  @override
  int readWord() => read() as int;

  @override
  Uint8List viewBytes(int bytes) => Uint8List(0);

  @override
  Uint8List peekBytes(int bytes) => Uint8List(0);

  @override
  void skip(int bytes) {
    _index += bytes;
  }

  @override
  List<bool> readBoolList([int? length]) => read() as List<bool>;
}
