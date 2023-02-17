import NIOCore
import NIOHTTP1
import NIOHTTP2
import NIOPosix
import NIOSSL

import JazzCodec;
import JazzServer;

internal final class NioHttpProcessor: HttpProcessor {
    private final let requestProcessor: RequestProcessor;
    private final let transcoderCollection: TranscoderCollection;

    internal init(requestProcessor: RequestProcessor, transcoderCollection: TranscoderCollection) {
        self.requestProcessor = requestProcessor;
        self.transcoderCollection = transcoderCollection;
    }

    public final func start() async throws {
    }
}