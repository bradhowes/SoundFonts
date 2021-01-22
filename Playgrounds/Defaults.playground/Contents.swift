import Foundation

protocol DefaultSource {
    associatedtype Value: Decodable
    static var defaultValue: Value { get }
}

@propertyWrapper
struct DefaultDecodable<T: DefaultSource> {
    typealias WrappedType = T.Value
    var wrappedValue: WrappedType
}

extension DefaultDecodable: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode(WrappedType.self)
    }
}

extension DefaultDecodable: Encodable where WrappedType: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

extension DefaultDecodable: Equatable where WrappedType: Equatable {}
extension DefaultDecodable: Hashable where WrappedType: Hashable {}

extension KeyedDecodingContainer {
    func decode<T>(_ type: DefaultDecodable<T>.Type, forKey key: Key) throws -> DefaultDecodable<T> {
        try decodeIfPresent(type, forKey: key) ?? .init(wrappedValue: T.defaultValue)
    }
}

extension DefaultDecodable {
    enum Sources {
        enum Constant<T: DefaultSource>: DefaultSource { static var defaultValue = T.defaultValue }
    }
}

extension DefaultDecodable {
    typealias Constant<T: DefaultSource> = DefaultDecodable<Sources.Constant<T>>
}

struct DefaultValue: DefaultSource {
    static var defaultValue = 123
}

struct Foo: Codable, Equatable {
    let one: Int
    @DefaultDecodable.Constant<DefaultValue> var two: Int
}

let jsonData = #"{ "one": null }"#.data(using: .utf8)!
let foo = try JSONDecoder().decode(Foo.self, from: jsonData)
print(foo)
