import JazzCodec;

internal final class EmptyRequestStreamImpl: RequestStream {
    public final func hasData() -> Bool {
        return false;
    }

    public final func read(into buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) -> Int {
        return 0;
    }
}