/// Значения `parent_id` в API (form field `field_value`).
class TaskParentIdCodec {
  const TaskParentIdCodec._();

  static String toApiValue(int? parentId) {
    if (parentId == null || parentId == 0) return '0';
    return parentId.toString();
  }
}
