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
    
    public var versions: Set<Version> = {
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
    
    @discardableResult
    func add(entity: Entity, to versionNumber: Int) -> Bool {
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
    
    @discardableResult
    func add(table: Table, to versionNumber: Int, to entityName: String) -> Bool {
        guard let version = version(with: versionNumber) else { return false }
        
        var entityToModify: Entity?
        
        for entity in version.entities where entity.title == entityName {
            entityToModify = entity
            break
        }
        
        guard let entity = entityToModify else { return false }
        
        let success = write(table: table,
                            folders: [FolderNames.versions.string, String(versionNumber), entityName],
                            overwrite: true)
        
        guard success else { return false }
        
        entity.tables.append(table)
        
        return true
    }
    
    func remove(version: Version) {
        
    }

    func remove(entity: Entity, from version: Version) {
        
    }
    
    func remove(table: Table, from entity: Entity) {
        
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
        var versionToReturn: Version?
        
        for version in versions where version.number == number {
            versionToReturn = version
            break
        }
        
        return versionToReturn
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

    /*
    /// Saves table as csv to specified location.
    ///
    /// - Parameters:
    ///   - table: Table to save.
    ///   - fileName: Filename of the table. Extension will be `.csv`.
    ///   - folders: Path of folders.
    ///   - overwrite: If table at given path exists, it will not be overwritten by default.
    /// - Returns: Success of the operation or false if something failed.
    @discardableResult
    public func save(table: Table, fileName: String, folders: [String]? = nil, overwrite: Bool = false) -> Bool {
        guard var folder = try? Folder(path: self.startFolder.path) else { return false }
        
        if let folders = folders {
            for folderName in folders {
                guard let subfolder = try? folder.createSubfolderIfNeeded(withName: folderName) else { return false}
                folder = subfolder
            }
        }
        
        let validatedFileName = fileName.replacingOccurrences(of: " ", with: "_") + ".csv"
        
        // If overwrite is not set to true but file exists already - simply quit.
        if !overwrite, folder.containsFile(named: validatedFileName) { return false }
        
        guard let file = try? folder.createFile(named: validatedFileName) else { return false }
        
        print("\tFinal filepath for file with name `\(validatedFileName)` is \(file.path)")
        guard let tableData = table.toData() else { return false }
        
        do {
            try file.write(data: tableData)
            return true
        } catch {
            print("Failed to write table csv to \(file.path). Error: \(error)")
            return false
        }
    }
    
    /// Returns all tables in specified folder.
    /// E.g. if you pass `["home", "video"]` array as `folders` argument, this method will return all tables at path
    /// `$ROOT_FOLDER/home/video`
    ///
    /// - Parameter folders: Path to the folder with tables.
    /// - Returns: Nil if there was an error opening specified folder or an array of tables (may be empty as well).
    public func getTables(from folders: [String]) -> [Table]? {
        guard var folder = try? Folder(path: self.startFolder.path) else { return nil }
        
        for folderName in folders {
            guard let subfolder = try? folder.subfolder(named: folderName) else { return nil }
            folder = subfolder
        }
        
        var tables = [Table]()
        folder.files.forEach { file in
            guard file.extension == "csv" else { return }
            guard let data = try? file.read() else { return }
            guard let rows = FileService.readRowsFromData(data: data) else { return }
            tables.append(Table(title: file.nameExcludingExtension, rows: rows))
        }
        
        return tables
    }
    
    /// Returns all subfolders' names for given path.
    ///
    /// - Parameter folders: Path to the folder.
    /// - Returns: Nil if there was an error opening specified folder or an array of folder names (may be empty).
    public func getFolderNames(at folders: [String] = [String]()) -> [String]? {
        guard var folder = try? Folder(path: self.startFolder.path) else { return nil }
        
        for folderName in folders {
            guard let subfolder = try? folder.subfolder(named: folderName) else { return nil }
            folder = subfolder
        }
        
        var folderNames = [String]()
        folder.subfolders.forEach { folderNames.append($0.name) }

        return folderNames
    }
    

}
*/
