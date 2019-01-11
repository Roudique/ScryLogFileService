import Files
import Foundation
import ScryLogHTMLParser
import CSV

class FileService {
    private let startFolder: Folder
    
    // MARK: - Public
    
    public init?(startDirectoryPath: String) {
        guard let folder = try? Folder(path: startDirectoryPath) else { return nil }
        self.startFolder = folder
    }
    
    /// Saves table as csv to specified location.
    ///
    /// - Parameters:
    ///   - table: Table to save.
    ///   - fileName: Filename of the table. Extension will be `.csv`.
    ///   - folders: Path of folders.
    ///   - overwrite: If table at given path exists, it will not be overwritten by default.
    /// - Returns: Success of the operation or false if something failed.
    @discardableResult
    public func saveCSV(table: Table, fileName: String, folders: [String]? = nil, overwrite: Bool = false) -> Bool {
        guard var folder = try? Folder(path: self.startFolder.path) else { return false }
        
        if let folders = folders {
            for folderName in folders {
                guard let subfolder = try? folder.createSubfolderIfNeeded(withName: folderName) else { return false}
                folder = subfolder
            }
        }
        
        let validatedFileName = fileName.replacingOccurrences(of: " ", with: "_") + ".csv"
        if !overwrite, let _ = try? File(path: folder.file(named: validatedFileName).path) { return false }
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
    
    
    // MARK: - Private
    
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
