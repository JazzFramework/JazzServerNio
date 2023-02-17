import Foundation;

import Hummingbird;

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

    internal final func getData(on eventLoop: EventLoop) ->EventLoopFuture<HBStreamerOutput> {
        if let stream = input {
            if stream.hasBytesAvailable {
                var buffer = ByteBuffer();
                buffer.clear();

                let inputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: ResultStreamImpl.BUFFER_SIZE);
                defer {
                    inputBuffer.deallocate();
                }

                let read = stream.read(inputBuffer, maxLength: ResultStreamImpl.BUFFER_SIZE);
                if (read == 0) {
                    return eventLoop.makeSucceededFuture(.end);
                }

                buffer.writeBytes(UnsafeRawBufferPointer(start: inputBuffer, count: read));
                return eventLoop.makeSucceededFuture(.byteBuffer(buffer));
            } else {
                return eventLoop.makeSucceededFuture(.end);
            }
        } else if data.count > 0 {
            var buffer = ByteBuffer();
            buffer.clear();
            buffer.writeBytes(data[0]);

            data.removeFirst(1);

            return eventLoop.makeSucceededFuture(.byteBuffer(buffer));
        }

        return eventLoop.makeSucceededFuture(.end);
    }
}