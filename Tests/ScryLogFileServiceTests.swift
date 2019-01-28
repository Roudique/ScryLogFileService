import XCTest
import Files
import ScryLogHTMLParser
@testable import ScryLogFileService

final class ScryLogFileServiceTests: XCTestCase {
    private var folder: Folder!
    private var service: FileService!
    
    // MARK: - XCTestCase
    
    override func setUp() {
        super.setUp()
        folder = try! Folder.home.createSubfolderIfNeeded(withName: ".scrylogFileTest")
        try! folder.empty()
        service = FileService(startDirectoryPath: folder.path)
    }
    
    override func tearDown() {
        try? folder.delete()
        super.tearDown()
    }
    
    // MARK: - Convenience
    
    func makeTable(title: String = "testTable") -> Table {
        return Table(title: title, rows: [["00", "01"], ["10", "11"], ["20", "21"]])
    }
    
    func makeEntity(title: String = "testEntity") -> Entity {
        let table1 = makeTable(title: "testTable01")
        let table2 = makeTable(title: "testTable02")
        
        return Entity(title: title, tables: [table1, table2])
    }
    
    func makeVersion(number: Int = 0) -> Version {
        let entity1 = makeEntity(title: "testEntity01")
        let entity2 = makeEntity(title: "testEntity02")
        
        return Version(number: number, entities: [entity1, entity2])
    }
    
    // MARK: - Tests
    
    func testInit() {
        XCTAssert(service != nil)
        XCTAssert(folder.containsSubfolder(named: "versions"))
    }
    
    func testAddVersion() {
        let versionNumber = 0
        let version = makeVersion(number: versionNumber)
        
        service.add(version: version)
        
        let versionsFolder = try! folder.subfolder(named: "versions")
        let version0Folder = try! versionsFolder.subfolder(named: String(versionNumber))
        
        for entity in version.entities {
            let entityFolder = try! version0Folder.subfolder(named: entity.title)
            
            for table in entity.tables {
                let containsFile = entityFolder.containsFile(named: table.title + ".csv")
                XCTAssert(containsFile)
            }
        }
    }

    static var allTests = [
        ("testExample", testInit),
    ]
}
