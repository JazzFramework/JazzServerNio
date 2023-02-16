import Hummingbird;

import JazzCodec;

internal final class StreamRequestStreamImpl: RequestStream {
    private let stream: HBRequestBodyStreamerSequence.AsyncIterator;
    private var next: ByteBuffer?;

    internal init(_ stream: HBByteBufferStreamer) {
        self.stream = stream.sequence.makeAsyncIterator();
    }

    public final func hasData() -> Bool {
        if var byteBuffer = next {
            if byteBuffer.readableBytes > 0 {
                return true;
            }
        }

        do {
            Task {
                next = try await stream.next();
            }

            return next != nil;
        } catch {
            return false;
        }
    }

    public final func read(into buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) -> Int {
        if var byteBuffer = next, let data = byteBuffer.readBytes(length: min(maxLength, byteBuffer.readableBytes)) {
            buffer.initialize(from: data, count: data.count);

            return data.count;
        }

        return 0;
    }
}