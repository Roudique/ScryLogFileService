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
    
    func testSimpleTableSaving() {
        let table = makeTable()
        let service = makeService()
        
        service.saveCSV(table: table, fileName: table.title)
        let file = try? folder.file(named: table.title + ".csv")
        
        XCTAssert(file != nil)
    }
    
    func testTableSaveQuitsWithFileOverwriteIfFileExists() {
        let table = makeTable()
        let service = makeService()
        
        XCTAssert(service.saveCSV(table: table, fileName: table.title) == true)
        XCTAssert(service.saveCSV(table: table, fileName: table.title, folders: nil, overwrite: false) == false)
    }
    
    func testTableSaveOverwrites() {
        let table1 = Table(title: "00", rows: [["00"]])
        let table2 = Table(title: "01", rows: [["00", "01"], ["02", "03"]])
        let fileTitle = "testTitle"
        let service = makeService()

        XCTAssert(service.saveCSV(table: table1, fileName: fileTitle) == true)
        
        let table1BytesLength = try! folder.file(named: fileTitle + ".csv").read().count
        
        XCTAssert(service.saveCSV(table: table2, fileName: fileTitle, folders: nil, overwrite: true) == true)
        
        let table2BytesLength = try! folder.file(named: fileTitle + ".csv").read().count
        
        XCTAssert(table1BytesLength != table2BytesLength)
    }
    
    func testTableSavingWithFolders() {
        let table = makeTable()
        let service = makeService()
        let folders = ["home", "video"]
        
        service.saveCSV(table: table, fileName: table.title, folders: folders, overwrite: false)
        
        var testFolder = try! Folder(path: folder.path)
        folders.forEach { testFolder = try! testFolder.subfolder(named: $0) }
        
        let file = try? testFolder.file(named: table.title + ".csv")
        
        XCTAssert(file != nil)
    }
    
    func testGetTables() {
        let tables = [makeTable(title: "test00"),
                      makeTable(title: "test01"),
                      makeTable(title: "test02")]
        let service = makeService()
        let folders = ["home"]
        
        tables.forEach { table in
            service.saveCSV(table: table, fileName: table.title, folders: folders, overwrite: false)
        }
        
        let returnedTables = service.getTables(from: folders)
        
        XCTAssert(returnedTables != nil)
        XCTAssert(returnedTables!.count == tables.count)
    }
    
    func testGetFolderNames() {
        let service = makeService()
        let folderName = "home"
        var folderNames = [String]()
        (0..<10).forEach { folderNames.append("test\($0)") }
        
        let testFolder = try! folder.createSubfolder(named: folderName)
        folderNames.forEach { try! testFolder.createSubfolder(named: $0) }
        
        let testFolders = service.getFolderNames(at: [folderName])!
        XCTAssert(testFolders == folderNames)
    }
    
    static var allTests = [
        ("testExample", testInit),
        ("testSimpleTableSaving", testSimpleTableSaving),
        ("testTableSaveQuitsWithFileOverwriteIfFileExists", testTableSaveQuitsWithFileOverwriteIfFileExists),
        ("testTableSaveOverwrites", testTableSaveOverwrites),
        ("testTableSavingWithFolders", testTableSavingWithFolders),
        ("testGetTables", testGetTables),
        ("testGetFolderNames", testGetFolderNames),
    ]
}
