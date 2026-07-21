import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;

typedef StateValueProvider<T> = NotifierProvider<ValueStateNotifier<T>, T>;

StateValueProvider<T> mutableProvider<T>(T Function() initial) {
  return NotifierProvider<ValueStateNotifier<T>, T>(
    () => ValueStateNotifier<T>(initial),
  );
}

NotifierProviderFamily<ValueStateNotifier<T>, T, Arg>
mutableProviderFamily<T, Arg>(T Function(Arg arg) initial) {
  return NotifierProvider.family<ValueStateNotifier<T>, T, Arg>(
    (arg) => ValueStateNotifier<T>(() => initial(arg)),
  );
}

class ValueStateNotifier<T> extends Notifier<T> {
  ValueStateNotifier(this._initial);

  final T Function() _initial;

  @override
  T build() => _initial();

  void set(T value) {
    state = value;
  }
}
