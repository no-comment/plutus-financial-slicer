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
        print(splits)

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
            case "EUR":
                XCTAssertEqual(data.exchangeRate, 1, accuracy: 0.000001)
                XCTAssertEqual(data.taxFactor, 1, accuracy: 0.000001)
            case "JPY":
                XCTAssertEqual(data.exchangeRate, 0.008169014084507042253521126761, accuracy: 0.000001)
                XCTAssertEqual(data.taxFactor, 0.7932960893854748603351955307, accuracy: 0.000001)
            case "USD":
                XCTAssertEqual(data.exchangeRate, 0.9195617316942812, accuracy: 0.000001)
                XCTAssertEqual(data.taxFactor, 1, accuracy: 0.000001)
            case "USD - RoW":
                XCTAssertEqual(data.exchangeRate, 0.9191919191919191, accuracy: 0.000001)
                XCTAssertEqual(data.taxFactor, 1, accuracy: 0.000001)
            case "USD - LatAm":
                XCTAssertEqual(data.exchangeRate, 0.91944990176817287, accuracy: 0.000001)
                XCTAssertEqual(data.taxFactor, 1, accuracy: 0.000001)
            default:
                XCTFail(data.currency)
            }
        }

        XCTAssertEqual(currencyData.count, 6)
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
