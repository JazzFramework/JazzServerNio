import Foundation;

import JazzCodec;

internal final class ResultStreamImpl: ResultStream {
    private static let BUFFER_SIZE: Int = 1024;

    //TODO: support writing to both.
    private var input: InputStream?;
    private var data: [[UInt8]];

    internal init() {
        data = [];
    }

    deinit {
        if let input {
            input.close();
        }
    }

    public final func write(_ data: [UInt8]) {
        self.data.append(data);
    }

    public final func write(_ data: String) {
        let encodedDataArray = [UInt8](data.utf8);

        write(encodedDataArray);
    }

    public final func write(_ data: InputStream) {
        input = data;

        data.open();
    }
    
    public final func write(_ data: UnsafeMutablePointer<UInt8>, maxLength: Int) {
        let a = UnsafeMutableBufferPointer(start: data, count: maxLength);
        let b = Array(a);

        write(b);
    }
}