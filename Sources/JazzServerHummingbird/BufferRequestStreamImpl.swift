import Hummingbird;

import JazzCodec;

internal final class BufferRequestStreamImpl: RequestStream {
    private var byteBuffer: ByteBuffer;

    internal init(_ byteBuffer: ByteBuffer) {
        self.byteBuffer = byteBuffer;
    }

    public final func hasData() -> Bool {
        return byteBuffer.readableBytes > 0;
    }

    public final func read(into buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) -> Int {
        if let data = byteBuffer.readBytes(length: min(maxLength, byteBuffer.readableBytes)) {
            buffer.initialize(from: data, count: data.count);

            return data.count;
        }

        return 0;
    }
}