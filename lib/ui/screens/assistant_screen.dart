import 'package:flutter/material.dart';

import '../../features/assistant/assistant_controller.dart';
import '../widgets/app_scope.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _text = TextEditingController();
  final _turns = <AssistantTurn>[];
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  AssistantController _controller(BuildContext context) {
    final scope = AppScope.of(context);
    return AssistantController(
      db: scope.services.db,
      intentEngine: scope.services.intentEngine,
      responses: scope.services.responses,
      tts: scope.services.tts,
    );
  }

  Future<void> _send(String text) async {
    final scope = AppScope.of(context);
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    setState(() => _busy = true);
    _text.clear();

    final turn = await _controller(context).handleText(
      userId: scope.userId,
      text: trimmed,
    );

    if (!mounted) return;
    setState(() {
      _turns.insert(0, turn);
      _busy = false;
    });
  }

  Future<void> _sync() async {
    final scope = AppScope.of(context);
    setState(() => _busy = true);
    final result =
        await scope.services.sync.syncUnsyncedLogs(userId: scope.userId);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sync: ${result.reason} • pushed ${result.pushed}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          label: const Text('Taken'),
          onPressed: _busy ? null : () => _send('ma ausadi khayo'),
        ),
        ActionChip(
          label: const Text('Missed'),
          onPressed: _busy ? null : () => _send('ausadi chutyo'),
        ),
        ActionChip(
          label: const Text('Schedule'),
          onPressed: _busy ? null : () => _send('schedule'),
        ),
        ActionChip(
          label: const Text('Sync logs'),
          onPressed: _busy ? null : _sync,
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Assistant'),
        actions: [
          IconButton(
            onPressed: _busy
                ? null
                : () async {
                    final scope = AppScope.of(context);
                    await scope.services.tts.stop();
                  },
            icon: const Icon(Icons.volume_off_outlined),
            tooltip: 'Stop voice',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: chips,
          ),
          const Divider(height: 1),
          Expanded(
            child: _turns.isEmpty
                ? const Center(
                    child: Text(
                      'Type or tap a quick action.\n\nThis MVP is offline-first.\nVoice input (Vosk) will be wired next.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    reverse: true,
                    itemCount: _turns.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final t = _turns[i];
                      return ListTile(
                        title: Text(t.userText),
                        subtitle: Text(t.assistantText),
                        trailing: IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Intent JSON'),
                              content: SingleChildScrollView(
                                child: Text(t.intentJson.toString()),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      decoration: const InputDecoration(
                        hintText: 'Say: "ma ausadhi khaye" / "schedule"...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: _busy ? null : _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _busy ? null : () => _send(_text.text),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

