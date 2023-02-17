import JazzCodec;

internal final class BufferRequestStreamImpl: RequestStream {
    public final func hasData() -> Bool { false }

    public final func read(into buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) -> Int { 0 }
}