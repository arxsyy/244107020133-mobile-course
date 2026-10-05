import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Saklar offline yang bisa diaktifkan dari SettingsPage untuk
/// mensimulasikan kondisi offline secara deterministik (untuk demo & testing).
final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false; // bawaan: online

  void toggle() => state = !state;
}
