@testable import PlutusFinancialReportSlicer
import XCTest

final class PlutusFinancialReportSlicerTests: XCTestCase {
    func testFinancialReportCSVParser() throws {
        let input = try readFile(url: Bundle.module.url(forResource: "financial_report", withExtension: "csv")!)
        let csv = PlutusFinancialReportSlicer.parseCSV(input: input)
        // check that csv parsing is same as in python
        XCTAssertEqual(csv, [
            ["iTunes Connect - Payments and Financial Reports\t(September, 2014)", "", "", "", "", "", "", "", "", "", "", "", ""],
            ["", "", "", "", "", "", "", "", "", "", "", "", ""],
            ["Region (Currency)", "Units Sold", "Earned", "Pre-Tax Subtotal", "Input Tax", "Adjustments", "Withholding Tax", "Total Owed", "Exchange Rate", "Proceeds", "Bank Account Currency", ""],
            ["Switzerland (CHF)", "29", "33.15", "33.15", "0", "0", "0", "33.15", "0.80030", "26.53", "EUR", ""],
            ["Euro-Zone (EUR)", "19", "206.89", "206.89", "0", "0", "0", "206.89", "1.00000", "206.89", "EUR", ""],
            ["Japan (JPY)", "2", "179", "179", "0", "0", "-37", "142", "0.00817", "1.16", "EUR", ""],
            ["Americas (USD)", "42", "336.78", "336.78", "0", "0", "0", "336.78", "0.91956", "309.69", "EUR", ""],
            ["Latin America and the Caribbean (USD)", "1", "5.09", "5.09", "0", "0", "0", "5.09", "0.91945", "4.68", "EUR", ""],
            ["Rest of World (USD)", "1", "4.95", "4.95", "0", "0", "0", "4.95", "0.91919", "4.55", "EUR", ""],
            ["", "", "", "", "", "", "", "", "", "", "", "", ""],
            ["", "", "", "", "", "", "", "", "", "", "234.58 EUR", "", ""],
            ["", "", "", "", "", "", "", "", "", "", "Paid to FICTIONAL BANK -****1299", "", ""],
            ["", "", "", "", "", "", "", "", "", "", "", "", ""],
            ["", "", "", "", "", "", "", "", "", "", "", "", ""],
        ])
    }

    func testCurrencyDataMonthString() throws {
        let input = try readFile(url: Bundle.module.url(forResource: "financial_report", withExtension: "csv")!)
        let month = PlutusFinancialReportSlicer.parseCurrencyDataMonth(input: input)
        XCTAssertEqual(month, "September, 2014")
    }

