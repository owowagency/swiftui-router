import Combine

/// An empty observable object, used to express that a given `Route` has no dependency on the environment.
@available(iOS 13, macOS 10.15, *)
public final class VoidObservableObject: ObservableObject {
    public init() {}
}
