import Foundation;

import NIOCore
import NIOHTTP1
import NIOHTTP2
import NIOPosix
import NIOSSL

import JazzCodec;
import JazzServer;

internal final class HttpHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart;
    typealias OutboundOut = HTTPServerResponsePart;

    private let requestProcessor: RequestProcessor;
    private let transcoderCollection: TranscoderCollection;

 //   private var requestBoundStreams: BoundStreams = BoundStreams();
  //  private var responseBoundStreams: BoundStreams = BoundStreams();

//    private var requestContext: RequestContext? = nil;
//    private var resultContext: ResultContext? = nil;

    internal init(_ requestProcessor: RequestProcessor, _ transcoderCollection: TranscoderCollection) {
        self.requestProcessor = requestProcessor;
        self.transcoderCollection = transcoderCollection;
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        guard case .end = self.unwrapInboundIn(data) else {
            return
        }

        // Insert an event loop tick here. This more accurately represents real workloads in SwiftNIO, which will not
        // re-entrantly write their response frames.
        context.eventLoop.execute {
            context.channel.getOption(HTTP2StreamChannelOptions.streamID).flatMap { (streamID) -> EventLoopFuture<Void> in
                var headers = HTTPHeaders()
                headers.add(name: "content-length", value: "5")
                headers.add(name: "x-stream-id", value: String(Int(streamID)))
                context.channel.write(self.wrapOutboundOut(HTTPServerResponsePart.head(HTTPResponseHead(version: .init(major: 2, minor: 0), status: .ok, headers: headers))), promise: nil)

                var buffer = context.channel.allocator.buffer(capacity: 12)
                buffer.writeStaticString("hello")
                context.channel.write(self.wrapOutboundOut(HTTPServerResponsePart.body(.byteBuffer(buffer))), promise: nil)
                return context.channel.writeAndFlush(self.wrapOutboundOut(HTTPServerResponsePart.end(nil)))
            }.whenComplete { _ in
                context.close(promise: nil)
            }
        }

/*
        switch self.unwrapInboundIn(data) {
            case .head(let request):
                print("head start");

                self.keepAlive = request.isKeepAlive;
                self.state.requestReceived();

                requestContext = buildRequestContext(requestBoundStreams, request);
                resultContext = buildResultContext(responseBoundStreams, request);

                let responseHead: HTTPResponseHead = httpResponseHead(request: request, status: getResponseStatus(resultContext!));
                //responseHead.headers.add(name: "content-length", value: "\(self.buffer!.readableBytes)");
                let response = HTTPServerResponsePart.head(responseHead);
                context.write(self.wrapOutboundOut(response), promise: nil);

                print("head end");
                break;
            case .body(let requestBody):
                print("body start");

                populateRequest(streams: requestBoundStreams, with: requestBody);

                print("body end");
                break;
            case .end:
                print("end start");

                if let requestContext = requestContext, let resultContext = resultContext {
                    Task {
                        await self.requestProcessor.process(request: requestContext, result: resultContext);
                    }

                    populateResult(streams: responseBoundStreams);
                }

                self.state.requestComplete();

                let content = HTTPServerResponsePart.body(.byteBuffer(buffer!.slice()));
                context.write(self.wrapOutboundOut(content), promise: nil);
                self.completeResponse(context, trailers: nil, promise: nil);

                print("end end");
                break;
        }
        */
    }
    /*
    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush();
    }

    public func handlerAdded(context: ChannelHandlerContext) {
        self.requestBoundStreams = BoundStreams();
        self.responseBoundStreams = BoundStreams();

        self.buffer = context.channel.allocator.buffer(capacity: 0);
    }

    public func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        switch event {
        case let evt as ChannelEvent where evt == ChannelEvent.inputClosed:
            // The remote peer half-closed the channel. At this time, any
            // outstanding response will now get the channel closed, and
            // if we are idle or waiting for a request body to finish we
            // will close the channel immediately.
            switch self.state {
            case .idle, .waitingForRequestBody:
                context.close(promise: nil);
            case .sendingResponse:
                self.keepAlive = false;
            }
        default:
            context.fireUserInboundEventTriggered(event);
        }
    }

    private func completeResponse(_ context: ChannelHandlerContext, trailers: HTTPHeaders?, promise: EventLoopPromise<Void>?) {
        self.state.responseComplete();

        let promise = self.keepAlive ? promise : (promise ?? context.eventLoop.makePromise());

        if !self.keepAlive {
            promise!.futureResult.whenComplete { (_: Result<Void, Error>) in
                context.close(promise: nil);
            }
        }

        context.writeAndFlush(self.wrapOutboundOut(.end(trailers)), promise: promise);
    }

    private func httpResponseHead(request: HTTPRequestHead, status: HTTPResponseStatus, headers: HTTPHeaders = HTTPHeaders()) -> HTTPResponseHead {
        var head = HTTPResponseHead(version: request.version, status: status, headers: headers);
        let connectionHeaders: [String] = head.headers[canonicalForm: "connection"].map { $0.lowercased() };

        if !connectionHeaders.contains("keep-alive") && !connectionHeaders.contains("close") {
            // the user hasn't pre-set either 'keep-alive' or 'close', so we might need to add headers
            switch (request.isKeepAlive, request.version.major, request.version.minor) {
            case (true, 1, 0):
                // HTTP/1.0 and the request has 'Connection: keep-alive', we should mirror that
                head.headers.add(name: "Connection", value: "keep-alive");
            case (false, 1, let n) where n >= 1:
                // HTTP/1.1 (or treated as such) and the request has 'Connection: close', we should mirror that
                head.headers.add(name: "Connection", value: "close");
            default:
                // we should match the default or are dealing with some HTTP that we don't support, let's leave as is
                ()
            }
        }
        return head;
    }

    private static func translate(method: HTTPMethod) -> HttpMethod {
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

    private static func getMediaTypes(for property: String, in headers: HTTPHeaders) -> [MediaType] {
        var mediaTypes: [MediaType] = [];

        for header in headers[property] {
            mediaTypes.append(MediaType(parseFrom: header));
        }

        return mediaTypes;
    }

    private func populateRequest(streams: BoundStreams, with body: ByteBuffer) {
        //todo: read in chunks
        if body.readableBytes > 0 {
            if let data = body.getBytes(at: 0, length: body.readableBytes) {
                streams.output.write(data, maxLength: body.readableBytes);
            }
        }
    }

    private func populateResult(streams: BoundStreams) {
        self.buffer.clear();

        let bufferSize = 1024;
        let inputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize);
        while streams.input.hasBytesAvailable {
            let read = streams.input.read(inputBuffer, maxLength: bufferSize);
            if (read == 0) {
                break;
            }
            self.buffer.writeBytes(UnsafeRawBufferPointer(start: inputBuffer, count: read));
        }
        inputBuffer.deallocate();

        self.buffer.writeString("test");
    }

    private func getResponseStatus(_ resultContext: ResultContext) -> HTTPResponseStatus {
        print("\(resultContext.getStatusCode())")

        return .custom(code: resultContext.getStatusCode(), reasonPhrase: "");
    }

    private func buildResultContext(_ responseBoundStreams: BoundStreams, _ request: HTTPRequestHead) -> ResultContext {
        let builder: ResultContextBuilder = ResultContextBuilder()
            .with(acceptMediaTypes: HttpHandler.getMediaTypes(for: "Accept", in: request.headers))
            .with(transcoderCollection: transcoderCollection)
            .with(outputStream: responseBoundStreams.output);
            
        return try! builder.build();
    }

    private func buildRequestContext(_ requestBoundStreams: BoundStreams, _ request: HTTPRequestHead) -> RequestContext {
        let builder: RequestContextBuilder = RequestContextBuilder()
            .with(rawInput: requestBoundStreams.input)
            .with(method: HttpHandler.translate(method: request.method))
            .with(url: request.uri)
            .with(transcoderCollection: transcoderCollection);

            for (headerKey, headerValue) in request.headers {
                _ = builder.with(header: headerKey, values: [headerValue]);
            }

        return try! builder.build();
    }
    */
}