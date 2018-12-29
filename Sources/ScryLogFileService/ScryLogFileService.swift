import Files
import Foundation
import ScryLogHTMLParser

class FileService {
    private let startFolder: Folder
    
    // MARK: - Public
    
    init?(startDirectoryPath: String) {
        guard let folder = try? Folder(path: startDirectoryPath) else { return nil }
        self.startFolder = folder
    }
}
