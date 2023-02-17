import JazzConfiguration;
import JazzServer;

public final class HummingbirdHttpProcessorInitializer: ServerInitializer {
    public required init() {}

    public override final func initialize(for app: ServerApp, with configurationBuilder: ConfigurationBuilder) throws {
        _ = try app
            .wireUp(singleton: { sp in
                return HummingbirdHttpProcessor(
                    requestProcessor: try await sp.fetchType(),
                    transcoderCollection: try await sp.fetchType(),
                    cookieProcessor: try await sp.fetchType(),
                    logger: try await sp.fetchType()
                ) as HttpProcessor;
            });
    }
}