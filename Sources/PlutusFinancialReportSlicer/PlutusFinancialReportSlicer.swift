import Foundation
import RegexBuilder

public enum PlutusFinancialReportSlicer {
    public static func parseCurrencyDataMonth(input: String) -> String? {
        let lines: [[String]] = parseCSV(input: input)
        guard let firstCell = lines.first?.first else { return nil }

        let dateRef = Reference(Substring.self)
        let regularExp = Regex {
            "("
            Capture(as: dateRef) {
                OneOrMore(.any)
            }

            ")"
        }

        guard let match = firstCell.firstMatch(of: regularExp) else { return nil }
        return String(match[dateRef])
    }

    public static func parseCurrencyData(input: String) throws -> [CurrencyData] {
        let lines: [[String]] = parseCSV(input: input)
        var result: [CurrencyData] = []

        guard lines.count > 4 else {
            throw ParsingError.NoDataInFile
        }

        guard let firstRow = lines.first,
              let headerRow = lines[safe: 2] else {
            throw ParsingError.NoDataInFile
        }

        // check valid file
        if firstRow.count == 10 {
            throw ParsingError.PendingMonthFile
        }

        if firstRow.count != 13 || (headerRow.count != 12 && headerRow.count != 13) {
            throw ParsingError.InvalidColumnCount
        }

        // column indices differ if report has a "Balance" column
        // if the report contains earnings that haven't surpassed the origin country's payout threshold, line 3 has a "Balance" column which makes for shifted column indices
        let columnIndexAmountPreTax = 3 + (headerRow.count == 13 ? 1 : 0)
        let columnIndexAmountAfterTax = 7 + (headerRow.count == 13 ? 1 : 0)
        let columnIndexEarnings = 9 + (headerRow.count == 13 ? 1 : 0)

        for line in lines.dropFirst(3) {
            // abort processing at the first blank line: separated by a line with empty fields, reports can contain earnings
            // which haven't surpassed the payout threshold and therefore need to be ignored
            if line.first?.isEmpty ?? true {
                break
            }
            // print(line)

            // extract currency symbol from parentheses
            guard let currencyCol: String = line[safe: 0] else {
                continue
            }

            let currencySymbolReference = Reference(Substring.self)
            let currencyReg = Regex {
                "("

                Capture(as: currencySymbolReference) {
                    Repeat(count: 3, { One(.word) })
                }

                ")"

                Anchor.endOfLine
            }

            guard let regexMatch = currencyCol.firstMatch(of: currencyReg) else {
                throw ParsingError.LineNoCurrencySymbol
            }
            var currency = String(regexMatch[currencySymbolReference])

            // USD can occur twice in the file: We must take special care to distinguish between USD (and their corresponding
            // exchange rate) for purchases made in "Americas" and in "Rest of World", as Apple calls it. Unfortunately, Apple
            // decided to localize the aforementioned strings so they need to be looked up in a translation table. Luckily,
            // localized report files currently seem to be generated only for French, German, Italian and Spanish locale settings.
            let localizationsRoW = ["of World", "du monde", "der Welt", "del mondo", "del mundo"]
            if currency == "USD" {
                for localization in localizationsRoW {
                    if currencyCol.lowercased().contains(localization.lowercased()) {
                        currency = "USD - RoW"
                    }
                }
            }

            guard let preTaxString = line[safe: columnIndexAmountPreTax]?.replacingOccurrences(of: ",", with: ""),
                  let afterTaxString = line[safe: columnIndexAmountAfterTax]?.replacingOccurrences(of: ",", with: ""),
                  let earningsString = line[safe: columnIndexEarnings]?.replacingOccurrences(of: ",", with: ""),

                  let amountPreTax = Double(preTaxString),
                  let amountAfterTax = Double(afterTaxString),
                  let earnings = Double(earningsString) else {
                throw ParsingError.FailedParsingValue
            }

            // There are very rare cases in which tax is withheld for a country seemingly without corresponding product sales within
            // the same period. As we can't handle these in a clean way because of the missing product context, just issue a warning:
            // https://github.com/fedoco/apple-slicer/issues/9
            if amountPreTax == 0 && amountAfterTax != 0 {
                print("WARNING:")
                print("Taxes without directly associated product sales have been withheld by Apple for " + currencyCol)
                print("Please deduct \(currency) \(amountAfterTax) (which is \(earnings)) manually for that country")
                continue
            }

            // calculate the exchange rate explicitly instead of relying on the "Exchange Rate“ column
            // because its value is rounded to 6 decimal places and sometimes not precise enough
            let exchangeRate = earnings / amountAfterTax

            let tax: Double = amountPreTax - amountAfterTax
            let taxFactor = 1.0 - abs(tax / amountPreTax)

            result.append(CurrencyData(currency: currency, exchangeRate: exchangeRate, taxFactor: taxFactor))
        }

        return result
    }

