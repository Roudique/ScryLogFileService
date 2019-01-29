import Files
import Foundation
import ScryLogHTMLParser
import CSV

private enum FolderNames: String {
    case versions
    
    var string: String { return rawValue }
}

public class FileService {
    private let startFolder: Folder
    private let versionsFolder: Folder
    
    /// Versions that are currently presented by service.
    private(set) public var versions: Set<Version> = {
        return Set<Version>()
    }()
    
    // MARK: - Public
    
    public init?(startDirectoryPath: String) {
        guard let folder = try? Folder(path: startDirectoryPath) else { return nil }
        self.startFolder = folder
        
        guard let versionsFolder = try? folder.createSubfolderIfNeeded(withName: FolderNames.versions.string) else {
            return nil
        }
        
        self.versionsFolder = versionsFolder
        
        let versionsFolders =  self.versionsFolder.subfolders
        if versionsFolders.count == 0 { return }
        
        guard let versions = versions(from: Array(versionsFolders)) else { return nil }
        self.versions = versions
    }
}

// MARK: - Public

public extension FileService {
    /// Add version to the service. If version with same number exists, it will be overwritten.
    /// Immediately persists all data inside the version on the disk.
    ///
    /// - Parameter version: Version to insert.
    /// - Returns: Success of the operation.
    @discardableResult
    func add(version: Version) -> Bool {
        var shouldErase = false
        
        // Write each table file to disk.
        for entity in version.entities {
            for table in entity.tables {
                let folders = [FolderNames.versions.string, String(version.number), entity.title]
                let success = write(table: table, folders: folders, overwrite: true)
                if !success {
                    shouldErase = true
                    break
                }
            }
        }
        
        // Rollback logic.
        if shouldErase {
            guard let versionFolder = try? versionsFolder.subfolder(named: String(version.number)) else { return false }
            try? versionFolder.delete()
            return false
        }
        
        self.versions.insert(version)
        return true
    }
    
    /// Add entity to specified version. If entity with same name exists, it will be overwritten.
    /// Immediately persists all data.
    ///
    /// - Parameters:
    ///   - entity: Entity to insert.
    ///   - versionNumber: Inserts entity to version with specified number or fails if such version doesn't exists.
    /// - Returns: Success of the operation.
    @discardableResult
    func add(entity: Entity, toVersionNumber versionNumber: Int) -> Bool {
        guard let version = version(with: versionNumber) else { return false }
        
        // Write all the tables to appropriate folders and check if it's successful to rollback if needed.
        var shouldErase = false
        for table in entity.tables {
            let success = write(table: table,
                                folders: [FolderNames.versions.string, String(version.number), entity.title],
                                overwrite: true)
            if !success {
                shouldErase = true
                break
            }
        }
        
        // Rollback logic.
        if shouldErase {
            guard let versionFolder = try? versionsFolder.subfolder(named: String(versionNumber)) else { return false }
            guard let entityFolder = try? versionFolder.subfolder(named: entity.title) else { return false }
            try? entityFolder.delete()
            return false
        }
        
        version.entities.insert(entity)
        
        return true
    }
    
    /// Add table to specified entity of version with specified number.
    /// Immediately persists the table. If table with same name exists it will be overwritten.
    ///
    /// - Parameters:
    ///   - table: Table to insert.
    ///   - versionNumber: Version number to which table will be inserted.
    ///   - entityTitle: Title of entity to which table will be inserted. If it doesn't exists then operation fails.
    /// - Returns: Success of the operation.
    @discardableResult
    func add(table: Table, toVersionNumber versionNumber: Int, toEntityTitle entityTitle: String) -> Bool {
        guard let version = version(with: versionNumber) else { return false }
        
        var entityToModify: Entity?
        
        for entity in version.entities where entity.title == entityTitle {
            entityToModify = entity
            break
        }
        
        guard let entity = entityToModify else { return false }
        
        let success = write(table: table,
                            folders: [FolderNames.versions.string, String(versionNumber), entityTitle],
                            overwrite: true)
        
        guard success else { return false }
        
        entity.tables.append(table)
        
        return true
    }
    
    /// Removes specified version from cached versions and erase it from disk.
    ///
    /// - Parameter version: Version to remove and erase.
    /// - Returns: Success of the operation.
    @discardableResult
    func remove(version: Version) -> Bool {
        if !versions.contains(version) { return false }
        
        guard let versionFolder = try? versionsFolder.subfolder(named: String(version.number)) else { return false }
        do {
            try versionFolder.delete()
        } catch {
            return false
        }
        
        versions.remove(version)
        
        return true
    }

