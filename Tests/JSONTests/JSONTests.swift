import Foundation
import XCTest
@testable import JSON
import Core
import Node

@discardableResult
func perf(_ block: () throws -> Void) rethrows -> Double {
    let start = Date()
    try block()
    let end = Date()
    let time = end.timeIntervalSince(start)
    return time
}

class CompareTests: XCTestCase {
    static let allTests = [
        ("testJayPerformance", testJayPerformance),
        ("testFoundationPerformance", testFoundationPerformance),
    ]

    let rawFile: Bytes = {
        let mockJSON = #file.components(separatedBy: "JSONTests")[0] + "JSONTests/MOCK_DATA.json"
        let rawFile = try! DataFile.load(path: mockJSON)
        return rawFile
    }()

    func testJayPerformance() throws {
        var structure: StructuredData = .object([:])
        let time = try perf {
            let json = try JSON(bytes: rawFile)
            structure = json.wrapped
        }
        print("First: \(structure.array!.first!)")
        print("It took Jay \(time) seconds")
    }

    func testFoundationPerformance() throws {
        var structure: StructuredData = .object([:])
        let time = try perf {
            let data = Data(bytes: rawFile)
            let blob = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            structure = StructuredData(any: blob)
        }
        print("First: \(structure.array!.first!)")
        print("It took Foundation \(time) seconds")
    }
}

class JSONTests: XCTestCase {
    static let allTests = [
        ("testParse", testParse),
        ("testSerialize", testSerialize),
        ("testSerializePerformance", testSerializePerformance),
        ("testParsePerformance", testParsePerformance),
    ]

    func testParse() throws {
        let string = "{\"double\":3.14159265358979,\"object\":{\"nested\":\"text\"},\"array\":[true,1337,\"😄\"],\"int\":42,\"bool\":false,\"string\":\"ferret 🚀\"}"
        let json = try JSON(bytes: string)

        XCTAssertEqual(json["bool"]?.bool, false)
        XCTAssertEqual(json["string"]?.string, "ferret 🚀")
        XCTAssertEqual(json["int"]?.int, 42)
        XCTAssertEqual(json["double"]?.double, 3.14159265358979)
        XCTAssertEqual(json["object", "nested"]?.string, "text")
        XCTAssertEqual(json["array", 0]?.bool, true)
        XCTAssertEqual(json["array", 1]?.int, 1337)
        XCTAssertEqual(json["array", 2]?.string, "😄")
    }

    func testSerialize() throws {
        let json = try JSON(node: [
            "null": nil,
            "bool": false,
            "string": "ferret 🚀",
            "int": 42,
            "double": 3.14159265358979,
            "object": JSON(node: [
                "nested": "text"
            ]),
            "array": JSON(node: [nil, true, 1337, "😄"])
        ])

        let serialized = try json.makeBytes().string
        XCTAssert(serialized.contains("\"bool\":false"))
        XCTAssert(serialized.contains("\"string\":\"ferret 🚀\""))
        XCTAssert(serialized.contains("\"int\":42"))
        XCTAssert(serialized.contains("\"double\":3.14159265358979"))
        XCTAssert(serialized.contains("\"object\":{\"nested\":\"text\"}"))
        XCTAssert(serialized.contains("\"array\":[null,true,1337,\"😄\"]"))
    }

    func testPrettySerialize() throws {
        let json = try JSON(node: [
            "hello": "world"
        ])

        let serialized = try json.serialize(prettyPrint: true).string
        let expectation = "{\n  \"hello\" : \"world\"\n}"
        XCTAssertEqual(serialized, expectation)
    }

    func testStringEscaping() throws {
        let json = try JSON(node: ["he \r\n l \t l \n o w\"o\rrld "])
        let data = try json.serialize().string
        XCTAssertEqual(data, "[\"he \\r\\n l \\t l \\n o w\\\"o\\rrld \"]")
    }

    var hugeParsed: JSON!
    var hugeSerialized: Bytes!

    override func setUp() {
        var huge: [String: Node] = [:]
        for i in 0 ... 100_000 {
            huge["double_\(i)"] = 3.14159265358979
        }

        hugeParsed = try! JSON(node: huge)
        hugeSerialized = try! hugeParsed.makeBytes()
    }

    func testSerializePerformance() throws {
        // debug 0.333
        // release 0.291

        // foundation 0.505 / 0.391
        measure {
            _ = try! self.hugeParsed.makeBytes()
        }
    }

    func testParsePerformance() throws {
        // debug 0.885
        // release 0.127

        // foundation 1.060 / 0.777
        measure {
            _ = try! JSON(bytes: self.hugeSerialized)
        }
    }

}
