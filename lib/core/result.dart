/// ══════════════════════════════════════════════════════════════
/// Result<T> — Bọc kết quả trả về kiểu-an-toàn (type-safe)
///
/// Thay vì trả về null hoặc ném lỗi bừa bãi,
/// mọi Repository/Service trả về Result<T> để:
///   • Phân biệt thành công / thất bại rõ ràng
///   • Mang thông điệp lỗi cụ thể cho UI
///   • Không cần try/catch lan tràn ở mọi nơi
///
/// Ví dụ sử dụng:
///   final result = await authRepo.login(email, password);
///   if (result.isSuccess) navigate();
///   else showError(result.error);
/// ══════════════════════════════════════════════════════════════
class Result<T> {
  final T? data;
  final String? error;

  const Result._({this.data, this.error});

  factory Result.success(T data) => Result._(data: data);
  factory Result.failure(String error) => Result._(error: error);
  factory Result.empty() => const Result._();

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  /// Trả về data hoặc fallback nếu không có
  T dataOr(T fallback) => data ?? fallback;

  /// Dùng như pattern matching
  R when<R>({
    required R Function(T data) success,
    required R Function(String error) failure,
  }) {
    if (isSuccess && data != null) return success(data as T);
    return failure(error ?? 'Lỗi không xác định');
  }

  @override
  String toString() =>
      isSuccess ? 'Result.success($data)' : 'Result.failure($error)';
}
