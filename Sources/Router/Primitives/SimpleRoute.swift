import SwiftUI

@available(iOS 13, *)
public struct SimpleRoute<State, Body, EnvironmentObjectDependency>: Route where Body: View, EnvironmentObjectDependency: ObservableObject {
    @usableFromInline
    var _prepareState: (EnvironmentValues, EnvironmentObjectDependency) -> State
    
    @usableFromInline
    var _body: (State) -> Body
    
    @inlinable
    public init(dependency: EnvironmentObjectDependency.Type, prepareState: @escaping (EnvironmentValues, EnvironmentObjectDependency) -> State, body: @escaping (State) -> Body) {
        _prepareState = prepareState
        _body = body
    }
    
    @inlinable
    public init(prepareState: @escaping (EnvironmentValues) -> State, body: @escaping (State) -> Body) where EnvironmentObjectDependency == VoidEnvironmentObject {
        _prepareState = { values, _ in prepareState(values) }
        _body = body
    }
    
    @inlinable
    public init(body: @escaping () -> Body) where State == Void, EnvironmentObjectDependency == VoidEnvironmentObject {
        _prepareState = { _, _ in () }
        _body = { _ in body() }
    }
    
    @inlinable
    public func prepareState(environment: EnvironmentValues, environmentObject: EnvironmentObjectDependency) -> State {
        _prepareState(environment, environmentObject)
    }
    
    @inlinable
    public func body(state: State) -> Body {
        _body(state)
    }
}

@available(iOS 13, *)
public class VoidEnvironmentObject: ObservableObject {}
