import SwiftUI

@available(iOS 13, macOS 10.15, *)
public protocol Presentor {
    associatedtype Parent: Route
    associatedtype Child: Route
    associatedtype Body: View
    
    static func present(
        parent: Parent,
        child: Child,
        dependenciesBag: ObjectDependenciesBag
    ) -> Body
}

@available(iOS 13, macOS 10.15, *)
public struct SheetPresentor<Parent: Route, Child: Route>: Presentor {
    public static func present(
        parent: Parent,
        child: Child,
        dependenciesBag: ObjectDependenciesBag
    ) -> some View {
        let parentDependency = dependenciesBag.objectDependency(
            ofType: Parent.EnvironmentObjectDependency.self
        )
        
        let childDependency = dependenciesBag.objectDependency(
            ofType: Child.EnvironmentObjectDependency.self
        )
        
        let parentState = parent.prepareState(environmentObject: parentDependency)
        let childState = child.prepareState(environmentObject: childDependency)
        
        let presented = State(initialValue: true)
        
        return parent.body(state: parentState).sheet(
            isPresented: presented.projectedValue
        ) {
            child.body(state: childState).environmentObject(childDependency)
        }.environmentObject(parentDependency)
    }
}

@available(iOS 13, macOS 10.15, *)
public struct ParentPresentor<Parent: Route>: Presentor {
    public typealias Child = VoidRoute
    
    public static func present(
        parent: Parent,
        child: Child,
        dependenciesBag: ObjectDependenciesBag
    ) -> some View {
        let parentDependency = dependenciesBag.objectDependency(
            ofType: Parent.EnvironmentObjectDependency.self
        )
        
        let parentState = parent.prepareState(environmentObject: parentDependency)
        
        return parent.body(state: parentState).environmentObject(parentDependency)
    }
}

@available(iOS 13, macOS 10.15, *)
public struct VoidRoute: Route {
    public typealias State = Void
    public typealias EnvironmentObjectDependency = VoidObservableObject
    
    @inlinable internal init() {}
    
    public func body(state: Void) -> EmptyView {
        EmptyView()
    }
}

@available(iOS 13, macOS 10.15, *)
public final class ObjectDependenciesBag {
    var dependencies = [ObjectIdentifier: AnyObject]()
    
    internal func addObjectDependency<Dependency: ObservableObject>(_ dependency: Dependency) {
        dependencies[ObjectIdentifier(Dependency.self)] = dependency
    }
    
    func objectDependency<Dependency: ObservableObject>(
        ofType type: Dependency.Type = Dependency.self
    ) -> Dependency {
        dependencies[ObjectIdentifier(Dependency.self)] as! Dependency
    }
    
    internal init() {
        addObjectDependency(VoidObservableObject())
    }
}
