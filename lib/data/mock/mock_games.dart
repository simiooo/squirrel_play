import 'package:flutter/material.dart';

/// Mock game data for demo cards.
///
/// Used in Sprint 2 for testing the UI before real data persistence
/// is implemented in Sprint 3.
class MockGames {
  MockGames._();

  /// List of mock games for demo purposes.
  static const List<MockGame> games = [
    MockGame(
      title: 'The Witcher 3',
      placeholderColor: Color(0xFF4A6741),
      description: 'Open world RPG',
    ),
    MockGame(
      title: 'Hades',
      placeholderColor: Color(0xFF8B2635),
      description: 'Roguelike dungeon crawler',
    ),
    MockGame(
      title: 'Celeste',
      placeholderColor: Color(0xFF6B4C9A),
      description: 'Platformer',
    ),
    MockGame(
      title: 'Hollow Knight',
      placeholderColor: Color(0xFF2C3E50),
      description: 'Metroidvania',
    ),
    MockGame(
      title: 'Ori and the Blind Forest',
      placeholderColor: Color(0xFF1E8449),
      description: 'Adventure platformer',
    ),
    MockGame(
      title: 'Stardew Valley',
      placeholderColor: Color(0xFFF39C12),
      description: 'Farming simulation',
    ),
  ];
}

/// Represents a mock game for demo purposes.
class MockGame {
  /// The game title.
  final String title;

  /// Color for the placeholder gradient.
  final Color placeholderColor;

  /// Optional description.
  final String? description;

  /// Optional cover image URL (null for placeholder).
  final String? coverImageUrl;

  /// Creates a mock game.
  const MockGame({
    required this.title,
    required this.placeholderColor,
    this.description,
    this.coverImageUrl,
  });
}
