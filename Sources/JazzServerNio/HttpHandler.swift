import Foundation;

import NIOCore;
import NIOHTTP1;
import NIOHTTP2;
import NIOPosix;
import NIOSSL;

import JazzCodec;
import JazzLogging;
import JazzServer;

internal final class HttpHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart;
    typealias OutboundOut = HTTPServerResponsePart;

    private final let requestProcessor: RequestProcessor;
    private final let transcoderCollection: TranscoderCollection;
    private final let cookieProcessor: CookieProcessor;
    private final let logger: Logger;

    internal init(
        _ requestProcessor: RequestProcessor,
        _ transcoderCollection: TranscoderCollection,
        _ cookieProcessor: CookieProcessor,
        _ logger: Logger
    ) {
        self.requestProcessor = requestProcessor;
        self.transcoderCollection = transcoderCollection;
        self.cookieProcessor = cookieProcessor;
        self.logger = logger;
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        guard case .end = self.unwrapInboundIn(data) else {
            return
        }
/*
        // Insert an event loop tick here. This more accurately represents real workloads in SwiftNIO, which will not
        // re-entrantly write their response frames.
        context.eventLoop.execute {
            context.channel.getOption(HTTP2StreamChannelOptions.streamID).flatMap { (streamID) -> EventLoopFuture<Void> in
                let resultContext: ResultContext = try! await run();

                var headers: HTTPHeaders = HTTPHeaders();

                for (key, values) in resultContext.getHeaders() {
                    for value in values {
                        headers.add(name: key, value: value);
                    }
                }

                //headers.add(name: "content-length", value: "5")
                //headers.add(name: "x-stream-id", value: String(Int(streamID)))

                context.channel.write(self.wrapOutboundOut(HTTPServerResponsePart.head(HTTPResponseHead(version: .init(major: 2, minor: 0), status: .ok, headers: headers))), promise: nil)

                var buffer = context.channel.allocator.buffer(capacity: 12)
                buffer.writeStaticString("hello")
                context.channel.write(self.wrapOutboundOut(HTTPServerResponsePart.body(.byteBuffer(buffer))), promise: nil)
                return context.channel.writeAndFlush(self.wrapOutboundOut(HTTPServerResponsePart.end(nil)))
            }.whenComplete { _ in
                context.close(promise: nil)
            }
        }
        */
    }

    private final func run() async throws -> ResultContext {
        let requestStream: RequestStream = EmptyRequestStreamImpl();
        let resultStream: ResultStreamImpl = ResultStreamImpl();

        let requestContext = try buildRequestContext(requestStream);
        let resultContext = try buildResultContext(resultStream);

        await requestProcessor.process(request: requestContext, result: resultContext);

        return resultContext;
    }

    private final func buildRequestContext(_ requestStream: RequestStream) throws -> RequestContext {
        let builder: RequestContextBuilder = RequestContextBuilder()
            .with(rawInput: requestStream)
            //.with(method: translate(method: httpRequest.method))
            //.with(url: httpRequest.uri.string)
            .with(transcoderCollection: transcoderCollection)
            .with(cookieProcessor: cookieProcessor);

        //for (headerKey, headerValue) in httpRequest.headers {
        //    _ = builder.with(header: headerKey, values: [headerValue]);
        //}

        return try builder.build();
    }

    private final func buildResultContext(_ resultStream: ResultStream) throws -> ResultContext {
        return try ResultContextBuilder()
            //.with(acceptMediaTypes: getMediaTypes(for: "Accept", in: httpRequest.headers))
            .with(transcoderCollection: transcoderCollection)
            .with(cookieProcessor: cookieProcessor)
            .with(resultStream: resultStream)
            .build();
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
}