import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/run_guarded.dart';
import '../providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  (int hour, int minute)? _reminderTime;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final time = await ref.read(settingsRepositoryProvider).getReminderTime();
    if (!mounted) return;
    setState(() {
      _reminderTime = time;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Tägliche Erinnerung'),
                  subtitle: Text(
                    _reminderTime == null
                        ? 'Nicht gesetzt'
                        : 'Um ${_reminderTime!.$1.toString().padLeft(2, '0')}:'
                            '${_reminderTime!.$2.toString().padLeft(2, '0')} Uhr',
                  ),
                  trailing: _reminderTime == null
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Erinnerung ausschalten',
                          onPressed: _clearReminder,
                        ),
                  onTap: _pickReminderTime,
                ),
              ],
            ),
    );
  }

  Future<void> _pickReminderTime() async {
    final initial = _reminderTime == null
        ? TimeOfDay.now()
        : TimeOfDay(hour: _reminderTime!.$1, minute: _reminderTime!.$2);

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;

    await runGuarded(context, () async {
      await ref.read(settingsRepositoryProvider).setReminderTime(picked.hour, picked.minute);
      await ref
          .read(notificationServiceProvider)
          .scheduleDailyReminder(hour: picked.hour, minute: picked.minute);
      if (!mounted) return;
      setState(() => _reminderTime = (picked.hour, picked.minute));
    });
  }

  Future<void> _clearReminder() async {
    await runGuarded(context, () async {
      await ref.read(settingsRepositoryProvider).clearReminderTime();
      await ref.read(notificationServiceProvider).cancelReminder();
      if (!mounted) return;
      setState(() => _reminderTime = null);
    });
  }
}