    public static func parseFinancialReports(report: String) throws -> (sales: [SalesForCountry], dateRange: DateInterval) {
        var sales: [String: [ProductSale]] = [:]
        var currencies: [String: String] = [:]
        var dateRange: DateInterval?

        let parsedCSV = parseCSV(input: report, delimiter: "\t")
        guard !parsedCSV.isEmpty else { throw ParsingError.NoDataInFile }

        for line in parsedCSV {
            // skip lines that don't start with a date
            guard let startDate = line[safe: 0],
                  let endDate = line[safe: 1],
                  startDate.contains("/") else {
                continue
            }

            // consider first occurrence the authoritative date range and assume it is the same for all reports
            if dateRange == nil {
                guard let start = formatDate(startDate), let end = formatDate(endDate) else {
                    throw ParsingError.FailedParsingValue
                }
                dateRange = DateInterval(start: start, end: end)
            } else {
                let start = formatDate(startDate)
                let end = formatDate(endDate)
                assert(start == dateRange?.start)
                assert(end == dateRange?.end)
            }

            // all fields of interest of the current line
            let quantity: Int? = if let quantityString = line[safe: 5] { Int(quantityString) } else { nil as Int? }
            let amount: Double? = if let amountString = line[safe: 7] { Double(amountString) } else { nil as Double? }
            guard let quantity,
                  let amount,
                  let currency = line[safe: 8],
                  let product = line[safe: 12],
                  let countryCode = line[safe: 17] else {
                throw ParsingError.InvalidColumnCount
            }

            // TODO: improve this
            // add current line's product quantity and amount to dictionary
            var products: [ProductSale] = sales[countryCode, default: []]
            let quantityAndAmount: ProductSale = products.first(where: { $0.product == product }) ?? .init(product: product, quantity: 0, amount: 0)
            products = products.filter({ $0.product != product }) + [
                ProductSale(
                    product: product,
                    quantity: quantityAndAmount.quantity + quantity,
                    amount: quantityAndAmount.amount + amount),
            ]
            sales[countryCode] = products

            // remember currency of current line's country
            currencies[countryCode] = currency

            // special case affecting countries Apple put in the "Rest of World" group: currency for those is listed as "USD"
            // in the sales reports but the corresponding exchange rate is keyed "USD - RoW"
            if Subsidiary.restOfWorldCountries.contains(countryCode) && currency == "USD" {
                currencies[countryCode] = "USD - RoW"
            }
        }

        // break if we didn't read any meaningful data
        if sales.isEmpty {
            throw ParsingError.NoDataInFile
        }

        guard let dateRange else { throw ParsingError.NoDataInFile }

        return (sales: sales.map({ (countryCode: String, value: [ProductSale]) in
            SalesForCountry(countryCode: countryCode, currency: currencies[countryCode] ?? "", sales: value)
        }), dateRange: dateRange)
    }

