import XCTest
import Files
import ScryLogHTMLParser
@testable import ScryLogFileService

final class ScryLogFileServiceTests: XCTestCase {
    private var folder: Folder!
    private var versionsFolder: Folder! {
        return try! folder.subfolder(named: "versions")
    }
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
        
        let versionsFolder = self.versionsFolder!
        let version0Folder = try! versionsFolder.subfolder(named: String(versionNumber))
        
        for entity in version.entities {
            let entityFolder = try! version0Folder.subfolder(named: entity.title)
            
            for table in entity.tables {
                let containsFile = entityFolder.containsFile(named: table.title + ".csv")
                XCTAssert(containsFile)
            }
        }
        
        XCTAssert(service.versions.contains(version))
    }
    
    func testAddEntity() {
        let entityName = "testEntity"
        let entity = makeEntity(title: entityName)
        
        service.add(entity: entity, toVersionNumber: 0)
        
        XCTAssert(service.versions.count == 0)
        let versionsFolder = self.versionsFolder!
        XCTAssert(versionsFolder.subfolders.count == 0)
        
        let versionNumber = 0
        let version = makeVersion(number: versionNumber)
        
        service.add(version: version)
        XCTAssert(versionsFolder.containsSubfolder(named: String(versionNumber)))
        
        service.add(entity: entity, toVersionNumber: versionNumber)
        let version0Folder = try! versionsFolder.subfolder(named: String(versionNumber))
        
        let entityFolder = try! version0Folder.subfolder(named: entityName)
        for table in entity.tables {
            XCTAssert(entityFolder.containsFile(named: table.title + ".csv"))
        }
    }
    
    func testRemoveVersion() {
        let version = makeVersion()
        XCTAssert(service.add(version: version))
        XCTAssert(versionsFolder.containsSubfolder(named: String(version.number)))
        
        service.remove(version: version)
        
        XCTAssert(!versionsFolder.containsSubfolder(named: String(version.number)))
    }
    
    func testRemoveEntity() {
        let version = makeVersion()
        let entity = version.entities.first!
        
        service.add(version: version)
        
        let versionFolder = try! versionsFolder.subfolder(named: String(version.number))
        XCTAssert(versionFolder.containsSubfolder(named: entity.title))
        
        service.remove(entity: entity, fromVersionNumber: version.number)
        
        XCTAssert(!versionFolder.containsSubfolder(named: entity.title))
    }
    
    func testRemoveTable() {
        let version = makeVersion()
        let entity = version.entities.first!
        let table = entity.tables.first!
        
        service.add(version: version)
        
        let versionFolder = try! versionsFolder.subfolder(named: String(version.number))
        let entityFolder = try! versionFolder.subfolder(named: entity.title)
        XCTAssert(entityFolder.containsFile(named: table.title + ".csv"))
        
        service.remove(table: table, fromVersionNumber: version.number, fromEntityWithTitle: entity.title)
        
        XCTAssert(!entityFolder.containsFile(named: table.title + ".csv"))
    }

    static var allTests = [
        ("testExample", testInit),
        ("testAddVersion", testAddVersion),
        ("testAddEntity", testAddEntity),
    ]
}
