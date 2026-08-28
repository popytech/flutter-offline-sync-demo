import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'models/sync_models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _title = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Offline Sync Demo'),
            actions: [
              IconButton(
                tooltip: 'Sync now',
                onPressed: widget.controller.syncing ? null : widget.controller.syncNow,
                icon: widget.controller.syncing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
              ),
            ],
          ),
          body: SafeArea(
            child: widget.controller.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _StatusBanner(message: widget.controller.statusMessage),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Create offline', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              const Text('This form saves locally first. Network access is optional.'),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _title,
                                decoration: const InputDecoration(labelText: 'Title'),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _notes,
                                minLines: 3,
                                maxLines: 5,
                                decoration: const InputDecoration(labelText: 'Notes'),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () async {
                                  await widget.controller.createRecord(_title.text, _notes.text);
                                  _title.clear();
                                  _notes.clear();
                                },
                                icon: const Icon(Icons.save_outlined),
                                label: const Text('Save locally'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Local records', style: Theme.of(context).textTheme.titleLarge),
                          Text('${widget.controller.records.length}'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (widget.controller.records.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(child: Text('No local records yet.')),
                        )
                      else
                        ...widget.controller.records.map(
                          (record) => Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              title: Text(record.title),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(record.notes.isEmpty ? 'No notes' : record.notes),
                                    const SizedBox(height: 10),
                                    _SyncChip(state: record.syncState),
                                  ],
                                ),
                              ),
                              trailing: IconButton(
                                tooltip: 'Queue attachment',
                                onPressed: () => widget.controller.attachFile(record),
                                icon: const Icon(Icons.attach_file),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_sync_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _SyncChip extends StatelessWidget {
  const _SyncChip({required this.state});
  final SyncState state;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (state) {
      SyncState.local => ('Local', Icons.offline_pin_outlined),
      SyncState.pending => ('Pending', Icons.schedule),
      SyncState.syncing => ('Syncing', Icons.sync),
      SyncState.synced => ('Synced', Icons.cloud_done_outlined),
      SyncState.failed => ('Failed', Icons.error_outline),
    };

    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
