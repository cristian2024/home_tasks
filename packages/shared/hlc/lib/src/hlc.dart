import 'package:equatable/equatable.dart';

/// Marca de un reloj lógico híbrido: tiempo de pared en milisegundos UTC,
/// un contador para los eventos del mismo milisegundo y el dispositivo que la
/// generó.
///
/// El orden es total: primero [wallTime], luego [counter] y, como desempate
/// final, [deviceId]. Dos dispositivos nunca generan la misma marca.
class Hlc extends Equatable implements Comparable<Hlc> {
  /// Lanza [ArgumentError] si [wallTime] o [counter] están fuera de rango o
  /// si [deviceId] está vacío.
  Hlc({required this.wallTime, required this.counter, required this.deviceId}) {
    if (wallTime < 0 || wallTime > maxWallTime) {
      throw ArgumentError.value(wallTime, 'wallTime', 'Se esperaba 0..$maxWallTime');
    }
    if (counter < 0 || counter > maxCounter) {
      throw ArgumentError.value(counter, 'counter', 'Se esperaba 0..$maxCounter');
    }
    if (deviceId.isEmpty) {
      throw ArgumentError.value(deviceId, 'deviceId', 'No puede estar vacío');
    }
  }

  /// Marca con el tiempo de pared de [time] (p. ej. el `updatedAt` de un dato
  /// anterior a la sincronización).
  factory Hlc.fromDateTime(DateTime time, {required String deviceId, int counter = 0}) =>
      Hlc(wallTime: time.toUtc().millisecondsSinceEpoch, counter: counter, deviceId: deviceId);

  /// Lee una marca escrita con [encode]. Lanza [FormatException] si no lo es.
  factory Hlc.parse(String value) {
    final RegExpMatch? match = _encoded.firstMatch(value);
    if (match == null) {
      throw FormatException('No es un HLC', value);
    }
    return Hlc(
      wallTime: int.parse(match.group(1)!),
      counter: int.parse(match.group(2)!),
      deviceId: match.group(3)!,
    );
  }

  /// Mayor contador admitido en un mismo milisegundo.
  static const int maxCounter = 0xFFFF;

  /// Mayor tiempo de pared que cabe en [encode] (15 dígitos).
  static const int maxWallTime = 999999999999999;

  static const int _wallDigits = 15;
  static const int _counterDigits = 5;
  static final RegExp _encoded = RegExp(r'^(\d{15})-(\d{5})-(.+)$');

  /// Milisegundos desde la época Unix, en UTC.
  final int wallTime;

  final int counter;

  final String deviceId;

  /// [wallTime] como instante UTC.
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(wallTime, isUtc: true);

  bool isBefore(Hlc other) => compareTo(other) < 0;

  bool isAfter(Hlc other) => compareTo(other) > 0;

  /// Texto de ancho fijo: ordenarlo como texto da el mismo orden que
  /// [compareTo]. Se lee con [Hlc.parse].
  String encode() =>
      '${wallTime.toString().padLeft(_wallDigits, '0')}-'
      '${counter.toString().padLeft(_counterDigits, '0')}-'
      '$deviceId';

  @override
  int compareTo(Hlc other) {
    final int byWall = wallTime.compareTo(other.wallTime);
    if (byWall != 0) {
      return byWall;
    }
    final int byCounter = counter.compareTo(other.counter);
    if (byCounter != 0) {
      return byCounter;
    }
    return deviceId.compareTo(other.deviceId);
  }

  @override
  List<Object?> get props => <Object?>[wallTime, counter, deviceId];

  @override
  String toString() => encode();
}
