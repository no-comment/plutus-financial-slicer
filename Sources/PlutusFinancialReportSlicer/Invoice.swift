import Foundation

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
