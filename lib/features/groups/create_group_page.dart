import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';

class CreateGroupPage extends ConsumerStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<CreateGroupPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  String? _competition;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final group = await ref
          .read(apiProvider)
          .createGroup(_name.text.trim(), _competition!);
      ref.invalidate(groupsProvider);
      if (mounted) context.pushReplacement('/groups/${group.id}');
    } catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo grupo')),
      body: Centered(
        maxWidth: 480,
        child: AsyncBody(
          value: competitions,
          onRetry: () => ref.invalidate(competitionsProvider),
          data: (list) => Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _name,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del grupo',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Ponle un nombre al grupo'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _competition,
                        decoration: const InputDecoration(
                          labelText: 'Competición',
                        ),
                        items: [
                          for (final c in list)
                            DropdownMenuItem(
                              value: c.code,
                              child: Text(c.name),
                            ),
                        ],
                        onChanged: (v) => setState(() => _competition = v),
                        validator: (v) =>
                            v == null ? 'Elige una competición' : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Crear grupo'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
