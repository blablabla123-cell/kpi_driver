import '../../domain/entities/task_item.dart';
import '../dto/indicator_task_dto.dart';

extension IndicatorTaskMapper on IndicatorTaskDto {
  TaskItem toDomain() {
    return TaskItem(
      indicatorToMoId: indicatorToMoId,
      name: name,
      parentId: parentId,
      order: order,
    );
  }
}

