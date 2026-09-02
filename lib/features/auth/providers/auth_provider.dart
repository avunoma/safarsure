import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safarsure/data/models/user.dart';
import 'package:safarsure/data/repositories/app_repository.dart';

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  AuthNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    try {
      final repo = await _ref.read(appRepositoryProvider.future);
      state = AsyncValue.data(repo.getCurrentUser());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String phone, String name) async {
    final repo = await _ref.read(appRepositoryProvider.future);
    final user = AppUser(
      id: repo.generateId(),
      name: name.trim().isEmpty ? 'Traveller' : name.trim(),
      phone: phone,
    );
    await repo.saveUser(user);
    state = AsyncValue.data(user);
  }

  Future<void> logout() async {
    final repo = await _ref.read(appRepositoryProvider.future);
    await repo.clearUser();
    state = const AsyncValue.data(null);
  }

  Future<void> updateRole(UserRole role) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(role: role);
    final repo = await _ref.read(appRepositoryProvider.future);
    await repo.saveUser(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> updateName(String name) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(name: name);
    final repo = await _ref.read(appRepositoryProvider.future);
    await repo.saveUser(updated);
    state = AsyncValue.data(updated);
  }
}
