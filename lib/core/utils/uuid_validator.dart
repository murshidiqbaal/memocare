// lib/core/utils/uuid_validator.dart

bool isValidUuid(String? id) {
  return id != null && id.isNotEmpty && id.length > 10;
}
