import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aiassistant1/models/subtask.dart';

class SubtaskScreen extends StatefulWidget {
  final List<Subtask> existingSubtasks;
  final bool isEditMode;

  const SubtaskScreen({
    super.key,
    required this.existingSubtasks,
    this.isEditMode = false,
  });

  @override
  State<SubtaskScreen> createState() => _SubtaskScreenState();
}

class _SubtaskScreenState extends State<SubtaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _deadline = DateTime.now();

  late List<Subtask> _subtasks;

  @override
  void initState() {
    super.initState();
    _subtasks = List.from(widget.existingSubtasks); // copy existing
  }

  void _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_deadline),
      );
      if (time != null) {
        setState(() {
          _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void _addSubtask() {
    if (_formKey.currentState!.validate()) {
      final newSubtask = Subtask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        deadline: _deadline,
      );
      setState(() {
        _subtasks.add(newSubtask);
        _titleController.clear();
        _descriptionController.clear();
        _deadline = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subtasks'),
        actions: [
          if (!widget.isEditMode)
            IconButton(
              icon: const Icon(Icons.done),
              onPressed: () {
                Navigator.pop(context, _subtasks);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (!widget.isEditMode)
                Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Subtask Title'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter a title' : null,
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Subtask Description'),
                    ),
                    ListTile(
                      title: Text(
                          'Deadline: ${DateFormat('MMM dd, yyyy HH:mm').format(_deadline)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickDeadline,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Subtask'),
                      onPressed: _addSubtask,
                    ),
                    const Divider(height: 32),
                  ],
                ),
              const Text('Subtasks:'),
              const SizedBox(height: 8),
              ..._subtasks.map(
                (sub) => ListTile(
                  title: Text(sub.title),
                  subtitle: Text(
                    '${sub.description}\nDue: ${DateFormat('MMM dd, yyyy HH:mm').format(sub.deadline)}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
