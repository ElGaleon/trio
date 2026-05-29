import 'package:flutter/material.dart';

class AppConstants {
  const AppConstants._();

  static const appTitle = 'TRIO';
  static const playersBox = 'players';
  static const matchesBox = 'matches';
  static const settingsBox = 'settings';
  static const settingsKey = 'app';

  static const playerTypeId = 1;
  static const matchTypeId = 2;
  static const settingsTypeId = 3;

  static const initialRating = 1000.0;
  static const eloKFactor = 32.0;
  static const minTeamSize = 3;
  static const maxTeamSize = 7;
  static const defaultTeamSize = 3;
  static const seedColor = Color(0xFF7C3AED);
}