    /// Print sales grouped by Apple subsidiaries, by countries in which the sales have been made and by products sold.
    public static func splitSalesByCorporation(sales: [SalesForCountry], dateRange: DateInterval, currencyData: [CurrencyData], selectedCorporations: [Subsidiary] = Subsidiary.allCases, localCurrency: String = "EUR") throws -> [Invoice] {
        var invoices: [Invoice] = []

        let corporations: [Subsidiary?: [SalesForCountry]] = Dictionary(grouping: sales, by: { Subsidiary(code: $0.countryCode) })

        for (corporation, salesInCorp) in corporations {
            guard let corporation else { continue }
            if !selectedCorporations.contains(corporation) { continue }

            var countrySplitting: [Invoice.SubInvoice] = []

            for salesForCountry in salesInCorp {
                var countrySum: Double = 0
                let countryCurrency = salesForCountry.currency
                let productsSold = salesForCountry.sales

                let country = try countryName(for: salesForCountry.countryCode)
                let countryCode = salesForCountry.countryCode

                var exchangeRate: Double = 1
                var taxFactor: Double = 1

                // TODO: throw if currency not found in currencyData
                if countryCurrency != localCurrency {
                    if let data = currencyData.first(where: { $0.currency == countryCurrency }) {
                        exchangeRate = data.exchangeRate
                        taxFactor = data.taxFactor
                    } else if productsSold.contains(where: { $0.quantity > 0 }) {
                        fatalError("\(countryCurrency) not found in currency data")
                    }
                }

                var invoiceItems: [Invoice.InvoiceItem] = []
                for product in productsSold {
                    let quantity = product.quantity
                    var amount = product.amount

                    // subtract local tax(es) if applicable in country (f. ex. in JPY)
                    // TODO: check if -= is correct
                    amount -= amount - amount * taxFactor

                    countrySum += amount

                    // because of rounding errors, the per product amount can only serve as an informative estimate and is thus displayed with 4 fractional
                    // digits in order to convey that probably some rounding took place
                    let amountInLocalCurrency = amount * exchangeRate

                    invoiceItems.append(Invoice.InvoiceItem(quantity: quantity, product: product.product, amount: amount, exchangeRate: exchangeRate, amountInLocalCurrency: amountInLocalCurrency, dateRange: dateRange))
                }

                // although of course rounding happens here, too, it won't show because Apple converts currencies in the same per country manner
                let countrySumInLocalCurrency = countrySum * exchangeRate

                countrySplitting.append(Invoice.SubInvoice(country: country, countryCode: countryCode, countryCurrency: countryCurrency, invoiceItems: invoiceItems))
            }

            invoices.append(Invoice(
                recipient: corporation,
                countrySplitting: countrySplitting))
        }

        return invoices
    }

    private static func formatDate(_ dateStr: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter.date(from: dateStr)
    }
}

public struct Invoice: Equatable, Codable, Hashable {
    public let recipient: Subsidiary
    public let countrySplitting: [SubInvoice]
    public var totalInLocalCurrency: Double { countrySplitting.reduce(0, { $0 + $1.subtotalAmountInLocalCurrency }) }

    public init(recipient: Subsidiary, countrySplitting: [SubInvoice]) {
        self.recipient = recipient
        self.countrySplitting = countrySplitting
    }

    public struct SubInvoice: Equatable, Hashable, Codable {
        public let country: String
        public let countryCode: String
        public let countryCurrency: String
        public let invoiceItems: [InvoiceItem]

        public var subtotalAmount: Double { invoiceItems.reduce(0, { $0 + $1.amount }) }
        public var subtotalAmountInLocalCurrency: Double { invoiceItems.reduce(0, { $0 + $1.amountInLocalCurrency }) }

        public init(country: String, countryCode: String, countryCurrency: String, invoiceItems: [InvoiceItem]) {
            self.country = country
            self.countryCode = countryCode
            self.countryCurrency = countryCurrency
            self.invoiceItems = invoiceItems
        }
    }

    public struct InvoiceItem: Equatable, Hashable, Codable {
        public let quantity: Int
        public let product: String

        public let amount: Double
        public let exchangeRate: Double
        public let amountInLocalCurrency: Double

        public let dateRange: DateInterval

        public init(quantity: Int, product: String, amount: Double, exchangeRate: Double, amountInLocalCurrency: Double, dateRange: DateInterval) {
            self.quantity = quantity
            self.product = product
            self.amount = amount
            self.exchangeRate = exchangeRate
            self.amountInLocalCurrency = amountInLocalCurrency
            self.dateRange = dateRange
        }
    }
}

public struct SalesForCountry: Codable {
    let countryCode: String
    let currency: String
    let sales: [ProductSale]
}

public struct ProductSale: Equatable, Hashable, Codable {
    var product: String
    var quantity: Int
    var amount: Double
}

public struct CurrencyData: Codable, Equatable {
    let currency: String
    let exchangeRate: Double
    let taxFactor: Double
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

public enum ParsingError: Error {
    case PendingMonthFile
    case InvalidColumnCount
    case NoDataInFile
    case LineNoCurrencySymbol
    case FailedParsingValue
}
