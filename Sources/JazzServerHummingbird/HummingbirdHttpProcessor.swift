import Foundation;

import Hummingbird;

import JazzCodec;
import JazzServer;

internal final class HummingbirdHttpProcessor: HttpProcessor {
    private final let requestProcessor: RequestProcessor;
    private final let transcoderCollection: TranscoderCollection;
    private final let cookieProcessor: CookieProcessor;

    internal init(
        requestProcessor: RequestProcessor,
        transcoderCollection: TranscoderCollection,
        cookieProcessor: CookieProcessor
    ) {
        self.requestProcessor = requestProcessor;
        self.transcoderCollection = transcoderCollection;
        self.cookieProcessor = cookieProcessor;
    }

    public final func start() async throws {
        let app: HBApplication = HBApplication(configuration: .init(address: .hostname("127.0.0.1", port: 8080)));

        //TODO route all requests in a less hacky way
        app.router.get("/", use: handle);
        app.router.put("/", use: handle);
        app.router.post("/", use: handle);
        app.router.delete("/", use: handle);
        app.router.patch("/", use: handle);
        app.router.get("*", use: handle);
        app.router.put("*", use: handle);
        app.router.post("*", use: handle);
        app.router.delete("*", use: handle);
        app.router.patch("*", use: handle);
        app.router.get("*/*", use: handle);
        app.router.put("*/*", use: handle);
        app.router.post("*/*", use: handle);
        app.router.delete("*/*", use: handle);
        app.router.patch("*/*", use: handle);
        app.router.get("*/*/*", use: handle);
        app.router.put("*/*/*", use: handle);
        app.router.post("*/*/*", use: handle);
        app.router.delete("*/*/*", use: handle);
        app.router.patch("*/*/*", use: handle);

        try app.start();

        app.wait();
    }

    private final func handle(_ httpRequest: HBRequest) async -> HBResponse {
        let requestStream: RequestStream = await getRequestStream(httpRequest);
        let resultStream: ResultStreamImpl = ResultStreamImpl();
    
        let builder: RequestContextBuilder = RequestContextBuilder()
            .with(rawInput: requestStream)
            .with(method: translate(method: httpRequest.method))
            .with(url: httpRequest.uri.string)
            .with(transcoderCollection: transcoderCollection)
            .with(cookieProcessor: cookieProcessor);

        for (headerKey, headerValue) in httpRequest.headers {
            _ = builder.with(header: headerKey, values: [headerValue]);
        }

        let request: RequestContext = try! builder.build();

        let result: ResultContext =
            try! ResultContextBuilder()
                .with(acceptMediaTypes: getMediaTypes(for: "Accept", in: httpRequest.headers))
                .with(transcoderCollection: transcoderCollection)
                .with(cookieProcessor: cookieProcessor)
                .with(resultStream: resultStream)
                .build();

        await requestProcessor.process(request: request, result: result);
        
        return populateResult(result, resultStream);
    }

    private final func translate(method: HTTPMethod) -> HttpMethod {
        switch (method)
        {
            case .GET:
                return .get;
            case .HEAD:
                return .head;
            case .POST:
                return .post;
            case .PUT:
                return .put;
            case .DELETE:
                return .delete;
            case .CONNECT:
                return .connect;
            case .OPTIONS:
                return .options;
            case .TRACE:
                return .trace;
            case .PATCH:
                return .patch;
            default:
                return .get;
        }
    }

    private final func getMediaTypes(for property: String, in headers: HTTPHeaders) -> [MediaType] {
        var mediaTypes: [MediaType] = [];

        for header in headers[property] {
            for mediaType in header.components(separatedBy: ",") {
                mediaTypes.append(MediaType(parseFrom: mediaType));
            }
        }

        return mediaTypes;
    }

    private final func getRequestStream(_ httpRequest: HBRequest) async -> RequestStream {
        switch httpRequest.body {
            case .byteBuffer(let body):
                if let body = body, body.readableBytes > 0 {
                    return BufferRequestStreamImpl(body);
                }

                return EmptyRequestStreamImpl();
            case .stream(let stream):
                return StreamRequestStreamImpl(stream);
        }
    }

    private final func populateResult(_ result: ResultContext, _ resultStream: ResultStreamImpl) -> HBResponse {
        var headers: HTTPHeaders = HTTPHeaders();

        for (key, values) in result.getHeaders() {
            for value in values {
                headers.add(name: key, value: value);
            }
        }

        return HBResponse(
            status: .custom(code: result.getStatusCode(), reasonPhrase: ""),
            headers: headers,
            body: HBResponseBody.stream(ResponseStreamer(result: resultStream))
        );
    }

    private final class ResponseStreamer: HBResponseBodyStreamer {
        private final let result: ResultStreamImpl;

        init(result: ResultStreamImpl) {
            self.result = result;
        }

        func read(on eventLoop: EventLoop) -> EventLoopFuture<HBStreamerOutput> {
            return result.getData(on: eventLoop);
        }
    }
}