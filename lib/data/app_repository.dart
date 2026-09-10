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
  static const _corruptBackupKey = 'museum_heist_state_v2_corrupt';
  final SharedPreferencesAsync _preferences;
  Future<void> _writeTail = Future<void>.value();

  @override
  Future<PersistentState> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null || raw.isEmpty) return PersistentState();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException('State is not a JSON object.');
      return PersistentState.fromJson(Map<String, Object?>.from(decoded));
    } catch (_) {
      // Preserve malformed state for diagnosis instead of repeatedly failing on
      // every launch. A later successful save replaces the clean primary key.
      try {
        await _preferences.setString(_corruptBackupKey, raw);
        await _preferences.remove(_key);
      } catch (_) {
        // Storage failures must not prevent the app from starting.
      }
      return PersistentState();
    }
  }

  @override
  Future<void> save(PersistentState state) {
    // Snapshot before queueing so later in-memory mutations cannot make an
    // older queued write overwrite a newer state.
    final payload = jsonEncode(state.toJson());
    return _enqueue(() => _preferences.setString(_key, payload));
  }

  @override
  Future<void> clear() => _enqueue(() => _preferences.remove(_key));

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return next;
  }
}

class MemoryAppRepository implements AppRepository {
  MemoryAppRepository([PersistentState? initial])
      : _state = initial ?? PersistentState();

  PersistentState _state;

  @override
  Future<void> clear() async => _state = PersistentState();

  @override
  Future<PersistentState> load() async =>
      PersistentState.fromJson(_state.toJson());

  @override
  Future<void> save(PersistentState state) async {
    _state = PersistentState.fromJson(state.toJson());
  }
}
