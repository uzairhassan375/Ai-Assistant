import 'package:aiassistant1/screens/subtask_screen.dart';
import 'package:flutter/material.dart';
import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/task_services.dart';
import 'package:aiassistant1/services/simple_notification_service.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:aiassistant1/models/subtask.dart';

class CreateTaskScreen extends StatefulWidget {
  final Task? task;
  final DateTime? initialDate;
  final Map<String, dynamic>? aiGeneratedData;
  
  const CreateTaskScreen({
    super.key, 
    this.task, 
    this.initialDate,
    this.aiGeneratedData,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<Subtask> _subtasks = [];
  late DateTime _dueDate;
  bool _isLoading = false;
  String _selectedCategory = 'other';
  TaskPriority _selectedPriority = TaskPriority.medium;
  bool _isReminder = false;
  Color _appBarColor = Colors.blue;

  final List<String> _categories = [
    'academics',
    'social',
    'personal',
    'health',
    'work',
    'finance',
    'other',
  ];

  // Voice recognition variables - removed as functionality moved to Speed Dial

  @override
  void initState() {
    super.initState();
    print('DEBUG: CreateTaskScreen initState called');
    print('DEBUG: widget.task: ${widget.task}');
    print('DEBUG: widget.aiGeneratedData: ${widget.aiGeneratedData}');
    
    if (widget.task != null) {
      // Editing existing task
      print('DEBUG: Editing existing task');
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _dueDate = widget.task!.dueDate;
      _selectedCategory = widget.task!.category;
      _selectedPriority = widget.task!.priority;
      _isReminder = widget.task!.isReminder;
      _subtasks = List.from(widget.task!.subtasks); // Initialize with existing subtasks
      _updateAppBarColor();
    } else if (widget.aiGeneratedData != null) {
      // Creating new task with AI-generated data
      print('DEBUG: Creating new task with AI-generated data');
      final aiData = widget.aiGeneratedData!;
      print('DEBUG: aiData: $aiData');
      _titleController.text = aiData['title'] ?? '';
      _descriptionController.text = aiData['description'] ?? '';
      _dueDate = aiData['due_date'] ?? DateTime.now().add(const Duration(days: 1));
      _selectedCategory = aiData['category'] ?? 'other';
      _selectedPriority = _stringToPriority(aiData['priority']) ?? TaskPriority.medium;
      _isReminder = aiData['is_reminder'] ?? false;
      print('DEBUG: Populated fields - title: ${_titleController.text}, category: $_selectedCategory, dueDate: $_dueDate');
      _updateAppBarColor();
    } else {
      // Creating new task without AI data
      print('DEBUG: Creating new task without AI data');
      _dueDate = widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
      // Initialize time to midnight for new tasks if no initialDate is provided with time
      _dueDate = DateTime(_dueDate.year, _dueDate.month, _dueDate.day, 0, 0);
      _updateAppBarColor();
    }
    // Speech functionality removed - now available through Speed Dial on home screen
  }

  void _updateAppBarColor() {
    Color color;
    switch (_selectedCategory.toLowerCase()) {
      case 'academics':
        color = Colors.blue;
        break;
      case 'social':
        color = Colors.purple;
        break;
      case 'personal':
        color = Colors.green;
        break;
      case 'health':
        color = Colors.red;
        break;
      case 'work':
        color = Colors.orange;
        break;
      case 'finance':
        color = Colors.teal;
        break;
      default:
        // Use priority color if category is 'other'
        switch (_selectedPriority) {
          case TaskPriority.low:
            color = Colors.green;
            break;
          case TaskPriority.medium:
            color = Colors.orange;
            break;
          case TaskPriority.high:
            color = Colors.red;
            break;
          case TaskPriority.urgent:
            color = Colors.purple;
            break;
        }
        break;
    }
    setState(() {
      _appBarColor = color;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      // If a date is picked, show the time picker
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate),
      );

      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        // If only date is picked, keep the existing time or set to midnight
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _dueDate.hour,
            _dueDate.minute,
          );
        });
      }
    } else {
      // If no date is picked, do nothing
    }
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      const String demoUserId = 'demo_user';

      final taskService = TaskService();
      final task = Task(
        id: widget.task?.id,
        title: _titleController.text,
        description:
            _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
        dueDate: _dueDate,
        isCompleted: widget.task?.isCompleted ?? false,
        userId: demoUserId,
        category: _selectedCategory,
        subtasks: _subtasks,
        priority: _selectedPriority,
        isArchived: widget.task?.isArchived ?? false,
        isReminder: _isReminder,
      );

      try {
        if (_isReminder) {
          // Check if the due date is in the past (current time, not just date)
          if (_dueDate.isBefore(DateTime.now())) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cannot set reminder for past date/time. Please select a future time.'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.fixed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                ),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return;
          }
          
          // Exact alarm permission request disabled for demo release
        }
        if (widget.task == null) {
          // Create new task
          await taskService.createTask(task);
          
          // Schedule notification if reminder is enabled
          if (task.isReminder) {
            final notificationService = SimpleNotificationService();
            await notificationService.scheduleTaskReminder(task);
          }
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(task.isReminder 
                  ? 'Task created with reminder set for ${DateFormat('MMM dd, h:mm a').format(task.dueDate)}!' 
                  : 'Task created successfully!'),
                behavior: SnackBarBehavior.fixed,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              ),
            );
          }
        } else {
          // Update existing task
          await taskService.updateTask(task);
          // Note: TaskNotificationIntegration automatically handles notification scheduling
          // via Firestore listeners - no manual scheduling needed
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(task.isReminder 
                  ? 'Task updated with reminder set for ${DateFormat('MMM dd, h:mm a').format(task.dueDate)}!' 
                  : 'Task updated successfully!'),
                behavior: SnackBarBehavior.fixed,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              ),
            );
          }
        }
        if (context.mounted) {
          Navigator.pop(context); // Go back after saving
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(
            content: Text('Failed to save task: $e'),
            behavior: SnackBarBehavior.fixed,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ));
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.task == null ? 'New Task' : 'Edit Task',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, size: 24, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveTask,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_appBarColor),
                    ),
                  )
                : Text(
                    widget.task == null ? 'Create' : 'Save',
                    style: TextStyle(
                      color: _appBarColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        color: colorScheme.surface,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // Task Title Input
                  Text(
                    'What needs to be done?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                const SizedBox(height: 12),
                _buildSimpleTextField(
                  controller: _titleController,
                  hintText: 'Enter task title...',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Description Input
                Text(
                  'Add details (optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSimpleTextField(
                  controller: _descriptionController,
                  hintText: 'Add more details about your task...',
                  maxLines: 3,
                  isOptional: true,
                ),
                
                const SizedBox(height: 32),
                
                // Date & Time
                Text(
                  'When is this due?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSimpleDateSelector(),
                
                const SizedBox(height: 24),
                
                // Category & Priority Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSimpleCategorySelector(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Priority',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSimplePrioritySelector(),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Reminder Toggle
                _buildSimpleReminderToggle(),
                
                // Subtasks Section (if editing existing task)
                if (widget.task != null && widget.task!.subtasks.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Subtasks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.task!.subtasks.map((subtask) => _buildSimpleSubtaskTile(subtask)),
                ],
                
                // Add Subtasks Button (only when creating new task)
                if (widget.task == null) ...[
                  const SizedBox(height: 32),
                  _buildSimpleAddSubtasksButton(),
                ],
                
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
      )
    );
  }

  // Simple UI Helper Methods
  Widget _buildSimpleTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    int? maxLines,
    bool isOptional = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceVariant.withOpacity(0.3) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? colorScheme.outline.withOpacity(0.3) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines ?? 1,
        validator: validator,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.5),
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _appBarColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleDateSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceVariant.withOpacity(0.3) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? colorScheme.outline.withOpacity(0.3) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectDate(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: _appBarColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('EEEE, MMM dd, yyyy • h:mm a').format(_dueDate),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: colorScheme.onSurface.withOpacity(0.4),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleCategorySelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceVariant.withOpacity(0.3) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? colorScheme.outline.withOpacity(0.3) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        value: _selectedCategory,
        hint: Text('Select', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
        isExpanded: true,
        items: _categories.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category[0].toUpperCase() + category.substring(1),
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedCategory = newValue;
              _updateAppBarColor();
            });
          }
        },
      ),
    );
  }

  Widget _buildSimplePrioritySelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceVariant.withOpacity(0.3) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? colorScheme.outline.withOpacity(0.3) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<TaskPriority>(
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        value: _selectedPriority,
        hint: Text('Select', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
        isExpanded: true,
        items: TaskPriority.values.map((TaskPriority priority) {
          return DropdownMenuItem<TaskPriority>(
            value: priority,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    priority.toString().split('.').last.toUpperCase(),
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (TaskPriority? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedPriority = newValue;
              _updateAppBarColor();
            });
          }
        },
      ),
    );
  }

  Widget _buildSimpleReminderToggle() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceVariant.withOpacity(0.3) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? colorScheme.outline.withOpacity(0.3) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isReminder ? Icons.notifications_active : Icons.notifications_off_outlined,
              color: _isReminder ? _appBarColor : colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Set reminder notification',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Switch(
              value: _isReminder,
              activeColor: _appBarColor,
              onChanged: (value) {
                setState(() {
                  _isReminder = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleSubtaskTile(Subtask subtask) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceVariant.withOpacity(0.3) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? colorScheme.outline.withOpacity(0.3) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtask.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          if (subtask.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtask.description,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Due: ${DateFormat('MMM dd, yyyy').format(subtask.deadline)}',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleAddSubtasksButton() {
    return Container(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          bool isEditMode = widget.task != null;
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubtaskScreen(
                existingSubtasks: _subtasks,
                isEditMode: isEditMode,
              ),
            ),
          );

          if (result != null && result is List<Subtask>) {
            setState(() {
              _subtasks = result;
            });
          }
        },
        icon: Icon(
          Icons.add,
          color: _appBarColor,
          size: 20,
        ),
        label: Text(
          'Add Subtasks',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _appBarColor,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: _appBarColor.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Helper methods for colors
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'academics':
        return Colors.blue;
      case 'social':
        return Colors.purple;
      case 'personal':
        return Colors.green;
      case 'health':
        return Colors.red;
      case 'work':
        return Colors.orange;
      case 'finance':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
    }
  }

  // Helper method to convert string priority to TaskPriority enum
  TaskPriority? _stringToPriority(String? priorityString) {
    if (priorityString == null) return null;
    
    switch (priorityString.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'medium':
        return TaskPriority.medium;
      case 'high':
        return TaskPriority.high;
      case 'urgent':
        return TaskPriority.urgent;
      default:
        return TaskPriority.medium; // Default fallback
    }
  }
}