    func testSalesByCorporation() throws {
        let currencyDataInput = try readFile(url: Bundle.module.url(forResource: "financial_report", withExtension: "csv")!)
        let currencyData = try PlutusFinancialReportSlicer.parseCurrencyData(input: currencyDataInput)

        let report: String = try readFile(url: Bundle.module.url(forResource: "45545510_0914", withExtension: "txt")!)
        let financialReportsData = try PlutusFinancialReportSlicer.parseFinancialReports(report: report)

        let dateRange = DateInterval(start: .now.addingTimeInterval(-60 * 60 * 24 * 3), end: .now)

        let splits = try PlutusFinancialReportSlicer.splitSalesByCorporation(sales: financialReportsData.sales, dateRange: dateRange, currencyData: currencyData)

        XCTAssertEqual(splits.count, 4)
        guard splits.count == 4 else { return }

        let jpCorp = splits.first(where: { $0.recipient == .japan })!
        let euCorp = splits.first(where: { $0.recipient == .europe })!

        XCTAssertEqual(jpCorp.totalInLocalCurrency, 1.16, accuracy: 0.000001)
        XCTAssertEqual(euCorp.totalInLocalCurrency, 237.97, accuracy: 0.000001)

        AssertSameCountrySplitting(jpCorp.countrySplitting, [
            Invoice.SubInvoice(country: "Japan", countryCode: "JP", countryCurrency: "JPY", invoiceItems: [
                Invoice.InvoiceItem(quantity: 1, product: "Example App 3", amount: 94.4022346368715, exchangeRate: 0.008169014084507042, amountInLocalCurrency: 0.7711731843575418, dateRange: dateRange),
                Invoice.InvoiceItem(quantity: 1, product: "Example App 4", amount: 47.59776536312849, exchangeRate: 0.008169014084507042, amountInLocalCurrency: 0.3888268156424581, dateRange: dateRange),
            ]),
        ])

        AssertSameCountrySplitting(euCorp.countrySplitting, [
            Invoice.SubInvoice(country: "Finland", countryCode: "FI", countryCurrency: "EUR", invoiceItems: [
                Invoice.InvoiceItem(quantity: 1, product: "Example App 5", amount: 12.17, exchangeRate: 1.0, amountInLocalCurrency: 12.17, dateRange: dateRange),
            ]),
            Invoice.SubInvoice(country: "France", countryCode: "FR", countryCurrency: "EUR", invoiceItems: [
                Invoice.InvoiceItem(quantity: 1, product: "Example App 5", amount: 12.17, exchangeRate: 1.0, amountInLocalCurrency: 12.17, dateRange: dateRange),
            ]),
            Invoice.SubInvoice(country: "Switzerland", countryCode: "CH", countryCurrency: "CHF", invoiceItems: [
                Invoice.InvoiceItem(quantity: 16, product: "Example App 1", amount: 20.8, exchangeRate: 0.8003016591251886, amountInLocalCurrency: 16.646274509803924, dateRange: dateRange),
                Invoice.InvoiceItem(quantity: 5, product: "Example App 2", amount: 3.25, exchangeRate: 0.8003016591251886, amountInLocalCurrency: 2.600980392156863, dateRange: dateRange),
                Invoice.InvoiceItem(quantity: 6, product: "Example App 3", amount: 7.8, exchangeRate: 0.8003016591251886, amountInLocalCurrency: 6.24235294117647, dateRange: dateRange),
                Invoice.InvoiceItem(quantity: 2, product: "Example App 4", amount: 1.3, exchangeRate: 0.8003016591251886, amountInLocalCurrency: 1.0403921568627452, dateRange: dateRange),
            ]),
            Invoice.SubInvoice(country: "Germany", countryCode: "DE", countryCurrency: "EUR", invoiceItems: [
                Invoice.InvoiceItem(quantity: 2, product: "Example App 6", amount: 24.34, exchangeRate: 1.0, amountInLocalCurrency: 24.34, dateRange: dateRange),
                Invoice.InvoiceItem(quantity: 15, product: "Example App 5", amount: 158.21, exchangeRate: 1.0, amountInLocalCurrency: 158.21, dateRange: dateRange),
            ]),
            Invoice.SubInvoice(country: "Ukraine", countryCode: "UA", countryCurrency: "USD - RoW", invoiceItems: [
                Invoice.InvoiceItem(quantity: 1, product: "Example App 5", amount: 4.95, exchangeRate: 0.9191919191919191, amountInLocalCurrency: 4.55, dateRange: dateRange),
            ]),
        ])
    }

    func testExampleCurrencyData() throws {
        let input = try readFile(url: Bundle.module.url(forResource: "financial_report", withExtension: "csv")!)
        let currencyData = try PlutusFinancialReportSlicer.parseCurrencyData(input: input)

        for data in currencyData {
            XCTAssertEqual(data.bankAccountCurrency, "EUR")
            switch data.currency {
            case "CHF":
                XCTAssertEqual(data.exchangeRate, 0.8003016591251885369532428356, accuracy: 0.000001)
                XCTAssertEqual(data.taxFactor, 1, accuracy: 0.000001)
                XCTAssertEqual(data.adjustments, 0, accuracy: 0.000001)
            case "EUR":
                XCTAssertEqual(data.exchangeRate, 1, accuracy: 0.000001)
                XCTAssertEqual(data.taxFactor, 1, accuracy: 0.000001)
                XCTAssertEqual(data.adjustments, 0, accuracy: 0.000001)
            case "JPY":
                XCTAssertEqual(data.exchangeRate, 0.008169014084507042253521126761, accuracy: 0.000001)
                XCTAssertEqual(data.taxFactor, 0.7932960893854748603351955307, accuracy: 0.000001)
                XCTAssertEqual(data.adjustments, 0, accuracy: 0.000001)
            case "USD":
                XCTAssertEqual(data.exchangeRate, 0.9195617316942812, accuracy: 0.000001)
                XCTAssertEqual(data.taxFactor, 1, accuracy: 0.000001)
                XCTAssertEqual(data.adjustments, 0, accuracy: 0.000001)
            case "USD - RoW":
                XCTAssertEqual(data.exchangeRate, 0.9191919191919191, accuracy: 0.000001)
                XCTAssertEqual(data.taxFactor, 1, accuracy: 0.000001)
                XCTAssertEqual(data.adjustments, 0, accuracy: 0.000001)
            case "USD - LatAm":
                XCTAssertEqual(data.exchangeRate, 0.91944990176817287, accuracy: 0.000001)
                XCTAssertEqual(data.taxFactor, 1, accuracy: 0.000001)
                XCTAssertEqual(data.adjustments, 0, accuracy: 0.000001)
            default:
                XCTFail(data.currency)
            }
        }

        XCTAssertEqual(currencyData.count, 6)
    }

