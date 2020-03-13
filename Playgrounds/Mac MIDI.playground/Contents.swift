import PlaygroundSupport

enum Tag: String {
    case one
    case two
}

enum Payload {
    case one(view: String, completionHandler: (Bool) -> Void)
    var tag: String {
        switch self {
        case .one: return "one"
        }
    }
}

let z = Payload.one(view: "mom", completionHandler: { did in } )

