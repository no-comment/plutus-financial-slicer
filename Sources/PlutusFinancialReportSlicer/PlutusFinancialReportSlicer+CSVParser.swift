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

public enum ParsingError: Error {
    case PreliminaryMonthFile
    case InvalidColumnCount
    case NoDataInFile
    case LineNoCurrencySymbol
    case FailedParsingValue
    case CurrencyDataNotFound(currency: String)
    /// Apple changed its subsidiary structure on October 26, 2024. Sales must occur either before or after that date.
    case DateRangeOverlappingBreakingChangeDate(interval: DateInterval)
}

extension ParsingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .PreliminaryMonthFile:
            NSLocalizedString("The file contained preliminary data.", comment: "Localized description for ParsingError.PreliminaryMonthFile")
        case .InvalidColumnCount:
            NSLocalizedString("The file has an invalid number of columns.", comment: "Localized description for ParsingError.InvalidColumnCount")
        case .NoDataInFile:
            NSLocalizedString("There was not data in the file.", comment: "Localized description for ParsingError.NoDataInFile")
        case .LineNoCurrencySymbol:
            NSLocalizedString("No currency symbol found in line.", comment: "Localized description for ParsingError.LineNoCurrencySymbol")
        case .FailedParsingValue:
            NSLocalizedString("Failed parsing the report.", comment: "Localized description for ParsingError.FailedParsingValue")
        case .CurrencyDataNotFound(let currency):
            NSLocalizedString("No currency data was found for '\(currency)'.", comment: "Localized description for ParsingError.CurrencyDataNotFound")
        case .DateRangeOverlappingBreakingChangeDate(let interval):
            NSLocalizedString("The date range (\(interval.debugDescription) overlaps subsidiary structure change date.", comment: "Localized description for ParsingError.DateRangeOverlappingBreakingChangeDate")
        }
    }
}
