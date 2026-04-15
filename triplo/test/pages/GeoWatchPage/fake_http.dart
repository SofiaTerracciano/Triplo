import 'dart:io';

class FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return FakeHttpClient();
  }
}

class FakeHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return FakeHttpRequest();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return FakeHttpResponse();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  Stream<List<int>> handleError(Function onError,
          {bool Function(dynamic error)? test}) =>
      const Stream.empty();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

