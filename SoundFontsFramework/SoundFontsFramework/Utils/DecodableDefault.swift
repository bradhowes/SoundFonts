// Copyright © 2020 Brad Howes. All rights reserved.
// Based on code from https://www.swiftbysundell.com/tips/default-decoding-values/

/// A type that can provide a default value.
protocol DecodableDefaultSource {
  associatedtype ValueType: Decodable
  static var defaultValue: ValueType { get }
}

/// A container for a wrapper around a DecodableDefaultSource
enum DecodableDefault {
  @propertyWrapper
  struct Wrapper<Source: DecodableDefaultSource> {
    typealias DefaultSource = Source
    typealias ValueType = Source.ValueType
    var wrappedValue = Source.defaultValue
  }
}

extension DecodableDefault.Wrapper: Decodable {

  /**
   Constructor for a new DecodableDefaultSource wrapper that takes a value from the given decoder.

   - parameter decoder: provider of values
   */
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    wrappedValue = try container.decode(ValueType.self)
  }
}

extension DecodableDefault.Wrapper: Encodable where ValueType: Encodable {

  /**
   Encode the wrapped value in the given encoder.

   - parameter encoder: the container for the wrapped value
   */
  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(wrappedValue)
  }
}

extension DecodableDefault.Wrapper: Equatable where ValueType: Equatable {}
extension DecodableDefault.Wrapper: Hashable where ValueType: Hashable {}

extension KeyedDecodingContainer {

  /**
   Attempt to extract a value from a container. If it fails, just return a wrapped default value of the right type.

   - parameter type: the type to decode
   - parameter key: the key to use in the container
   */
  func decode<T>(_ type: DecodableDefault.Wrapper<T>.Type, forKey key: Key) throws
  -> DecodableDefault.Wrapper<T>
  {
    try decodeIfPresent(type, forKey: key) ?? .init()
  }
}

extension DecodableDefault {

  typealias Source = DecodableDefaultSource
  typealias List = Decodable & ExpressibleByArrayLiteral
  typealias Map = Decodable & ExpressibleByDictionaryLiteral

  enum Sources {
    enum True: Source { public static var defaultValue: Bool { true } }
    enum False: Source { public static var defaultValue: Bool { false } }
    enum Zero<T>: Source where T: ExpressibleByFloatLiteral & Decodable {
      static var defaultValue: T { 0.0 }
    }
    enum EmptyString: Source { public static var defaultValue: String { "" } }
    enum EmptyList<T: List>: Source { public static var defaultValue: T { [] } }
    enum EmptyMap<T: Map>: Source { public static var defaultValue: T { [:] } }
    enum EmptyTagSet: Source { public static var defaultValue: Set<Tag.Key> { Set() } }
    enum Value<T: Source>: Source { public static var defaultValue: T.ValueType { T.defaultValue } }
  }
}

extension DecodableDefault {
  typealias True = Wrapper<Sources.True>
  typealias False = Wrapper<Sources.False>
  typealias Zero<T> = Wrapper<Sources.Zero<T>> where T: ExpressibleByFloatLiteral & Decodable
  typealias EmptyString = Wrapper<Sources.EmptyString>
  typealias EmptyList<T> = Wrapper<Sources.EmptyList<T>> where T: List
  typealias EmptyMap<T> = Wrapper<Sources.EmptyMap<T>> where T: Map
  typealias EmptyTagSet = Wrapper<Sources.EmptyTagSet>
  typealias Value<T: DecodableDefaultSource> = Wrapper<Sources.Value<T>>
}

struct DefaultValue: DecodableDefaultSource {
  static var defaultValue = 123
}

final public class Foo: Codable {
  let one: Int
  @DecodableDefault.True var isVisible: Bool
  @DecodableDefault.Value<DefaultValue> var two: Int
}
