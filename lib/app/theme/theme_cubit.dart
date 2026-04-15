import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeState extends Equatable {
  const ThemeState({required this.themeMode});

  final ThemeMode themeMode;

  ThemeState copyWith({ThemeMode? themeMode}) {
    return ThemeState(themeMode: themeMode ?? this.themeMode);
  }

  @override
  List<Object?> get props => [themeMode];
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState(themeMode: ThemeMode.system));

  void setThemeMode(ThemeMode mode) => emit(state.copyWith(themeMode: mode));

  void toggleLightDark() {
    final next = switch (state.themeMode) {
      ThemeMode.dark => ThemeMode.light,
      _ => ThemeMode.dark,
    };
    emit(state.copyWith(themeMode: next));
  }
}

