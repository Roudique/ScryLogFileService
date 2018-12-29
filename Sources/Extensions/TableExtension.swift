//
//  TableExtension.swift
//  ScryLogFileService
//
//  Created by Roudique on 12/28/18.
//

import Foundation
import CSV
import ScryLogHTMLParser

extension Table {
    func toData() -> Data? {
        let stream = OutputStream(toMemory: ())
        let csv = try! CSVWriter(stream: stream)
        
        // Write data to file row by row.
        for row in self.rows {
            csv.beginNewRow()
            
            for field in row {
                try! csv.write(field: field, quoted: true)
            }
        }
        
        csv.stream.close()
        
        guard let data = stream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data else {
            return nil
        }
        
        return data
    }
}
