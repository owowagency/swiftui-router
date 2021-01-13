import SwiftUI

#if canImport(AppKit)
@available(iOS 13, macOS 10.15, *)
fileprivate struct HostingControllerRepresentable<V: View>: NSViewControllerRepresentable {
    let hostingController: HostingController<V>
    
    func makeNSViewController(context: Context) -> HostingController<V> {
        hostingController
    }
    
    func updateNSViewController(_ nsViewController: HostingController<V>, context: Context) { }
}
#elseif canImport(UIKit)
@available(iOS 13, macOS 10.15, *)
fileprivate struct HostingControllerRepresentable<V: View>: UIViewControllerRepresentable {
    let hostingController: NSHostingController<V>
    
    func makeUIViewController(context: Context) -> HostingController<V> {
        hostingController
    }
    
    func updateUIViewController(_ nsViewController: HostingController<V>, context: Context) { }
}
#endif

#if canImport(AppKit) || canImport(UIKit)
@available(iOS 13, macOS 10.15, *)
public struct SwiftUIRouterView: View {
    @State var router: SwiftUIRouter
    
    public init(router: SwiftUIRouter) {
        self._router = State(wrappedValue: router)
    }
    
    public var body: some View {
        NavigationView {
            HostingControllerRepresentable(hostingController: router.hostingController)
        }
    }
}

@available(iOS 13, macOS 10.15, *)
public struct SwiftUIMasterDetailRouterView<Master: View>: View {
    let makeMaster: () -> Master
    @State var router: SwiftUIRouter
    
    public init(router: SwiftUIRouter, @ViewBuilder makeMaster: @escaping () -> Master) {
        self._router = State(wrappedValue: router)
        self.makeMaster = makeMaster
    }
    
    public var body: some View {
        NavigationView {
            makeMaster()
                .environmentObject(VoidObservableObject())
                .environment(\.router, router)
            
            HostingControllerRepresentable(hostingController: router.hostingController)
        }
    }
}
#endif
