import Foundation

/// The lifecycle of one asynchronously loaded value, rendered by every screen.
enum Loadable<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(any Error)

    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var error: (any Error)? {
        if case .failed(let error) = self { return error }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}