    /// Removes specified entity from cached entities and from the disk.
    ///
    /// - Parameters:
    ///   - entity: Entity to remove and erase.
    ///   - versionNumber: Version number of version that holds the entity.
    /// - Returns: Success of the operation.
    @discardableResult
    func remove(entity: Entity, fromVersionNumber versionNumber: Int) -> Bool {
        guard let correctVersion = version(with: versionNumber) else { return false }
        guard correctVersion.entities.contains(entity) else { return false }
        
        guard let versionFolder = try? versionsFolder.subfolder(named: String(versionNumber)) else { return false }
        guard let entityFolder = try? versionFolder.subfolder(named: entity.title) else { return false }
        
        do {
            try entityFolder.delete()
        } catch {
            return false
        }
        
        correctVersion.entities.remove(entity)
        
        return true
    }
    
    /// Removes specified table from cached tables and from the disk.
    ///
    /// - Parameters:
    ///   - table: Table to remove and erase.
    ///   - versionNumber: Version number that holds the entity which holds the table.
    ///   - entityTitle: Title of the entity which holds the table.
    /// - Returns: Success of the operation.
    @discardableResult
    func remove(table: Table, fromVersionNumber versionNumber: Int, fromEntityWithTitle entityTitle: String) -> Bool {
        guard let correctVersion = version(with: versionNumber) else { return false }
        let entity = correctVersion.entities.first { $0.title == entityTitle }
        guard let correctEntity = entity else { return false }
        
        var storedTable: Table?
        
        for tab in correctEntity.tables where tab.title == table.title {
            storedTable = tab
        }
        
        guard storedTable === table else { return false }
        let tableIndex = correctEntity.tables.firstIndex { $0 === table }
        guard let correctTableIndex = tableIndex else { return false }
        
        guard let versionFolder = try? versionsFolder.subfolder(named: String(versionNumber)) else { return false }
        guard let entityFolder = try? versionFolder.subfolder(named: entityTitle) else { return false }
        guard let tableFile = try? entityFolder.file(named: table.title + ".csv") else { return false }
        
        do {
            try tableFile.delete()
        } catch {
            return false
        }
        
        correctEntity.tables.remove(at: correctTableIndex)
        
        return true
    }
}

// MARK: - Initialization helpers

private extension FileService {
    func versions(from folders: [Folder]) -> Set<Version>? {
        var versions = Set<Version>()
        
        guard folders.count > 0 else { return versions }
        
        for folder in folders {
            let folderName          = folder.name
            guard let versionNumber = Int(folderName) else { continue }
            
            let entitiesFolders     = folder.subfolders
            guard let entities      = entities(from: Array(entitiesFolders)) else { continue }
            
            let version             = Version(number: versionNumber, entities: entities)
            versions.insert(version)
        }
        
        return versions
    }
    
    func entities(from folders: [Folder]) -> [Entity]? {
        var entities = [Entity]()
        
        for folder in folders {
            let entityName = folder.name
            guard let tables = tables(from: folder) else { continue }
            
            let entity = Entity(title: entityName, tables: tables)
            entities.append(entity)
        }
        
        return entities
    }
    
    func tables(from folder: Folder) -> [Table]? {
        var tables = [Table]()
        folder.files.forEach { file in
            guard file.extension == "csv" else { return }
            guard let data = try? file.read() else { return }
            guard let rows = FileService.readRowsFromData(data: data) else { return }
            tables.append(Table(title: file.nameExcludingExtension, rows: rows))
        }
        
        return tables
    }
}

// MARK: - Helpers

private extension FileService {
    func version(with number: Int) -> Version? {
        for version in versions where version.number == number {
            return version
        }
        
        return nil
    }
}

// MARK: - File handling

private extension FileService {
    @discardableResult
    func write(table: Table, folders: [String]? = nil, overwrite: Bool = false) -> Bool {
        guard var folder = try? Folder(path: self.startFolder.path) else { return false }
        
        if let folders = folders {
            for folderName in folders {
                guard let subfolder = try? folder.createSubfolderIfNeeded(withName: folderName) else { return false}
                folder = subfolder
            }
        }
        
        let filename = table.title.replacingOccurrences(of: " ", with: "_") + ".csv"
        
        // If overwrite is not set to true but file exists already - simply quit.
        if !overwrite, folder.containsFile(named: filename) { return false }
        
        guard let file = try? folder.createFile(named: filename) else { return false }
        
        guard let tableData = table.toData() else { return false }
        
        do {
            try file.write(data: tableData)
            return true
        } catch {
            print("Failed to write table csv to \(file.path). Error: \(error)")
            return false
        }
    }

    private static func readRowsFromData(data: Data) -> [Row]? {
        let stream = InputStream.init(data: data)
        return self.readRowsFromStream(inputStream: stream)
    }
    
    private static func readRowsFromFile(fileURL: URL) -> [Row]? {
        guard let stream = InputStream.init(url: fileURL) else { return nil }
        return self.readRowsFromStream(inputStream: stream)
    }
    
    private static func readRowsFromStream(inputStream: InputStream) -> [Row]? {
        var rows = [Row]()
        
        do {
            let reader = try CSVReader.init(stream: inputStream)
            while let line = reader.next() {
                var row = [String]()
                
                for field in line {
                    row.append(field)
                }
                rows.append(row)
            }
            
        } catch {
            return nil
        }
        
        return rows
    }

}
