import 'package:dio/dio.dart';
import '../models/task.dart';
import '../models/paginated_response.dart';

class TaskRepository {
  final Dio _dio;

  TaskRepository(this._dio);

  Future<PaginatedResponse<Task>> getTasks({
    int page = 1,
    int limit = 10,
    TaskStatus? status,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null) 'status': taskStatusToString(status),
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final res = await _dio.get('/tasks', queryParameters: queryParams);
    final data = res.data as Map<String, dynamic>;

    final tasks = (data['data'] as List<dynamic>)
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = data['meta'] as Map<String, dynamic>;

    return PaginatedResponse<Task>(
      data: tasks,
      page: meta['page'] as int,
      limit: meta['limit'] as int,
      total: meta['total'] as int,
      totalPages: meta['totalPages'] as int,
    );
  }

  Future<Task> createTask({
    required String title,
    String? description,
    TaskStatus status = TaskStatus.pending,
  }) async {
    final res = await _dio.post('/tasks', data: {
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      'status': taskStatusToString(status),
    });
    print(res.data);
    return Task.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Task> updateTask({
    required String id,
    String? title,
    String? description,
    TaskStatus? status,
  }) async {
    final res = await _dio.patch('/tasks/$id', data: {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (status != null) 'status': taskStatusToString(status),
    });
    return Task.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteTask(String id) async {
    await _dio.delete('/tasks/$id');
  }

  Future<Task> toggleTask(String id) async {
    final res = await _dio.patch('/tasks/$id/toggle');
    return Task.fromJson(res.data as Map<String, dynamic>);
  }
}
