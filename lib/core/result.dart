import 'package:equatable/equatable.dart';

sealed class Result<T> extends Equatable {
  const Result();

  @override
  List<Object?> get props => [];
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  List<Object?> get props => [data];
}

class Failure<T> extends Result<T> {
  final String message;
  final int? statusCode;
  final dynamic error;

  const Failure({
    required this.message,
    this.statusCode,
    this.error,
  });

  @override
  List<Object?> get props => [message, statusCode, error];
}

class Loading<T> extends Result<T> {
  const Loading();
}

class Empty<T> extends Result<T> {
  const Empty();
}
