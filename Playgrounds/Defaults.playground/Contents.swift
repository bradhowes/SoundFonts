import Foundation

struct Bar: Codable {
    let one: Int
    let two: String
}

struct Foo: Codable {
    var one: Int
    var two: String
    var bar: Bar?
}

let a = Foo(one: 1, two: "2", bar: nil)
a

let b = Foo(one: 2, two: "4", bar: Bar(one: 2, two: "4"))
b


