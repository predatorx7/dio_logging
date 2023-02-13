import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_logging/src/logger.dart';
import 'package:logging/logging.dart';

class DioLogging extends Interceptor {
  final Logger logger;

  DioLogging({
    Logger? logger,
  }) : logger = logger ?? dioLogger;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    super.onRequest(options, handler);
    log(InterceptedNetworkLog(
      requestOptions: options,
    ));
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    super.onResponse(response, handler);
    log(InterceptedNetworkLog(
      requestOptions: response.requestOptions,
      response: response,
    ));
  }

  @override
  void onError(
    DioError err,
    ErrorInterceptorHandler handler,
  ) {
    super.onError(err, handler);
    log(InterceptedNetworkLog(
      dioErrorType: err.type,
      error: err.error,
      requestOptions: err.requestOptions,
      response: err.response,
      stackTrace: err.stackTrace,
    ));
  }

  Future<void> log(InterceptedNetworkLog log) async {
    if (log.error != null) {
      logger.severe(log, log.error, log.stackTrace);
    } else if (log.response != null) {
      logger.info(log, log.error, log.stackTrace);
    } else {
      logger.fine(log, log.error, log.stackTrace);
    }
  }
}

class InterceptedNetworkLog {
  final DioErrorType? dioErrorType;
  final Object? error;
  final RequestOptions requestOptions;
  final Response? response;
  final StackTrace? stackTrace;

  const InterceptedNetworkLog({
    this.dioErrorType,
    this.error,
    required this.requestOptions,
    this.response,
    this.stackTrace,
  });

  Map<String, Object?> toJson() {
    final response = this.response;
    requestOptions.uri;
    return {
      if (dioErrorType != null) 'dio_error_type': dioErrorType.toString(),
      if (error != null) 'error': error.toString(),
      'request': {
        'data': requestOptions.data,
        if (requestOptions.path.isNotEmpty) 'path': requestOptions.path,
        'uri': requestOptions.uri.toString(),
        if (requestOptions.baseUrl.isNotEmpty)
          'baseUrl': requestOptions.baseUrl,
        'connectTimeout': requestOptions.connectTimeout,
        if (requestOptions.contentType != null)
          'contentType': requestOptions.contentType,
        if (requestOptions.extra.isNotEmpty) 'extra': requestOptions.extra,
        'followRedirects': requestOptions.followRedirects,
        if (requestOptions.headers.isNotEmpty)
          'headers': requestOptions.headers,
        'listFormat': requestOptions.listFormat.toString(),
        'maxRedirects': requestOptions.maxRedirects,
        'method': requestOptions.method,
        if (requestOptions.queryParameters.isNotEmpty)
          'queryParameters': requestOptions.queryParameters,
        'receiveDataWhenStatusError': requestOptions.receiveDataWhenStatusError,
        'receiveTimeout': requestOptions.receiveTimeout,
        'responseType': requestOptions.responseType.toString(),
        'sendTimeout': requestOptions.sendTimeout,
      },
      if (response != null)
        'response': {
          "data": response.data,
          if (response.extra.isNotEmpty) "extra": response.extra,
          if (response.headers.map.isNotEmpty) "headers": response.headers.map,
          "isRedirect": response.isRedirect,
          "realUri": response.realUri.toString(),
          "statusCode": response.statusCode,
          if (response.statusMessage != null)
            "statusMessage": response.statusMessage,
        },
    };
  }

  static String toJsonString(InterceptedNetworkLog log) {
    final logAsMap = log.toJson();
    final logAsJson = json.encode(logAsMap);
    return logAsJson;
  }

  String toPrettyLog() {
    final buffer = StringBuffer();
    buffer.writeln('===== Intercepted Network ==========');
    if (error != null) {
      buffer.writeln('$dioErrorType $error');
      if (stackTrace != null) {
        buffer.writeln(stackTrace.toString());
        buffer.writeln();
      }
    }

    String tryJson(Object? object) {
      if (object == null) return '';
      if (object is! Map && object is! List) return object.toString();
      try {
        return json.encode(object);
      } catch (_) {
        return object.toString();
      }
    }

    final request = {
      if (requestOptions.path.isNotEmpty) 'path': requestOptions.path,
      'uri': requestOptions.uri.toString(),
      if (requestOptions.baseUrl.isNotEmpty) 'baseUrl': requestOptions.baseUrl,
      'connectTimeout': requestOptions.connectTimeout,
      if (requestOptions.contentType != null)
        'contentType': requestOptions.contentType,
      if (requestOptions.extra.isNotEmpty) 'extra': requestOptions.extra,
      'followRedirects': requestOptions.followRedirects,
      if (requestOptions.headers.isNotEmpty) 'headers': tryJson(requestOptions.headers),
      'listFormat': requestOptions.listFormat.toString(),
      'maxRedirects': requestOptions.maxRedirects,
      if (requestOptions.queryParameters.isNotEmpty)
        'queryParameters': tryJson(requestOptions.queryParameters),
      'receiveDataWhenStatusError': requestOptions.receiveDataWhenStatusError,
      'receiveTimeout': requestOptions.receiveTimeout,
      'responseType': requestOptions.responseType.toString(),
      'sendTimeout': requestOptions.sendTimeout,
    };
    buffer.writeln('---- REQUEST (METHOD ${requestOptions.method}) ----');
    for (final entry in request.entries) {
      buffer.writeln(
        'request.${entry.key}: ${tryJson(entry.value)}',
      );
    }
    if (requestOptions.data != null) {
      buffer.writeln('[REQUEST BODY]');
      buffer.writeln(tryJson(requestOptions.data));
      buffer.writeln('END [REQUEST BODY]');
    } else {
      buffer.writeln('[REQUEST BODY is NULL]');
    }
    buffer.writeln('---- X ----');

    final response = this.response;

    if (response != null) {
      final responseData = {
        if (response.extra.isNotEmpty) "extra": response.extra,
        if (response.headers.map.isNotEmpty) "headers": tryJson(response.headers.map),
        "isRedirect": response.isRedirect,
        "realUri": response.realUri.toString(),
        if (response.statusMessage != null)
          "statusMessage": response.statusMessage,
      };
      buffer.writeln('---- RESPONSE (STATUS ${response.statusCode}) ----');
      for (final entry in responseData.entries) {
        buffer.writeln(
          'response.${entry.key}: ${tryJson(entry.value)}',
        );
      }
      if (response.data != null) {
        buffer.writeln('[RESPONSE DATA]');
        buffer.writeln(tryJson(response.data));
        buffer.writeln('END [RESPONSE DATA]');
      } else {
        buffer.writeln('[RESPONSE DATA is NULL]');
      }
      buffer.writeln('---- X ----');
    }
    buffer.writeln('===== END Intercepted Network ==========');

    return buffer.toString();
  }

  @override
  String toString() {
    return toJsonString(this);
  }
}
