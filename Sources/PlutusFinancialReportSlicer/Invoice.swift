import Foundation

public struct Invoice: Equatable, Codable, Hashable {
    public let recipient: Subsidiary
    public let countrySplitting: [SubInvoice]
    public let currencyAdjustments: [CurrencyAdjustment]
    public var totalInLocalCurrency: Double {
        countrySplitting.reduce(0, { $0 + $1.subtotalAmountInLocalCurrency }) + currencyAdjustments.reduce(0, { $0 + $1.amountInLocalCurrency })
    }
    public let localCurrency: String
    
    public init(recipient: Subsidiary, countrySplitting: [SubInvoice], localCurrency: String, currencyAdjustments: [CurrencyAdjustment] = []) {
        self.recipient = recipient
        self.countrySplitting = countrySplitting
        self.localCurrency = localCurrency
        self.currencyAdjustments = currencyAdjustments
    }

    private enum CodingKeys: String, CodingKey {
        case recipient
        case countrySplitting
        case currencyAdjustments
        case localCurrency
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.recipient = try container.decode(Subsidiary.self, forKey: .recipient)
        self.countrySplitting = try container.decode([SubInvoice].self, forKey: .countrySplitting)
        self.currencyAdjustments = try container.decodeIfPresent([CurrencyAdjustment].self, forKey: .currencyAdjustments) ?? []
        self.localCurrency = try container.decode(String.self, forKey: .localCurrency)
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

    public struct CurrencyAdjustment: Equatable, Hashable, Codable {
        public let currency: String
        public let amount: Double
        public let exchangeRate: Double
        public let amountInLocalCurrency: Double

        public init(currency: String, amount: Double, exchangeRate: Double, amountInLocalCurrency: Double) {
            self.currency = currency
            self.amount = amount
            self.exchangeRate = exchangeRate
            self.amountInLocalCurrency = amountInLocalCurrency
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
    let adjustments: Double
    let bankAccountCurrency: String

    init(currency: String, exchangeRate: Double, taxFactor: Double, adjustments: Double, bankAccountCurrency: String) {
        self.currency = currency
        self.exchangeRate = exchangeRate
        self.taxFactor = taxFactor
        self.adjustments = adjustments
        self.bankAccountCurrency = bankAccountCurrency
    }

    private enum CodingKeys: String, CodingKey {
        case currency
        case exchangeRate
        case taxFactor
        case adjustments
        case bankAccountCurrency
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.currency = try container.decode(String.self, forKey: .currency)
        self.exchangeRate = try container.decode(Double.self, forKey: .exchangeRate)
        self.taxFactor = try container.decode(Double.self, forKey: .taxFactor)
        self.adjustments = try container.decodeIfPresent(Double.self, forKey: .adjustments) ?? 0.0
        self.bankAccountCurrency = try container.decode(String.self, forKey: .bankAccountCurrency)
    }
}
