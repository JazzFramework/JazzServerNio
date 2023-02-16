import NIOCore
import NIOHTTP1
import NIOHTTP2
import NIOPosix
import NIOSSL

final class ErrorHandler: ChannelInboundHandler, Sendable {
    typealias InboundIn = Never

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Server received error: \(error)")
        context.close(promise: nil)
    }
}