    func testCurrencyDataParsesAdjustmentsAndKeepsTaxIndependent() throws {
        let firstRow = "iTunes Connect - Payments and Financial Reports (January 2026)" + String(repeating: ",", count: 12)
        let blankRow = String(repeating: ",", count: 12)
        let input = [
            firstRow,
            blankRow,
            "Region (Currency),Units Sold,Earned,Pre-Tax Subtotal,Input Tax,Adjustments,Withholding Tax,Total Owed,Exchange Rate,Proceeds,Bank Account Currency,",
            "Euro-Zone (EUR),1,100.00,100.00,0,10.00,0,110.00,1.00000,110.00,EUR,",
            "Japan (JPY),1,100.00,100.00,0,0,-20.00,80.00,0.01000,0.80,EUR,",
            blankRow,
        ].joined(separator: "\n")

        let currencyData = try PlutusFinancialReportSlicer.parseCurrencyData(input: input)
        XCTAssertEqual(currencyData.count, 2)

        let eur = try XCTUnwrap(currencyData.first(where: { $0.currency == "EUR" }))
        XCTAssertEqual(eur.adjustments, 10, accuracy: 0.000001)
        XCTAssertEqual(eur.taxFactor, 1, accuracy: 0.000001)

        let jpy = try XCTUnwrap(currencyData.first(where: { $0.currency == "JPY" }))
        XCTAssertEqual(jpy.adjustments, 0, accuracy: 0.000001)
        XCTAssertEqual(jpy.taxFactor, 0.8, accuracy: 0.000001)
    }

    func testSplitSalesByCorporationAppliesAdjustmentsOncePerCurrency() throws {
        let dateRange = DateInterval(start: Date.now.addingTimeInterval(-60 * 60 * 24), end: Date.now)
        let sales: [SalesForCountry] = [
            SalesForCountry(countryCode: "DE", currency: "EUR", sales: [ProductSale(product: "Example App", quantity: 1, amount: 50)]),
            SalesForCountry(countryCode: "FR", currency: "EUR", sales: [ProductSale(product: "Example App", quantity: 1, amount: 50)]),
        ]
        let currencyData: [CurrencyData] = [
            CurrencyData(currency: "EUR", exchangeRate: 1, taxFactor: 1, adjustments: 10, bankAccountCurrency: "EUR"),
        ]

        let invoices = try PlutusFinancialReportSlicer.splitSalesByCorporation(
            sales: sales,
            dateRange: dateRange,
            currencyData: currencyData,
            selectedCorporations: [.europe],
            localCurrency: "EUR"
        )
        XCTAssertEqual(invoices.count, 1)

        let invoice = try XCTUnwrap(invoices.first)
        XCTAssertEqual(invoice.currencyAdjustments.count, 1)
        let adjustment = try XCTUnwrap(invoice.currencyAdjustments.first)
        XCTAssertEqual(adjustment.currency, "EUR")
        XCTAssertEqual(adjustment.amount, 10, accuracy: 0.000001)
        XCTAssertEqual(invoice.totalInLocalCurrency, 110, accuracy: 0.000001)
    }

    func testSplitSalesByCorporationSkipsCountryWithoutFinalizedCurrencyData() throws {
        let dateRange = DateInterval(start: Date.now.addingTimeInterval(-60 * 60 * 24), end: Date.now)
        let sales: [SalesForCountry] = [
            SalesForCountry(countryCode: "DE", currency: "EUR", sales: [ProductSale(product: "Example App", quantity: 1, amount: 50)]),
            SalesForCountry(countryCode: "BG", currency: "BGN", sales: [ProductSale(product: "Example App", quantity: 1, amount: 21.24)]),
        ]
        let currencyData: [CurrencyData] = [
            CurrencyData(currency: "EUR", exchangeRate: 1, taxFactor: 1, adjustments: 0, bankAccountCurrency: "EUR"),
        ]

        let invoices = try PlutusFinancialReportSlicer.splitSalesByCorporation(
            sales: sales,
            dateRange: dateRange,
            currencyData: currencyData,
            estimatedOnlyCurrencies: ["BGN"],
            selectedCorporations: [.europe],
            localCurrency: "EUR"
        )

        XCTAssertEqual(invoices.count, 1)
        let invoice = try XCTUnwrap(invoices.first)
        XCTAssertEqual(invoice.countrySplitting.map(\.countryCode), ["DE"])
        XCTAssertEqual(invoice.totalInLocalCurrency, 50, accuracy: 0.000001)
        XCTAssertEqual(invoice.skippedEntries.count, 1)
        XCTAssertEqual(invoice.skippedEntries.first?.countryCode, "BG")
        XCTAssertEqual(invoice.skippedEntries.first?.countryCurrency, "BGN")
    }

