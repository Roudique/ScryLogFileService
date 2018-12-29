import Files
import Foundation
import ScryLogHTMLParser
import CSV

class FileService {
    private let startFolder: Folder
    
    // MARK: - Public
    
    init?(startDirectoryPath: String) {
        guard let folder = try? Folder(path: startDirectoryPath) else { return nil }
        self.startFolder = folder
    }
    
    @discardableResult
    func saveCSV(table: Table, fileName: String, folders: [String]? = nil, overwrite: Bool = false) -> Bool {
        guard var folder = try? Folder(path: self.startFolder.path) else { return false }
        
        if let folders = folders {
            for folderName in folders {
                guard let subfolder = try? folder.createSubfolderIfNeeded(withName: folderName) else { return false}
                folder = subfolder
            }
        }
        
        let validatedFileName = fileName.replacingOccurrences(of: " ", with: "_") + ".csv"
        guard let file = try? folder.createFileIfNeeded(withName: validatedFileName) else { return false }
        
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
