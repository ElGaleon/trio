
extension DoubleExtension on double {
  String get percent => '${(this * 100).round()}%';
}