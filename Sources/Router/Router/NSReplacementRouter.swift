#if canImport(AppKit)
import Foundation
import SwiftUI

@available(macOS 10.15, *)
public struct NSReplacementRouter: NSViewControllerRepresentable, Router {
    @State var controller = NSViewController()
    @State var view = NSView()
    @State var childController: NSViewController?
    @State var dependenciesBag = ObjectDependenciesBag()
    
    public init<Root: Route>(root: Root) where Root.EnvironmentObjectDependency == VoidObservableObject {
        self.init()
        replace(
            with: ParentPresentor.present(
                parent: root,
                child: VoidRoute(),
                dependenciesBag: dependenciesBag
            )
        )
    }
    
    public init<Root: Route>(root: Root, _ environmentObject: Root.EnvironmentObjectDependency) {
        self.init()
        replace(
            with: ParentPresentor.present(
                parent: root,
                child: VoidRoute(),
                dependenciesBag: dependenciesBag
            )
        )
    }
    
    private init() {
        self.controller.view = self.view
    }
    
    public func navigate<Target>(with presentor: Target.Type, parent: Target.Parent, child: Target.Child) where Target : Presentor {
        let view = presentor.present(
            parent: parent,
            child: child,
            dependenciesBag: dependenciesBag
        )
        
        replace(with: view)
    }
    
    public func replaceRoot<Target>(with presentor: Target.Type, parent: Target.Parent, child: Target.Child) where Target : Presentor {
        let view = presentor.present(
            parent: parent,
            child: child,
            dependenciesBag: dependenciesBag
        )
        
        replace(with: view)
    }
    
    private func replace<Target: View>(with target: Target) {
        let target = NSHostingController(rootView: target)
        controller.view.removeConstraints(controller.view.constraints)
        for subview in controller.view.subviews {
            subview.removeFromSuperview()
        }
        
        childController?.view.removeFromSuperview()
        target.view.autoresizingMask = [.height, .width]
        controller.view.addSubview(target.view)
        target.view.frame = controller.view.frame
    }
    
    public func makeNSViewController(context: Context) -> NSViewController {
        controller
    }
    
    public func updateNSViewController(
        _ nsViewController: NSViewController,
        context: Context
    ) {
        childController?.view.frame = controller.view.frame
    }
}
#endif
