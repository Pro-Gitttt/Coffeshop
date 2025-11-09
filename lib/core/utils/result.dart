// Simple functional-style Result type for success/failure
// Prefer explicit handling at call sites rather than throwing

class Result<T> {
  final T? data;
  final String? code;
  final String? message;

  const Result._({this.data, this.code, this.message});

  bool get isSuccess => data != null;
  bool get isFailure => data == null;

  static Result<T> ok<T>(T data) => Result._(data: data);
  static Result<T> fail<T>({String? code, String? message}) =>
      Result._(code: code, message: message);
}
