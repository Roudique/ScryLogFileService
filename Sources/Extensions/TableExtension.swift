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
        guard let csv = try? CSVWriter(stream: stream) else { return nil }
        
        // Write data to file row by row.
        for row in self.rows {
            csv.beginNewRow()
            
            for field in row {
                do {
                    try csv.write(field: field, quoted: true)
                } catch {
                    return nil
                }
            }
        }
        
        csv.stream.close()
        
        guard let data = stream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data else {
            return nil
        }
        
        return data
    }
}
