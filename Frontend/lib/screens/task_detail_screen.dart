import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../services/task_provider.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TextEditingController _subtaskController = TextEditingController();

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Используем watch для автоматического ребилда при изменениях в провайдере
    final provider = context.watch<TaskProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.task.title),
        actions: [
          IconButton(
            icon: Icon(widget.task.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: () => provider.togglePin(widget.task),
            tooltip: widget.task.isPinned ? 'Открепить' : 'Закрепить',
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: provider.getSubtasks(widget.task.id),
        builder: (context, snapshot) {
          final subtasks = snapshot.data ?? [];
          final progress = provider.calculateProgress(subtasks);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Карточка прогресса
                _buildProgressCard(context, progress),
                const SizedBox(height: 32),

                // 2. Секция подзадач
                _buildSectionHeader(context, "ПОДЗАДАЧИ", Icons.checklist_rounded),
                const SizedBox(height: 16),
                _buildSubtaskList(context, subtasks, provider),
                const SizedBox(height: 8),
                _buildAddSubtaskInput(context, provider),

                const SizedBox(height: 40),

                // 3. Секция файлов
                _buildSectionHeader(context, "ФАЙЛЫ И АРТЕФАКТЫ", Icons.attach_file_rounded),
                const SizedBox(height: 16),
                _buildFileSection(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.secondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(BuildContext context, double progress) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Прогресс выполнения",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtaskList(BuildContext context, List<Task> subtasks, TaskProvider provider) {
    if (subtasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          "Нет подзадач",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return Column(
      children: subtasks.map((st) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: CheckboxListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              title: Text(
                st.title,
                style: TextStyle(
                  decoration: st.isCompleted ? TextDecoration.lineThrough : null,
                  color: st.isCompleted ? Colors.grey : null,
                ),
              ),
              value: st.isCompleted,
              onChanged: (_) async {
                await provider.toggleTaskCompletion(st);
                // FutureBuilder обновится, так как провайдер вызовет notifyListeners, 
                // и экран перестроится благодаря context.watch
                setState(() {}); 
              },
              controlAffinity: ListTileControlAffinity.leading,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          )).toList(),
    );
  }

  Widget _buildAddSubtaskInput(BuildContext context, TaskProvider provider) {
    return TextField(
      controller: _subtaskController,
      decoration: InputDecoration(
        hintText: "Добавить подзадачу...",
        prefixIcon: const Icon(Icons.add_circle_outline_rounded),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      onSubmitted: (val) async {
        if (val.trim().isNotEmpty) {
          await provider.addSubtask(widget.task.id, val);
          _subtaskController.clear();
          setState(() {}); // Обновляем FutureBuilder
        }
      },
    );
  }

  Widget _buildFileSection(BuildContext context, TaskProvider provider) {
    return Column(
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file_rounded, color: Colors.orange),
            title: const Text("specification.pdf"),
            subtitle: const Text("1.2 MB • Готов к открытию"),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: () {},
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => provider.attachFile(widget.task.id),
          icon: const Icon(Icons.attach_file_rounded),
          label: const Text("Прикрепить файл"),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}
