# 🚀 SwiftUI Router

A SwiftUI package that provides routing functionality. Great for building (MVVM) SwiftUI apps where navigation is decoupled from the UI and view models. 

## 🚲 Usage

### 🔀 Basic routing

`Route` is a protocol. The package provides one basic implementation, `SimpleRoute`, which works for simple use cases.

Define your routes by extending the `Routes` type. The most basic route looks like this:

```swift
extension Routes {
  static let hello = SimpleRoute { Text("Hello! 👋") }
}
```

To navigate to this route, you can use a `RouterLink` in any SwiftUI view contained in a `Router`:

```swift
RouterLink(to: Routes.hello) {
  Text("Some link")
}
```

### 🔭 Routes and state

A common SwiftUI pattern is to bind an `ObservableObject` to your view to serve as the view model. For example, you could have a view model like this:

```swift
class EditNameViewModel: ObservableObject {
  @Published var name: String
  
  init(name: String = "") {
    self.name = name
  }
}
```

And a view like this:

```swift
struct EditNameView: View {
  @ObservedObject var viewModel: EditNameViewModel
  
  var body: some View {
      TextField("Name", text: $viewModel.name)
  }
}
```

SwiftUI Router provides a mechanism to initialise your view state. Using `SimpleRoute`, it looks like this:

```swift
extension Routes {
  static let editName = SimpleRoute(prepareState: { EditNameViewModel() }) { viewModel in
    EditNameView(viewModel: viewModel)
  }
}
```

The `prepareState` closure runs once when navigating to the route. Afterwards, the return value is used to render the view.

### Parameterized and custom routes

Some routes might need parameters to show correctly. To accept parameters, you can implement a custom route type. Let's expand on the name editing example above – say you want to pass a default name as route argument.

A custom route implementation might look like this:

```swift
struct EditNameRoute: IndependentRoute {
  var name: String
      
  func prepareState() -> EditNameViewModel {
    EditNameViewModel(name: emailAddress)
  }
      
  func body(state: EditNameViewModel) -> some View {
    EditNameView(viewModel: state)
  }
}
```

Afterwards, you can add it as extension to your `Routes`:

```swift
extension Routes {
  static func editName(name: String) -> EditNameRoute {
    EditNameRoute(name: name)
  }
}
```

*Note that `IndependentRoute` is a specialized version of `Route` that doesn't depend on an environment object to prepare it's state.*

### Routers

Before you are able to use your defined routes, you need to initialise a router. Because `Router` is a protocol, multiple implementations (including your own) are possible. SwiftUI Router provides the `UINavigationControllerRouter` implementation.

## Principles

- A route defines how to perform set-up of the state (if needed) for a given view, and how the view is a product of that state 
- Navigation should be possible both programmatically (e.g. `router.navigate(...)`) and user-initiated (e.g. `RouterLink(to: ...)`)
- The presentation of a route is decoupled 
