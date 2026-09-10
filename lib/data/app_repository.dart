import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/progress.dart';

abstract interface class AppRepository {
  Future<PersistentState> load();
  Future<void> save(PersistentState state);
  Future<void> clear();
}

class PreferencesAppRepository implements AppRepository {
  PreferencesAppRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'museum_heist_state_v2';
  final SharedPreferencesAsync _preferences;

  @override
  Future<PersistentState> load() async {
    try {
      final raw = await _preferences.getString(_key);
      if (raw == null || raw.isEmpty) return PersistentState();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return PersistentState();
      return PersistentState.fromJson(Map<String, Object?>.from(decoded));
    } catch (_) {
      return PersistentState();
    }
  }

  @override
  Future<void> save(PersistentState state) =>
      _preferences.setString(_key, jsonEncode(state.toJson()));

  @override
  Future<void> clear() => _preferences.remove(_key);
}

class MemoryAppRepository implements AppRepository {
  MemoryAppRepository([PersistentState? initial]) : _state = initial ?? PersistentState();

  PersistentState _state;

  @override
  Future<void> clear() async => _state = PersistentState();

  @override
  Future<PersistentState> load() async => PersistentState.fromJson(_state.toJson());

  @override
  Future<void> save(PersistentState state) async {
    _state = PersistentState.fromJson(state.toJson());
  }
}
