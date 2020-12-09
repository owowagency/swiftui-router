@available(*, deprecated, message: "TODO")
func unimplemented(function: StaticString = #function) -> Never {
    fatalError("\(function) is pending implementation")
}
