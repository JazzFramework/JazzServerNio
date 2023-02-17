import JazzConfiguration;
import JazzServer;

public final class NioHttpProcessorInitializer: ServerInitializer {
    public required init() {}

    public override final func initialize(for app: ServerApp, with configurationBuilder: ConfigurationBuilder) throws {
        _ = try app
            .wireUp(singleton: { _, sp in
                return NioHttpProcessor(
                    requestProcessor: try await sp.fetchType(),
                    transcoderCollection: try await sp.fetchType()
                ) as HttpProcessor;
            });
    }
}