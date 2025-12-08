import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Task> _allTasks = [];
  List<Task> _selectedDayTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await DatabaseService.instance.getAllTasks();
    setState(() {
      _allTasks = tasks;
      _loadTasksForSelectedDay();
      _isLoading = false;
    });
  }

  void _loadTasksForSelectedDay() {
    if (_selectedDay == null) return;

    setState(() {
      _selectedDayTasks = _allTasks.where((task) {
        return task.dueDate.year == _selectedDay!.year &&
            task.dueDate.month == _selectedDay!.month &&
            task.dueDate.day == _selectedDay!.day;
      }).toList();
    });
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _allTasks.where((task) {
      return task.dueDate.year == day.year &&
          task.dueDate.month == day.month &&
          task.dueDate.day == day.day;
    }).toList();
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    );
    await DatabaseService.instance.updateTask(updatedTask);
    _loadTasks();
  }

  Future<void> _deleteTask(Task task) async {
    await DatabaseService.instance.deleteTask(task.id);
    if (task.reminderDateTime != null) {
      await NotificationService.instance.cancelNotification(task.id.hashCode);
    }
    _loadTasks();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task deleted')));
    }
  }

  void _showTaskDialog({Task? task}) {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descController = TextEditingController(text: task?.description ?? '');
    DateTime selectedDate = task?.dueDate ?? _selectedDay ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(
      task?.dueDate ?? DateTime.now(),
    );
    DateTime? reminderDateTime = task?.reminderDateTime;
    int selectedPriority = task?.priority ?? 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(task == null ? 'New Task' : 'Edit Task'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: task == null,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Priority',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('Low'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Med'),
                      icon: Icon(Icons.remove),
                    ),
                    ButtonSegment(
                      value: 2,
                      label: Text('High'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                  ],
                  selected: {selectedPriority},
                  onSelectionChanged: (Set<int> newSelection) {
                    setDialogState(() {
                      selectedPriority = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat('MMM d, y').format(selectedDate)),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: Text(selectedTime.format(context)),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    reminderDateTime != null
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    color: reminderDateTime != null ? Colors.orange : null,
                  ),
                  title: Text(
                    reminderDateTime != null
                        ? 'Reminder: ${DateFormat('MMM d, HH:mm').format(reminderDateTime!)}'
                        : 'Set reminder',
                  ),
                  trailing: reminderDateTime != null
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setDialogState(() => reminderDateTime = null);
                          },
                        )
                      : const Icon(Icons.add),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: reminderDateTime ?? selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: selectedDate,
                    );
                    if (date == null || !context.mounted) return;

                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        reminderDateTime ?? DateTime.now(),
                      ),
                    );
                    if (time == null) return;

                    setDialogState(() {
                      reminderDateTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }

                final dueDate = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                if (task == null) {
                  // Create new task
                  final newTask = Task(
                    id: const Uuid().v4(),
                    title: title,
                    description: descController.text.trim(),
                    dueDate: dueDate,
                    createdAt: DateTime.now(),
                    reminderDateTime: reminderDateTime,
                    priority: selectedPriority,
                  );
                  await DatabaseService.instance.createTask(newTask);

                  if (reminderDateTime != null &&
                      reminderDateTime!.isAfter(DateTime.now())) {
                    await NotificationService.instance.scheduleNotification(
                      id: newTask.id.hashCode,
                      title: 'Task Reminder: $title',
                      body: descController.text.trim().isEmpty
                          ? 'You have a task due'
                          : descController.text.trim(),
                      scheduledDate: reminderDateTime!,
                    );
                  }
                } else {
                  // Update existing task
                  final updatedTask = task.copyWith(
                    title: title,
                    description: descController.text.trim(),
                    dueDate: dueDate,
                    reminderDateTime: reminderDateTime,
                    priority: selectedPriority,
                  );
                  await DatabaseService.instance.updateTask(updatedTask);

                  await NotificationService.instance.cancelNotification(
                    task.id.hashCode,
                  );
                  if (reminderDateTime != null &&
                      reminderDateTime!.isAfter(DateTime.now())) {
                    await NotificationService.instance.scheduleNotification(
                      id: updatedTask.id.hashCode,
                      title: 'Task Reminder: $title',
                      body: descController.text.trim().isEmpty
                          ? 'You have a task due'
                          : descController.text.trim(),
                      scheduledDate: reminderDateTime!,
                    );
                  }
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  _loadTasks();
                }
              },
              child: Text(task == null ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tasks & Calendar',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(8),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _loadTasksForSelectedDay();
                });
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: _getTasksForDay,
              calendarStyle: CalendarStyle(
                markersMaxCount: 3,
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  _selectedDay != null
                      ? DateFormat('EEEE, MMM d, y').format(_selectedDay!)
                      : 'Select a date',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedDayTasks.length} task${_selectedDayTasks.length != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedDayTasks.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.task_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks for this day',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to create a new task',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _selectedDayTasks.length,
                      itemBuilder: (context, index) {
                        final task = _selectedDayTasks[index];
                        return _buildTaskCard(task);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        tooltip: 'New Task',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color priorityColor;
    String priorityLabel;

    switch (task.priority) {
      case 2:
        priorityColor = Colors.red;
        priorityLabel = 'High';
        break;
      case 1:
        priorityColor = Colors.orange;
        priorityLabel = 'Medium';
        break;
      default:
        priorityColor = Colors.blue;
        priorityLabel = 'Low';
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => _toggleTaskCompletion(task),
          shape: const CircleBorder(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
            color: task.isCompleted
                ? (isDark ? Colors.grey.shade500 : Colors.grey.shade600)
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade300 : Colors.black87,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    priorityLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? priorityColor.withValues(alpha: 1.0) : priorityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(task.dueDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                if (task.reminderDateTime != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.notifications_active,
                    size: 14,
                    color: Colors.orange.shade700,
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showTaskDialog(task: task);
            } else if (value == 'delete') {
              _showDeleteDialog(task);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showTaskDialog(task: task),
      ),
    );
  }

  void _showDeleteDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(task);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
