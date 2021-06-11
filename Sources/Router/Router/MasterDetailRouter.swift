import SwiftUI

@available(iOS 13, macOS 10.15, *)
public struct MasterDetailRouter<MasterView: View, DetailRouter: Router, DetailView: View>: View {
    let masterView: MasterView
    @State var detailRouter: DetailRouter
    let makeDetailView: (DetailRouter) -> DetailView
    
    public init(masterView: MasterView, detailRouter: DetailRouter, @ViewBuilder makeDetailView: @escaping (DetailRouter) -> DetailView) {
        self.masterView = masterView
        self._detailRouter = State(wrappedValue: detailRouter)
        self.makeDetailView = makeDetailView
    }
    
    public var body: some View {
        #if os(macOS)
        HSplitView {
            masterView
                .environment(\.router, detailRouter)
                .environmentObject(VoidObservableObject())
            
            makeDetailView(detailRouter)
        }
        #else
        HStack(spacing: 0) {
            masterView
                .environment(\.router, detailRouter)
                .environmentObject(VoidObservableObject())
            
            Divider()
            
            makeDetailView(detailRouter)
        }
        #endif
    }
}

