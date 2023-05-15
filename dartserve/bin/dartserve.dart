import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;

Future<void> main(List<String> arguments) async {
  // If the "PORT" environment variable is set, listen to it. Otherwise, 8080.
  // https://cloud.google.com/run/docs/reference/container-contract#port
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  // See https://pub.dev/documentation/shelf/latest/shelf/Cascade-class.html
  final cascade = Cascade().add(_staticHandler).add(_router);

  final server = await shelf_io.serve(
    logRequests().addHandler(cascade.handler), //纪录日志
    InternetAddress.anyIPv4,
    port,
  );

  print('Sreving at http://${server.address.host}:${server.port}');

  _watch.start();
}

final _staticHandler =
    shelf_static.createStaticHandler('public', defaultDocument: 'index.html');

final _router = shelf_router.Router()
  ..get('/helloworld', _helloWorldHandler)
  ..get('/time',
      (request) => Response.ok(DateTime.now().toUtc().toIso8601String()))
  ..get('/info.json', _infoHandler)
  ..get('/sum/<a|[0-9]+>/<b|[0-9]+>?/<c|[0-9]+>', _sumHandler);

Response _helloWorldHandler(Request request) => Response.ok('Hello, World');

// 把输入对象变成json格式字符串
String _jsonEncode(Object? data) =>
    const JsonEncoder.withIndent(' ').convert(data);

const _jsonHeaders = {
  'content-type': 'application.json',
};

Response _sumHandler(Request request, String a, String b, String? c) {
  final aNum = int.parse(a);
  final bNum = int.parse(b);
  if(c != null){
      final cNum = int.parse(c);
      return Response.ok(
      _jsonEncode({'a': aNum, 'b': bNum, 'c': cNum, 'sum': aNum + bNum + cNum}),
      headers: {
        ..._jsonHeaders,
        'Cache-Control': 'public, max-age=604800, immutable',
      },
    );
  }
  
  return Response.ok(
    _jsonEncode({'a': aNum, 'b': bNum, 'sum': aNum + bNum}),
    headers: {
      ..._jsonHeaders,
      'Cache-Control': 'public, max-age=604800, immutable',
    },
  );
}

final _watch = Stopwatch(); //计数器对象

int _requestCount = 0;

final _dartVersion = () {
  final version = Platform.version;
  return version.substring(0, version.indexOf(' '));
}();

Response _infoHandler(Request request) => Response(
      200,
      headers: {
        ..._jsonHeaders,
        'Cache-COntrol': 'no-store',
      },
      body: _jsonEncode(
        {
          'Dart version': _dartVersion,
          'uptime': _watch.elapsed.toString(),
          'requestCount': ++_requestCount,
        },
      ),
    );