    func testSplitSalesByCorporationThrowsForMissingNonEstimatedCurrencyData() throws {
        let dateRange = DateInterval(start: Date.now.addingTimeInterval(-60 * 60 * 24), end: Date.now)
        let sales: [SalesForCountry] = [
            SalesForCountry(countryCode: "BG", currency: "BGN", sales: [ProductSale(product: "Example App", quantity: 1, amount: 21.24)]),
        ]
        let currencyData: [CurrencyData] = [
            CurrencyData(currency: "EUR", exchangeRate: 1, taxFactor: 1, adjustments: 0, bankAccountCurrency: "EUR"),
        ]

        XCTAssertThrowsError(try PlutusFinancialReportSlicer.splitSalesByCorporation(
            sales: sales,
            dateRange: dateRange,
            currencyData: currencyData,
            estimatedOnlyCurrencies: [],
            selectedCorporations: [.europe],
            localCurrency: "EUR"
        )) { error in
            guard case let ParsingError.CurrencyDataNotFound(currency) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(currency, "BGN")
        }
    }

    func testCurrencyDataHandlesBulgariaStyleAdjustmentWithZeroTotalOwed() throws {
        let firstRow = "iTunes Connect - Payments and Financial Reports (Dummy)" + String(repeating: ",", count: 12)
        let blankRow = String(repeating: ",", count: 12)
        let input = [
            firstRow,
            blankRow,
            "País o región (Divisa),Unidades vendidas,Ingresado,Subtotal antes de impuestos,Impuesto repercutido,Ajustes,Retención fiscal,Total adeudado,Tipo de cambio,Ganancias,Divisa de la cuenta bancaria,",
            "Eurozona (EUR),667,3030.30,3030.30,0,27.15,0,3057.45,1.00000,3057.45,EUR,",
            "Bulgaria (BGN),3,53.10,53.10,0,-53.10,0,0.00,0,0,EUR,",
            blankRow,
        ].joined(separator: "\n")

        let currencyData = try PlutusFinancialReportSlicer.parseCurrencyData(input: input)

        let eur = try XCTUnwrap(currencyData.first(where: { $0.currency == "EUR" }))
        XCTAssertEqual(eur.adjustments, 27.15, accuracy: 0.000001)
        XCTAssertEqual(eur.taxFactor, 1, accuracy: 0.000001)
        XCTAssertEqual(eur.exchangeRate, 1, accuracy: 0.000001)

        let bgn = try XCTUnwrap(currencyData.first(where: { $0.currency == "BGN" }))
        XCTAssertEqual(bgn.adjustments, -53.10, accuracy: 0.000001)
        XCTAssertEqual(bgn.exchangeRate, 0, accuracy: 0.000001)
        XCTAssertEqual(bgn.taxFactor, 1, accuracy: 0.000001)
    }

    func testCurrencyDataParsesCRLFWithBalanceColumn() throws {
        let lines = [
            "\"iTunes Connect - Payments and Financial Reports\t(December, 2025)\",,,,,,,,,,,,",
            ",,,,,,,,,,,,",
            "Country or Region (Currency),Units Sold,Balance,Earned,Pre-Tax Subtotal,Input Tax,Adjustments,Withholding Tax,Total Owed,Exchange Rate,Proceeds,Bank Account Currency,",
            "\"United Arab Emirates (AED)\",\"4\",\"\",\"43.68\",\"43.68\",\"0\",\"0\",\"0\",\"43.68\",\"0.22825\",\"9.97\",\"EUR\",",
            "\"Australia (AUD)\",\"72\",\"\",\"818.08\",\"818.08\",\"0\",\"0\",\"0\",\"818.08\",\"0.58189\",\"476.03\",\"EUR\",",
            ",,,,,,,,,,,,",
        ]
        let input = lines.joined(separator: "\r\n")

        let currencyData = try PlutusFinancialReportSlicer.parseCurrencyData(input: input)

        XCTAssertEqual(currencyData.count, 2)
        XCTAssertEqual(currencyData.map(\.currency), ["AED", "AUD"])
    }

