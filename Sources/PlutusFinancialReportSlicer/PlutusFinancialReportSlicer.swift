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
        try parseCurrencyDataWithDetails(input: input).currencyData
    }

    public static func parseCurrencyDataWithDetails(input: String) throws -> CurrencyDataParseResult {
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
            throw ParsingError.PreliminaryMonthFile
        }

        if firstRow.count != 13 || (headerRow.count != 12 && headerRow.count != 13) {
            throw ParsingError.InvalidColumnCount
        }

        // column indices differ if report has a "Balance" column
        // if the report contains earnings that haven't surpassed the origin country's payout threshold, line 3 has a "Balance" column which makes for shifted column indices
        let columnIndexAmountPreTax = 3 + (headerRow.count == 13 ? 1 : 0)
        let columnIndexAdjustments = 5 + (headerRow.count == 13 ? 1 : 0)
        let columnIndexAmountAfterTax = 7 + (headerRow.count == 13 ? 1 : 0)
        let columnIndexEarnings = 9 + (headerRow.count == 13 ? 1 : 0)
        let columnIndexBankAccountCurrency = 10 + (headerRow.count == 13 ? 1 : 0)

        var firstSectionSeparatorIndex: Int?
        for index in lines.indices.dropFirst(3) {
            let line = lines[index]
            // abort processing at the first blank line: separated by a line with empty fields, reports can contain earnings
            // which haven't surpassed the payout threshold and therefore need to be ignored
            if line.first?.isEmpty ?? true {
                firstSectionSeparatorIndex = index
                break
            }

            // extract currency symbol from parentheses
            guard let currencyCol: String = line[safe: 0] else {
                continue
            }
            guard let currency = mappedCurrencyKey(from: currencyCol) else {
                throw ParsingError.LineNoCurrencySymbol
            }

            guard let preTaxRaw = line[safe: columnIndexAmountPreTax],
                  let adjustmentsRaw = line[safe: columnIndexAdjustments],
                  let afterTaxRaw = line[safe: columnIndexAmountAfterTax],
                  let earningsRaw = line[safe: columnIndexEarnings],
                  let bankAccountCurrency = line[safe: columnIndexBankAccountCurrency]?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                throw ParsingError.FailedParsingValue("line \(index + 1), \(currency): missing one or more numeric columns")
            }

            let parsedAmountPreTax = parseNumber(preTaxRaw)
            let parsedAdjustments = parseNumber(adjustmentsRaw)
            let parsedAmountAfterTax = parseNumber(afterTaxRaw)
            let parsedEarnings = parseNumber(earningsRaw)
            guard let amountPreTax = parsedAmountPreTax,
                  let adjustments = parsedAdjustments,
                  let amountAfterTax = parsedAmountAfterTax,
                  let earnings = parsedEarnings else {
                var invalidFields: [String] = []
                if parsedAmountPreTax == nil { invalidFields.append("pre-tax='\(preTaxRaw)'") }
                if parsedAdjustments == nil { invalidFields.append("adjustments='\(adjustmentsRaw)'") }
                if parsedAmountAfterTax == nil { invalidFields.append("total-owed='\(afterTaxRaw)'") }
                if parsedEarnings == nil { invalidFields.append("earnings='\(earningsRaw)'") }
                let details = invalidFields.joined(separator: ", ")
                throw ParsingError.FailedParsingValue("line \(index + 1), \(currency): invalid number format for \(details)")
            }

            // If the report has no payout for this currency, avoid division by zero.
            // Keep a zero exchange rate so totals in local currency are zero.
            if amountAfterTax == 0 {
                result.append(CurrencyData(currency: currency, exchangeRate: 0, taxFactor: 1, adjustments: adjustments, bankAccountCurrency: bankAccountCurrency))
                continue
            }

            // There are very rare cases in which tax is withheld for a country seemingly without corresponding product sales within
            // the same period. As we can't handle these in a clean way because of the missing product context, just issue a warning:
            // https://github.com/fedoco/apple-slicer/issues/9
            if amountPreTax == 0 && amountAfterTax - adjustments != 0 {
                print("WARNING:")
                print("Taxes without directly associated product sales have been withheld by Apple for " + currencyCol)
                print("Please deduct \(currency) \(amountAfterTax) (which is \(earnings)) manually for that country")
                continue
            }

            // calculate the exchange rate explicitly instead of relying on the "Exchange Rate" column
            // because its value is rounded to 6 decimal places and sometimes not precise enough
            let exchangeRate = earnings / amountAfterTax

            let tax: Double = amountPreTax - (amountAfterTax - adjustments)
            let taxFactor = 1.0 - abs(tax / amountPreTax)

            result.append(CurrencyData(currency: currency, exchangeRate: exchangeRate, taxFactor: taxFactor, adjustments: adjustments, bankAccountCurrency: bankAccountCurrency))
        }

        let finalizedCurrencies = Set(result.map(\.currency))
        let estimatedOnlyCurrencies = parseEstimatedOnlyCurrencies(
            lines: lines,
            startingAfter: firstSectionSeparatorIndex
        ).subtracting(finalizedCurrencies).sorted()

        return CurrencyDataParseResult(currencyData: result, estimatedOnlyCurrencies: estimatedOnlyCurrencies)
    }

    public static func parseFinancialReports(report: String) throws -> (sales: [SalesForCountry], dateRange: DateInterval) {
        var sales: [String: [ProductSale]] = [:]
        var currencies: [String: String] = [:]
        var dateRange: DateInterval?

        let parsedCSV = parseCSV(input: report, delimiter: "\t")
        guard !parsedCSV.isEmpty else { throw ParsingError.NoDataInFile }

        for (index, line) in parsedCSV.enumerated() {
            // skip lines that don't start with a date
            guard let startDate = line[safe: 0],
                  let endDate = line[safe: 1],
                  startDate.contains("/") else {
                continue
            }

            // consider first occurrence the authoritative date range and assume it is the same for all reports
            if dateRange == nil {
                guard let start = formatDate(startDate), let end = formatDate(endDate) else {
                    throw ParsingError.FailedParsingValue("line \(index + 1): invalid date range start='\(startDate)' end='\(endDate)' (expected MM/DD/YYYY)")
                }
                dateRange = DateInterval(start: start, end: end)
            } else {
                let start = formatDate(startDate)
                let end = formatDate(endDate)
                assert(start == dateRange?.start)
                assert(end == dateRange?.end)
            }

            // all fields of interest of the current line
            guard let quantityString = line[safe: 5],
                  let amountString = line[safe: 7],
                  let currency = line[safe: 8],
                  let product = line[safe: 12],
                  let countryCode = line[safe: 17] else {
                throw ParsingError.InvalidColumnCount
            }
            guard let quantity = Int(quantityString),
                  let amount = parseNumber(amountString) else {
                throw ParsingError.FailedParsingValue("line \(index + 1): quantity='\(quantityString)', amount='\(amountString)' could not be parsed")
            }

            // TODO: improve this
            // add current line's product quantity and amount to dictionary
            var products: [ProductSale] = sales[countryCode, default: []]
            let quantityAndAmount: ProductSale = products.first(where: { $0.product == product }) ?? .init(product: product, quantity: 0, amount: 0)
            products = products.filter({ $0.product != product }) + [
                ProductSale(
                    product: product,
                    quantity: quantityAndAmount.quantity + quantity,
                    amount: quantityAndAmount.amount + amount
                ),
            ]
            sales[countryCode] = products

            // remember currency of current line's country
            currencies[countryCode] = currency

            if let start = formatDate(startDate), start >= Date.subsidiaryChange2024 {
                // special case affecting countries Apple put in the "South Asia and Pacific" group: currency for those is listed as "USD"
                // in the sales reports but the corresponding exchange rate is keyed "USD - AP"
                if Subsidiary.pacificCountries.contains(countryCode) && currency == "USD" {
                    currencies[countryCode] = "USD - AP"
                }
            }
            // special case affecting countries Apple put in the "Rest of World" group: currency for those is listed as "USD"
            // in the sales reports but the corresponding exchange rate is keyed "USD - RoW"
            if Subsidiary.restOfWorldCountries.contains(countryCode) && currency == "USD" {
                currencies[countryCode] = "USD - RoW"
            }
            // special case affecting countries Apple put in the "Latin America and the Caribbean" group: currency for those is listed as "USD"
            // in the sales reports but the corresponding exchange rate is keyed "USD - LatAm"
            if Subsidiary.latinAmericaCaribbeanCountries.contains(countryCode) && currency == "USD" {
                currencies[countryCode] = "USD - LatAm"
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
    public static func splitSalesByCorporation(sales: [SalesForCountry], dateRange: DateInterval, currencyData: [CurrencyData], estimatedOnlyCurrencies: Set<String> = [], selectedCorporations: [Subsidiary] = Subsidiary.allCases, localCurrency: String? = nil) throws -> [Invoice] {
        let localCurrency: String = localCurrency ?? currencyData.map(\.bankAccountCurrency).reduce(into: [:], { $0[$1, default: 0] += 1 }).max(by: { $0.value < $1.value })?.key ?? "EUR"
        let currencyDataByCurrency = currencyData.reduce(into: [String: CurrencyData](), { $0[$1.currency] = $1 })
        var invoices: [Invoice] = []

        guard dateRange.start >= Date.subsidiaryChange2024 || dateRange.end <= Date.subsidiaryChange2024 else {
            throw ParsingError.DateRangeOverlappingBreakingChangeDate(interval: dateRange)
        }

        let corporations: [Subsidiary?: [SalesForCountry]] = Dictionary(grouping: sales, by: { Subsidiary(code: $0.countryCode, date: dateRange.start) })

        for (corporation, salesInCorp) in corporations {
            guard let corporation else { continue }
            if !selectedCorporations.contains(corporation) { continue }

            var countrySplitting: [Invoice.SubInvoice] = []
            var skippedEntries: [Invoice.SkippedEntry] = []

            for salesForCountry in salesInCorp {
                var countrySum: Double = 0
                let countryCurrency = salesForCountry.currency
                let productsSold = salesForCountry.sales

                let countryCode = salesForCountry.countryCode

                var exchangeRate: Double = 1
                var taxFactor: Double = 1

                if countryCurrency != localCurrency {
                    if let data = currencyDataByCurrency[countryCurrency] {
                        exchangeRate = data.exchangeRate
                        taxFactor = data.taxFactor
                    } else if productsSold.contains(where: { $0.quantity != 0 || $0.amount != 0 }) {
                        guard estimatedOnlyCurrencies.contains(countryCurrency) else {
                            throw ParsingError.CurrencyDataNotFound(currency: countryCurrency)
                        }

                        skippedEntries.append(Invoice.SkippedEntry(
                            country: (try? countryName(for: countryCode)) ?? countryCode,
                            countryCode: countryCode,
                            countryCurrency: countryCurrency,
                            quantity: productsSold.reduce(0, { $0 + $1.quantity }),
                            amount: productsSold.reduce(0, { $0 + $1.amount })
                        ))
                        continue
                    }
                }

                let country = try countryName(for: countryCode)

                var invoiceItems: [Invoice.InvoiceItem] = []
                for product in productsSold {
                    let quantity = product.quantity
                    var amount = product.amount

                    // subtract local tax(es) if applicable in country (f. ex. in JPY)
                    amount -= amount - amount * taxFactor

                    countrySum += amount

                    // because of rounding errors, the per product amount can only serve as an informative estimate and is thus displayed with 4 fractional
                    // digits in order to convey that probably some rounding took place
                    let amountInLocalCurrency = amount * exchangeRate

                    invoiceItems.append(Invoice.InvoiceItem(quantity: quantity, product: product.product, amount: amount, exchangeRate: exchangeRate, amountInLocalCurrency: amountInLocalCurrency, dateRange: dateRange))
                }

                countrySplitting.append(Invoice.SubInvoice(country: country, countryCode: countryCode, countryCurrency: countryCurrency, invoiceItems: invoiceItems))
            }

            let currenciesInCorporation = Set(salesInCorp.map(\.currency))
            let currencyAdjustments = currenciesInCorporation.sorted().compactMap({ currency -> Invoice.CurrencyAdjustment? in
                guard let data = currencyDataByCurrency[currency],
                      data.adjustments != 0 else {
                    return nil
                }
                let amountInLocalCurrency = data.adjustments * data.exchangeRate
                return Invoice.CurrencyAdjustment(
                    currency: currency,
                    amount: data.adjustments,
                    exchangeRate: data.exchangeRate,
                    amountInLocalCurrency: amountInLocalCurrency
                )
            })

            // Skip subsidiaries that have neither invoice rows nor reportable skips.
            if countrySplitting.isEmpty && currencyAdjustments.isEmpty && skippedEntries.isEmpty {
                continue
            }

            invoices.append(Invoice(
                recipient: corporation,
                countrySplitting: countrySplitting,
                localCurrency: localCurrency,
                currencyAdjustments: currencyAdjustments,
                skippedEntries: skippedEntries
            ))
        }

        return invoices
    }

    private static func mappedCurrencyKey(from currencyColumn: String) -> String? {
        let currencySymbolReference = Reference(Substring.self)
        let currencyReg = Regex {
            "("

            Capture(as: currencySymbolReference) {
                Repeat(count: 3, { One(.word) })
            }

            ")"

            Anchor.endOfLine
        }

        guard let regexMatch = currencyColumn.firstMatch(of: currencyReg) else {
            return nil
        }
        var currency = String(regexMatch[currencySymbolReference])

        // USD can occur three times in the file: We must take special care to distinguish between USD (and their corresponding
        // exchange rate) for purchases made in "Americas", in "Rest of World", and in "Latin America and the Caribbean". Unfortunately, Apple
        // decided to localize the aforementioned strings so they need to be looked up in a translation table. Luckily,
        // localized report files currently seem to be generated only for French, German, Italian and Spanish locale settings.
        if currency == "USD" {
            let localizationsRoW = ["of World", "du monde", "der Welt", "del mondo", "del mundo"]
            for localization in localizationsRoW {
                if currencyColumn.lowercased().contains(localization.lowercased()) {
                    currency = "USD - RoW"
                    break
                }
            }

            let localizationsLatAm = ["latin", "latein"]
            for localization in localizationsLatAm {
                if currencyColumn.lowercased().contains(localization.lowercased()) {
                    currency = "USD - LatAm"
                    break
                }
            }

            let localizationsAP = ["Pacif", "Pacíf", "Pazif"]
            for localization in localizationsAP {
                if currencyColumn.lowercased().contains(localization.lowercased()) {
                    currency = "USD - AP"
                    break
                }
            }
        }

        return currency
    }

    private static func parseEstimatedOnlyCurrencies(lines: [[String]], startingAfter separatorIndex: Int?) -> Set<String> {
        guard let separatorIndex else {
            return []
        }

        var estimatedCurrencies: Set<String> = []
        let remainingLines = lines.dropFirst(separatorIndex + 1)
        for line in remainingLines {
            guard let currencyColumn = line[safe: 0],
                  !currencyColumn.isEmpty,
                  let currency = mappedCurrencyKey(from: currencyColumn) else {
                continue
            }
            estimatedCurrencies.insert(currency)
        }

        return estimatedCurrencies
    }

    private static func formatDate(_ dateStr: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter.date(from: dateStr)
    }

    private static func parseNumber(_ raw: String) -> Double? {
        var normalized = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: " ", with: "")

        if normalized.contains(",") && normalized.contains(".") {
            normalized = normalized.replacingOccurrences(of: ",", with: "")
        } else if normalized.contains(",") {
            normalized = normalized.replacingOccurrences(of: ",", with: ".")
        }

        return Double(normalized)
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
