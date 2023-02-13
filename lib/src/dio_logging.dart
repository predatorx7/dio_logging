import 'dart:convert';
import 'dart:isolate';

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
    log(InterceptorLog(
      requestOptions: options,
    ));
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    super.onResponse(response, handler);
    log(InterceptorLog(
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
    log(InterceptorLog(
      dioErrorType: err.type,
      error: err.error,
      requestOptions: err.requestOptions,
      response: err.response,
      stackTrace: err.stackTrace,
    ));
  }

  Future<void> log(InterceptorLog log) async {
    final logAsJson = await Isolate.run(
      () => InterceptorLog._toJsonString(log),
    );
    if (log.error != null) {
      logger.severe(logAsJson, log.error, log.stackTrace);
    } else if (log.response != null) {
      logger.info(logAsJson, log.error, log.stackTrace);
    } else {
      logger.fine(logAsJson, log.error, log.stackTrace);
    }
  }
}

class InterceptorLog {
  final DioErrorType? dioErrorType;
  final Object? error;
  final RequestOptions requestOptions;
  final Response? response;
  final StackTrace? stackTrace;

  const InterceptorLog({
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

  static String _toJsonString(InterceptorLog log) {
    final logAsMap = log.toJson();
    final logAsJson = json.encode(logAsMap);
    return logAsJson;
  }
}
