import SwiftUI

@available(iOS 13, *)
public struct SimpleRoute<State, Body>: Route where Body: View {
    @usableFromInline
    var _prepareState: (EnvironmentValues) -> State
    
    @usableFromInline
    var _body: (State) -> Body
    
    @inlinable
    public init(prepareState: @escaping (EnvironmentValues) -> State, body: @escaping (State) -> Body) {
        _prepareState = prepareState
        _body = body
    }
    
    @inlinable
    public init(body: @escaping () -> Body) where State == Void {
        _prepareState = { _ in () }
        _body = { _ in body() }
    }
    
    @inlinable
    public func prepareState(environment: EnvironmentValues) -> State {
        _prepareState(environment)
    }
    
    @inlinable
    public func body(state: State) -> Body {
        _body(state)
    }
}
