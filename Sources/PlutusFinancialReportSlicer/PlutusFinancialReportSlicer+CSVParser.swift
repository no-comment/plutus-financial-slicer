//
//  File.swift
//
//
//  Created by Miká Kruschel on 08.03.24.
//

import Foundation

extension PlutusFinancialReportSlicer {
    static func parseCSV(input: String, delimiter: Character = ",") -> [[String]] {
        return input.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines).map({ splitRow(line: $0, delimiter: delimiter) })
    }
    
    private static func splitRow(line: String, delimiter: Character) -> [String] {
        var data: [String] = []
        var inQuote = false
        var currentString = ""
        
        for character in line {
            switch character {
            case "\"":
                inQuote.toggle()
                continue
                
            case delimiter:
                if !inQuote {
                    data.append(currentString)
                    currentString = ""
                    continue
                }
                
            default:
                break
            }
            
            currentString.append(character)
        }
        
        data.append(currentString)
        
        return data
    }
}
