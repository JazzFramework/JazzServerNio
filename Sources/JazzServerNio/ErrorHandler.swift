import NIOCore;

final class ErrorHandler: ChannelInboundHandler, Sendable {
    typealias InboundIn = Never;

    public final func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Server received error: \(error)");

        context.close(promise: nil);
    }
}