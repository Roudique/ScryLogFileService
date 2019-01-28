import XCTest
import Files
import ScryLogHTMLParser
@testable import ScryLogFileService

final class ScryLogFileServiceTests: XCTestCase {
    private var folder: Folder!
    
    // MARK: - XCTestCase
    
    override func setUp() {
        super.setUp()
        folder = try! Folder.home.createSubfolderIfNeeded(withName: ".scrylogFileTest")
        try! folder.empty()
    }
    
    override func tearDown() {
        try? folder.delete()
        super.tearDown()
    }
    
    // MARK: - Convenience
    
    func makeTable(title: String = "testTable") -> Table {
        return Table(title: title, rows: [["00", "01"], ["10", "11"], ["20", "21"]])
    }
    
    func makeService() -> FileService {
        return FileService(startDirectoryPath: folder.path)!
    }
    
    // MARK: - Tests
    
    func testInit() {
        let service = FileService(startDirectoryPath: folder.path)
        
        XCTAssert(service != nil)
    }

    static var allTests = [
        ("testExample", testInit),
    ]
}
