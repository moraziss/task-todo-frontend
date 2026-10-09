import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/category_model.dart';
import '../services/task_provider.dart';
import 'task_detail_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            tooltip: 'Clear completed',
            icon: const Icon(Icons.cleaning_services_rounded),
            onPressed: () => taskProvider.bulkClearCompleted(),
          ),
          IconButton(
            tooltip: 'Sync',
            icon: const Icon(Icons.sync),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing...')));
              await taskProvider.syncWithServer();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const _CategoryFilterBar(),
          const Divider(height: 1),
          if (tasks.isNotEmpty) _FocusTaskOfDay(tasks: tasks),
          Expanded(
            child: tasks.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) => _TaskItem(task: tasks[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('New Task'),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _AddTaskSheet(),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final categories = provider.categories;

    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final Category? category = isAll ? null : categories[index - 1];
          final String id = isAll ? 'all' : category!.id;
          final String label = isAll ? 'All' : category!.name;
          final bool isSelected = provider.selectedCategoryId == id;
          final Color color = isAll ? Colors.grey : Color(int.parse(category!.color.replaceFirst('#', '0xFF')));

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: !isAll ? CircleAvatar(backgroundColor: color, radius: 6) : null,
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => provider.setCategory(id),
            ),
          );
        },
      ),
    );
  }
}

class _FocusTaskOfDay extends StatelessWidget {
  final List<Task> tasks;
  const _FocusTaskOfDay({required this.tasks});

  @override
  Widget build(BuildContext context) {
    // Задача дня - первая невыполненная из отсортированного списка
    Task? focus;
    try {
      focus = tasks.firstWhere((t) => !t.isCompleted);
    } catch (_) {
      return const SizedBox.shrink();
    }

    final provider = context.read<TaskProvider>();
    final color = provider.getCategoryColor(focus.categoryId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6)),
          ],
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: color, child: const Icon(Icons.star, color: Colors.white, size: 20)),
          title: Text('Task of the Day', style: Theme.of(context).textTheme.labelMedium),
          subtitle: Text(focus.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
          trailing: IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () => provider.toggleTaskCompletion(focus!),
          ),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: focus!))),
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final Task task;
  const _TaskItem({required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TaskProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final catColor = provider.getCategoryColor(task.categoryId);
    final overdue = !task.isCompleted && task.deadline != null && task.deadline!.isBefore(DateTime.now());

    return Dismissible(
      key: ValueKey(task.id),
      background: _SwipeBg(color: Colors.amber.shade200, icon: Icons.push_pin, alignment: Alignment.centerLeft),
      secondaryBackground: _SwipeBg(color: Colors.red.shade200, icon: Icons.delete_outline, alignment: Alignment.centerRight),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await provider.togglePin(task);
          return false;
        } else {
          await provider.softDelete(task);
          return true;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: overdue ? Colors.red : colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          color: task.isCompleted ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : colorScheme.surface,
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task))),
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(width: 5, decoration: BoxDecoration(color: catColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)))),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 24, height: 24,
                                child: Checkbox(
                                  value: task.isCompleted,
                                  onChanged: (_) => provider.toggleTaskCompletion(task),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (task.isPinned) const Icon(Icons.push_pin, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: TextStyle(
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    color: task.isCompleted ? colorScheme.onSurfaceVariant : (overdue ? Colors.red : colorScheme.onSurface),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 32),
                            child: _TaskMeta(task: task),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Alignment alignment;
  const _SwipeBg({required this.color, required this.icon, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _TaskMeta extends StatelessWidget {
  final Task task;
  const _TaskMeta({required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TaskProvider>();
    final cat = provider.getCategoryById(task.categoryId);
    
    return FutureBuilder<List<Task>>(
      future: provider.getSubtasks(task.id),
      builder: (context, snapshot) {
        final subs = snapshot.data ?? [];
        return Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (cat != null) Text(cat.name, style: TextStyle(fontSize: 12, color: provider.getCategoryColor(task.categoryId), fontWeight: FontWeight.bold)),
            Text(task.priority.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            if (task.deadline != null) Text(DateFormat('MMM d').format(task.deadline!), style: const TextStyle(fontSize: 10, color: Colors.blue)),
            if (subs.isNotEmpty) Text('${subs.where((s) => s.isCompleted).length}/${subs.length}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(child: Text('No tasks found'));
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();
  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  String _priority = 'medium';
  String? _selectedCatId;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TaskProvider>();
    _selectedCatId = provider.selectedCategoryId == 'all' ? provider.categories.firstOrNull?.id : provider.selectedCategoryId;
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _titleController, autofocus: true, decoration: const InputDecoration(hintText: 'Task title', border: InputBorder.none)),
          const SizedBox(height: 16),
          const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          SegmentedButton<String>(
            segments: const [ButtonSegment(value: 'low', label: Text('Low')), ButtonSegment(value: 'medium', label: Text('Med')), ButtonSegment(value: 'high', label: Text('High'))],
            selected: {_priority},
            onSelectionChanged: (val) => setState(() => _priority = val.first),
          ),
          const SizedBox(height: 16),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Wrap(
            spacing: 8,
            children: provider.categories.map((c) => ChoiceChip(
              label: Text(c.name),
              selected: _selectedCatId == c.id,
              onSelected: (s) => setState(() => _selectedCatId = s ? c.id : null),
            )).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Deadline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.event, size: 18),
                label: Text(_deadline == null ? 'No deadline' : DateFormat('MMM d, y').format(_deadline!)),
                onPressed: _pickDeadline,
              ),
              if (_deadline != null)
                IconButton(
                  tooltip: 'Clear deadline',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _deadline = null),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              provider.addTaskDirect(title: _titleController.text, priority: _priority, categoryId: _selectedCatId, deadline: _deadline);
              Navigator.pop(context);
            },
            child: const Text('Create Task'),
          ),
        ],
      ),
    );
  }
}
