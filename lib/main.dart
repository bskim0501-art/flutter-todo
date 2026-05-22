import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO 앱',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const TodoListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Todo {
  final String id;
  String title;
  bool isDone;
  final DateTime createdAt;

  Todo({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as String,
        title: json['title'] as String,
        isDone: json['isDone'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final List<Todo> _todos = [];
  final TextEditingController _controller = TextEditingController();
  String _filter = 'all'; // 'all', 'active', 'done'
  static const _storageKey = 'todos';

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List)
        .map((e) => Todo.fromJson(e as Map<String, dynamic>))
        .toList();
    setState(() {
      _todos
        ..clear()
        ..addAll(list);
    });
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_todos.map((t) => t.toJson()).toList()));
  }

  List<Todo> get _filteredTodos {
    switch (_filter) {
      case 'active':
        return _todos.where((t) => !t.isDone).toList();
      case 'done':
        return _todos.where((t) => t.isDone).toList();
      default:
        return List.from(_todos);
    }
  }

  int get _activeCount => _todos.where((t) => !t.isDone).length;

  void _addTodo() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _todos.insert(
        0,
        Todo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: text,
          createdAt: DateTime.now(),
        ),
      );
    });
    _controller.clear();
    _saveTodos();
  }

  void _toggleTodo(Todo todo) {
    setState(() {
      todo.isDone = !todo.isDone;
    });
    _saveTodos();
  }

  void _deleteTodo(Todo todo) {
    setState(() {
      _todos.removeWhere((t) => t.id == todo.id);
    });
    _saveTodos();
  }

  void _editTodo(Todo todo) {
    final editController = TextEditingController(text: todo.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할 일 수정'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(hintText: '할 일을 입력하세요'),
          onSubmitted: (_) {
            _applyEdit(todo, editController.text);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              _applyEdit(todo, editController.text);
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _applyEdit(Todo todo, String newTitle) {
    final text = newTitle.trim();
    if (text.isEmpty) return;
    setState(() {
      todo.title = text;
    });
    _saveTodos();
  }

  void _clearDone() {
    setState(() {
      _todos.removeWhere((t) => t.isDone);
    });
    _saveTodos();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTodos;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: const Text('TODO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          if (_todos.any((t) => t.isDone))
            TextButton.icon(
              onPressed: _clearDone,
              icon: Icon(Icons.delete_sweep, color: colorScheme.onPrimary),
              label: Text('완료 삭제', style: TextStyle(color: colorScheme.onPrimary)),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildInputArea(colorScheme),
          _buildFilterBar(colorScheme),
          _buildStats(colorScheme),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildTodoItem(filtered[index], colorScheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primaryContainer,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '새 할 일을 입력하세요...',
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _addTodo(),
              textInputAction: TextInputAction.done,
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: _addTodo,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Icon(Icons.add, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primaryContainer,
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _filterChip('all', '전체', colorScheme),
          const SizedBox(width: 8),
          _filterChip('active', '진행 중', colorScheme),
          const SizedBox(width: 8),
          _filterChip('done', '완료', colorScheme),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label, ColorScheme colorScheme) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: colorScheme.onPrimary,
      side: BorderSide.none,
    );
  }

  Widget _buildStats(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '남은 할 일: $_activeCount개 / 전체: ${_todos.length}개',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoItem(Todo todo, ColorScheme colorScheme) {
    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteTodo(todo),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: todo.isDone
                ? colorScheme.outlineVariant.withValues(alpha: 0.4)
                : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        color: todo.isDone
            ? colorScheme.surfaceContainerLow
            : colorScheme.surface,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: GestureDetector(
            onTap: () => _toggleTodo(todo),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: todo.isDone ? colorScheme.primary : Colors.transparent,
                border: Border.all(
                  color: todo.isDone ? colorScheme.primary : colorScheme.outline,
                  width: 2,
                ),
              ),
              child: todo.isDone
                  ? Icon(Icons.check, size: 16, color: colorScheme.onPrimary)
                  : null,
            ),
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.isDone ? TextDecoration.lineThrough : null,
              color: todo.isDone
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurface,
              fontSize: 15,
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.edit_outlined, size: 20, color: colorScheme.onSurfaceVariant),
            onPressed: () => _editTodo(todo),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist_rounded, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _filter == 'done' ? '완료된 할 일이 없습니다' : '할 일을 추가해보세요!',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
