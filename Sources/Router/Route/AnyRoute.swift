/// A type-erased route.
@available(iOS 13, macOS 10.15, *)
public typealias AnyRoute = AnyEnvironmentDependentRoute<VoidObservableObject>

@available(iOS 13, macOS 10.15, *)
extension AnyRoute: Route {}
