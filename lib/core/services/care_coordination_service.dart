import 'dart:async';

class CareTask {
  final String id;
  final String title;
  final String memberId;
  final String? assigneeId;
  final DateTime dueDate;
  final bool completed;
  final String? notes;

  CareTask({
    required this.id,
    required this.title,
    required this.memberId,
    this.assigneeId,
    required this.dueDate,
    this.completed = false,
    this.notes,
  });

  CareTask copyWith({
    String? title,
    String? memberId,
    String? assigneeId,
    DateTime? dueDate,
    bool? completed,
    String? notes,
  }) => CareTask(
        id: id,
        title: title ?? this.title,
        memberId: memberId ?? this.memberId,
        assigneeId: assigneeId ?? this.assigneeId,
        dueDate: dueDate ?? this.dueDate,
        completed: completed ?? this.completed,
        notes: notes ?? this.notes,
      );
}

class CarePlan {
  final String id;
  final String memberId;
  final String title;
  final DateTime createdAt;
  final int version;

  CarePlan({
    required this.id,
    required this.memberId,
    required this.title,
    required this.createdAt,
    required this.version,
  });
}

class CareCoordinationService {
  final _tasks = <CareTask>[];
  final _plans = <CarePlan>[];
  final _controller = StreamController<List<CareTask>>.broadcast();

  Stream<List<CareTask>> get taskStream => _controller.stream;

  List<CarePlan> getCarePlans(String memberId) =>
      _plans.where((p) => p.memberId == memberId).toList();

  List<CareTask> getTasksForMember(String memberId) =>
      _tasks.where((t) => t.memberId == memberId).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  CarePlan createPlan({required String memberId, required String title}) {
    final plan = CarePlan(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      memberId: memberId,
      title: title,
      createdAt: DateTime.now(),
      version: 1,
    );
    _plans.add(plan);
    return plan;
  }

  CareTask addTask({
    required String memberId,
    required String title,
    DateTime? dueDate,
    String? assigneeId,
    String? notes,
  }) {
    final task = CareTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      memberId: memberId,
      assigneeId: assigneeId,
      dueDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
      notes: notes,
    );
    _tasks.add(task);
    _controller.add(_tasks);
    return task;
  }

  void toggleComplete(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(completed: !_tasks[idx].completed);
      _controller.add(_tasks);
    }
  }

  void assignTask(String taskId, String assigneeId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(assigneeId: assigneeId);
      _controller.add(_tasks);
    }
  }

  void dispose() {
    _controller.close();
  }
}