    func testCurrencyDataWithDetailsDetectsEstimatedOnlyCurrency() throws {
        let lines = [
            "\"iTunes Connect - Payments and Financial Reports\t(December, 2025)\",,,,,,,,,,,,",
            ",,,,,,,,,,,,",
            "Country or Region (Currency),Units Sold,Balance,Earned,Pre-Tax Subtotal,Input Tax,Adjustments,Withholding Tax,Total Owed,Exchange Rate,Proceeds,Bank Account Currency,",
            "\"Euro-Zone (EUR)\",\"1\",\"\",\"10.00\",\"10.00\",\"0\",\"0\",\"0\",\"10.00\",\"1.00000\",\"10.00\",\"EUR\",",
            ",,,,,,,,,,,,",
            "Country or Region (Currency),Units Sold,Balance,Earned,Pre-Tax Subtotal,Input Tax,Adjustments,Withholding Tax,Total Owed,Exchange Rate,Proceeds,Bank Account Currency,",
            "\"Bulgaria (BGN)\",\"1\",\"-21.24\",\"21.24\",\"0.00\",\"0\",\"-21.24\",\"0\",\"-21.24\",\"\",\"-10.85\",\"EUR\",",
            ",,,,,,,,,,,,",
        ]
        let input = lines.joined(separator: "\r\n")

        let details = try PlutusFinancialReportSlicer.parseCurrencyDataWithDetails(input: input)

        XCTAssertEqual(details.currencyData.map(\.currency), ["EUR"])
        XCTAssertEqual(Set(details.estimatedOnlyCurrencies), ["BGN"])
    }

    func testParseFinancialReports() throws {
        let report: String = try readFile(url: Bundle.module.url(forResource: "45545510_0914", withExtension: "txt")!)
        let financialReportsData = try PlutusFinancialReportSlicer.parseFinancialReports(report: report)

        for countrySales in financialReportsData.sales {
            switch countrySales.countryCode {
            case "JP":
                AssertSameProductSales(countrySales.sales, [ProductSale(product: "Example App 3", quantity: 1, amount: 119.00), ProductSale(product: "Example App 4", quantity: 1, amount: 60.00)])
                XCTAssertEqual(countrySales.currency, "JPY")
            case "CH":
                AssertSameProductSales(countrySales.sales, [
                    ProductSale(product: "Example App 1", quantity: 16, amount: 20.80),
                    ProductSale(product: "Example App 2", quantity: 5, amount: 3.25),
                    ProductSale(product: "Example App 3", quantity: 6, amount: 7.80),
                    ProductSale(product: "Example App 4", quantity: 2, amount: 1.30),
                ])
                XCTAssertEqual(countrySales.currency, "CHF")
            case "DE":
                AssertSameProductSales(countrySales.sales, [
                    ProductSale(product: "Example App 5", quantity: 15, amount: 158.21),
                    ProductSale(product: "Example App 6", quantity: 2, amount: 24.34),
                ])
                XCTAssertEqual(countrySales.currency, "EUR")
            case "FI":
                AssertSameProductSales(countrySales.sales, [ProductSale(product: "Example App 5", quantity: 1, amount: 12.17)])
                XCTAssertEqual(countrySales.currency, "EUR")
            case "FR":
                AssertSameProductSales(countrySales.sales, [ProductSale(product: "Example App 5", quantity: 1, amount: 12.17)])
                XCTAssertEqual(countrySales.currency, "EUR")
            case "CA":
                AssertSameProductSales(countrySales.sales, [ProductSale(product: "Example App 5", quantity: 1, amount: 10.2)])
                XCTAssertEqual(countrySales.currency, "USD")
            case "UA":
                AssertSameProductSales(countrySales.sales, [ProductSale(product: "Example App 5", quantity: 1, amount: 4.95)])
                XCTAssertEqual(countrySales.currency, "USD - RoW")
            case "CR":
                AssertSameProductSales(countrySales.sales, [ProductSale(product: "Example App 5", quantity: 1, amount: 5.09)])
                XCTAssertEqual(countrySales.currency, "USD - LatAm")
            default:
                XCTFail(countrySales.countryCode)
            }
        }

        XCTAssertEqual(financialReportsData.sales.count, 8)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        XCTAssertEqual(financialReportsData.dateRange, DateInterval(start: dateFormatter.date(from: "08/31/2014")!, end: dateFormatter.date(from: "09/27/2014")!))
    }

    fileprivate func AssertSameCountrySplitting(_ a: [Invoice.SubInvoice], _ b: [Invoice.SubInvoice], file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(Set(a), Set(b), file: file, line: line)
    }

    fileprivate func AssertSameProductSales(_ a: [ProductSale], _ b: [ProductSale], file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(Set(a), Set(b), file: file, line: line)
    }

    fileprivate func readFile(url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return String(data: data, encoding: .utf8)!
    }
}
