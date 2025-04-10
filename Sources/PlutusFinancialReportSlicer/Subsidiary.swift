import Foundation

public enum Subsidiary: CaseIterable, Codable, Comparable {
    case europe
    case us
    case australia
    case canada
    case japan
    case latam
    case apac

    init?(code: String, date: Date) {
        for subsidiary in Subsidiary.allCases {
            let overseeingCountries = subsidiary.overseeingCountries(date: date)
            if overseeingCountries[code] != nil {
                self = subsidiary
                return
            }
        }
        print("Error: Could not find Subsidiary for \(code).")
        return nil
    }
}

public extension Subsidiary {
    var adress: String {
        switch self {
        case .australia:
            """
            Apple Pty Limited
            Level 3
            20 Martin Place
            Sydney NSW 2000
            Australia
            """
        case .canada:
            """
            Apple Canada Inc.
            120 Bremner Boulevard, Suite 1600
            Toronto, ON M5J 0A8
            Canada
            """
        case .europe:
            """
            Apple Distribution International Ltd.
            Hollyhill Industrial Estate
            Hollyhill, Cork
            Republic of Ireland
            VAT ID: IE9700053D
            """
        case .japan:
            """
            iTunes K.K.
            〒 106-6140
            6-10-1 Roppongi, Minato-ku, Tokyo
            Japan
            """
        case .latam:
            """
            Apple Services LATAM LLC
            1 Alhambra Plaza
            Suite 700
            Coral Gables, FL 33134
            U.S.A.
            """
        case .us:
            """
            Apple Inc.
            1 Apple Park Way
            Cupertino, CA 95014
            U.S.A.
            """
        case .apac:
            """
            Apple Services Pte. Ltd.
            7 Ang Mo Kio Street 64
            Singapore 569086
            Singapore
            """
        }
    }

    var title: String {
        switch self {
        case .australia: "Apple Pty Limited"
        case .canada: "Apple Canada Inc."
        case .europe: "Apple Distribution International"
        case .japan: "iTunes K.K."
        case .latam: "Apple Services LATAM LLC"
        case .us: "Apple Inc."
        case .apac: "Apple Services Pte. Ltd."
        }
    }
}

// MARK: Countries per Subsidy

/// Get name of country with given country code
func countryName(for code: String) throws -> String {
    for subsidiary in Subsidiary.allCases {
        if let countryName = subsidiary.overseeingCountries(date: Date.now)[code] {
            return countryName
        }
    }

    throw LookupError.unknownCountryCode(code)
}

// https://developer.apple.com/help/app-store-connect/reference/apple-legal-entities/
// https://developer.apple.com/help/app-store-connect/reference/financial-report-regions-and-currencies

public extension Subsidiary {
    func overseeingCountries(date: Date) -> [String: String] {
        switch self {
        case .apac:
            if date < Date.subsidiaryChange2024 { return [:] }
            return [
                "BT": "Bhutan",
                "BN": "Brunei",
                "KH": "Cambodia",
                "FM": "Federal States of Micronesia",
                "FJ": "Fiji",
                "KR": "Korea",
                "LA": "Laos",
                "MO": "Macao",
                "MV": "Maldives",
                "MN": "Mongolia",
                "MM": "Myanmar",
                "NR": "Nauru",
                "NP": "Nepal",
                "PW": "Palau",
                "PG": "Papua New Guinea",
                "SB": "Solomon Islands",
                "LK": "Sri Lanka",
                "TO": "Tonga",
                "VU": "Vanuatu"
            ]
        case .australia:
            return [
                "AU": "Australia",
                "NZ": "New Zealand"
            ]
        case .canada:
            return [
                "CA": "Canada"
            ]
        case .us:
            return [
                "US": "United States"
            ]
        case .japan:
            return [
                "JP": "Japan"
            ]
        case .latam:
            return [
                "AI": "Anguilla",
                "AG": "Antigua & Barbuda",
                "AR": "Argentinia",
                "BS": "Bahamas",
                "BB": "Barbados",
                "BZ": "Belize",
                "BM": "Bermuda",
                "BO": "Bolivia",
                "BR": "Brazil",
                "VG": "British Virgin Islands",
                "KY": "Cayman Islands",
                "CL": "Chile",
                "CO": "Colombia",
                "CR": "Costa Rica",
                "DM": "Dominica",
                "DO": "Dominican Republic",
                "EC": "Ecuador",
                "SV": "El Salvador",
                "GD": "Grenada",
                "GY": "Guyana",
                "GT": "Guatemala",
                "HN": "Honduras",
                "JM": "Jamaica",
                "MX": "Mexico",
                "MS": "Montserrat",
                "NI": "Nicaragua",
                "PA": "Panama",
                "PY": "Paraguay",
                "PE": "Peru",
                "KN": "St. Kitts & Nevis",
                "LC": "St. Lucia",
                "VC": "St. Vincent & The Grenadines",
                "SR": "Suriname",
                "TT": "Trinidad & Tobago",
                "TC": "Turks & Caicos",
                "UY": "Uruguay",
                "VE": "Venezuela"
            ]
        case .europe:
            if date < Date.subsidiaryChange2024 {
                return [
                    "AF": "Afghanistan",
                    "AL": "Albania",
                    "DZ": "Algeria",
                    "AO": "Angola",
                    "AM": "Armenia",
                    "AT": "Austria",
                    "AZ": "Azerbaijan",
                    "BH": "Bahrain",
                    "BY": "Belarus",
                    "BE": "Belgium",
                    "BJ": "Benin",
                    "BT": "Bhutan",
                    "BA": "Bosnia and Herzegovina",
                    "BW": "Botswana",
                    "BN": "Brunei",
                    "BG": "Bulgaria",
                    "BF": "Burkina-Faso",
                    "KH": "Cambodia",
                    "CM": "Cameroon",
                    "CV": "Cape Verde",
                    "TD": "Chad",
                    "CN": "China",
                    "CD": "Democratic Republic of Congo",
                    "CG": "Republic of Congo",
                    "CI": "Cote d’Ivoire",
                    "HR": "Croatia",
                    "CY": "Cyprus",
                    "CZ": "Czech Republic",
                    "DK": "Denmark",
                    "EG": "Egypt",
                    "EE": "Estonia",
                    "FJ": "Fiji",
                    "FI": "Finland",
                    "FR": "France",
                    "GA": "Gabon",
                    "GM": "Gambia",
                    "GE": "Georgia",
                    "DE": "Germany",
                    "GH": "Ghana",
                    "GR": "Greece",
                    "GW": "Guinea-Bissau",
                    "HK": "Hong Kong",
                    "HU": "Hungary",
                    "IS": "Iceland",
                    "IN": "India",
                    "ID": "Indonesia",
                    "IQ": "Iraq",
                    "IE": "Ireland",
                    "IL": "Israel",
                    "IT": "Italy",
                    "JO": "Jordan",
                    "KZ": "Kazakhstan",
                    "KE": "Kenya",
                    "KR": "Korea",
                    "XK": "Kosovo",
                    "KW": "Kuwait",
                    "KG": "Kyrgyzstan",
                    "LA": "Laos",
                    "LV": "Latvia",
                    "LB": "Lebanon",
                    "LR": "Liberia",
                    "LY": "Libya",
                    "LT": "Lithuania",
                    "LU": "Luxembourg",
                    "MO": "Macao",
                    "MK": "Macedonia",
                    "MG": "Madagascar",
                    "MW": "Malawi",
                    "MY": "Malaysia",
                    "MV": "Maldives",
                    "ML": "Mali",
                    "MT": "Republic of Malta",
                    "MR": "Mauritania",
                    "MU": "Mauritius",
                    "FM": "Federal States of Micronesia",
                    "MD": "Moldova",
                    "MN": "Mongolia",
                    "ME": "Montenegro",
                    "MA": "Morocco",
                    "MZ": "Mozambique",
                    "MM": "Myanmar",
                    "NA": "Namibia",
                    "NR": "Nauru",
                    "NP": "Nepal",
                    "NL": "Netherlands",
                    "NE": "Niger",
                    "NG": "Nigeria",
                    "NO": "Norway",
                    "OM": "Oman",
                    "PK": "Pakistan",
                    "PW": "Palau",
                    "PG": "Papua New Guinea",
                    "PH": "Philippines",
                    "PL": "Poland",
                    "PT": "Portugal",
                    "QA": "Qatar",
                    "RO": "Romania",
                    "RU": "Russia",
                    "RW": "Rwanda",
                    "ST": "Sao Tome e Principe",
                    "SA": "Saudi Arabia",
                    "SN": "Senegal",
                    "RS": "Serbia",
                    "SC": "Seychelles",
                    "SL": "Sierra Leone",
                    "SG": "Singapore",
                    "SK": "Slovakia",
                    "SI": "Slovenia",
                    "SB": "Solomon Islands",
                    "ZA": "South Africa",
                    "ES": "Spain",
                    "LK": "Sri Lanka",
                    "SZ": "Swaziland",
                    "SE": "Sweden",
                    "CH": "Switzerland",
                    "TW": "Taiwan",
                    "TJ": "Tajikistan",
                    "TZ": "Tanzania",
                    "TH": "Thailand",
                    "TO": "Tonga",
                    "TN": "Tunisia",
                    "TR": "Türkiye",
                    "TM": "Turkmenistan",
                    "AE": "United Arab Emirates",
                    "UG": "Uganda",
                    "UA": "Ukraine",
                    "GB": "United Kingdom",
                    "UZ": "Uzbekistan",
                    "VU": "Vanuatu",
                    "VN": "Vietnam",
                    "YE": "Yemen",
                    "ZM": "Zambia",
                    "ZW": "Zimbabwe"
                ]
            } else {
                return [
                    "AF": "Afghanistan",
                    "AL": "Albania",
                    "DZ": "Algeria",
                    "AO": "Angola",
                    "AM": "Armenia",
                    "AT": "Austria",
                    "AZ": "Azerbaijan",
                    "BH": "Bahrain",
                    "BY": "Belarus",
                    "BE": "Belgium",
                    "BJ": "Benin",
                    "BA": "Bosnia and Herzegovina",
                    "BW": "Botswana",
                    "BG": "Bulgaria",
                    "BF": "Burkina-Faso",
                    "CM": "Cameroon",
                    "CV": "Cape Verde",
                    "TD": "Chad",
                    "CN": "China",
                    "CD": "Democratic Republic of Congo",
                    "CG": "Republic of Congo",
                    "CI": "Cote d’Ivoire",
                    "HR": "Croatia",
                    "CY": "Cyprus",
                    "CZ": "Czech Republic",
                    "DK": "Denmark",
                    "EG": "Egypt",
                    "EE": "Estonia",
                    "FI": "Finland",
                    "FR": "France",
                    "GA": "Gabon",
                    "GM": "Gambia",
                    "GE": "Georgia",
                    "DE": "Germany",
                    "GH": "Ghana",
                    "GR": "Greece",
                    "GW": "Guinea-Bissau",
                    "HK": "Hong Kong",
                    "HU": "Hungary",
                    "IS": "Iceland",
                    "IN": "India",
                    "ID": "Indonesia",
                    "IQ": "Iraq",
                    "IE": "Ireland",
                    "IL": "Israel",
                    "IT": "Italy",
                    "JO": "Jordan",
                    "KZ": "Kazakhstan",
                    "KE": "Kenya",
                    "XK": "Kosovo",
                    "KW": "Kuwait",
                    "KG": "Kyrgyzstan",
                    "LV": "Latvia",
                    "LB": "Lebanon",
                    "LR": "Liberia",
                    "LY": "Libya",
                    "LT": "Lithuania",
                    "LU": "Luxembourg",
                    "MK": "Macedonia",
                    "MG": "Madagascar",
                    "MW": "Malawi",
                    "MY": "Malaysia",
                    "ML": "Mali",
                    "MT": "Republic of Malta",
                    "MR": "Mauritania",
                    "MU": "Mauritius",
                    "MD": "Moldova",
                    "ME": "Montenegro",
                    "MA": "Morocco",
                    "MZ": "Mozambique",
                    "NA": "Namibia",
                    "NL": "Netherlands",
                    "NE": "Niger",
                    "NG": "Nigeria",
                    "NO": "Norway",
                    "OM": "Oman",
                    "PK": "Pakistan",
                    "PH": "Philippines",
                    "PL": "Poland",
                    "PT": "Portugal",
                    "QA": "Qatar",
                    "RO": "Romania",
                    "RU": "Russia",
                    "RW": "Rwanda",
                    "ST": "Sao Tome e Principe",
                    "SA": "Saudi Arabia",
                    "SN": "Senegal",
                    "RS": "Serbia",
                    "SC": "Seychelles",
                    "SL": "Sierra Leone",
                    "SG": "Singapore",
                    "SK": "Slovakia",
                    "SI": "Slovenia",
                    "ZA": "South Africa",
                    "ES": "Spain",
                    "SZ": "Swaziland",
                    "SE": "Sweden",
                    "CH": "Switzerland",
                    "TW": "Taiwan",
                    "TJ": "Tajikistan",
                    "TZ": "Tanzania",
                    "TH": "Thailand",
                    "TN": "Tunisia",
                    "TR": "Türkiye",
                    "TM": "Turkmenistan",
                    "AE": "United Arab Emirates",
                    "UG": "Uganda",
                    "UA": "Ukraine",
                    "GB": "United Kingdom",
                    "UZ": "Uzbekistan",
                    "VN": "Vietnam",
                    "YE": "Yemen",
                    "ZM": "Zambia",
                    "ZW": "Zimbabwe"
                ]
            }
        }
    }

    // https://developer.apple.com/help/app-store-connect/reference/financial-report-regions-and-currencies
    // not for corporations but for currency conversion
    static let restOfWorldCountries: [String] = [
        "AF", // Afghanistan
        "AL", // Albania
        "DZ", // Algeria
        "AO", // Angola
        "AM", // Armenia
        "AZ", // Azerbaijan
        "BH", // Bahrain
        "BY", // Belarus
        "BJ", // Benin
        "BW", // Botswana
        "BF", // Burkina Faso
        "CM", // Cameroon
        "CV", // Cape Verde
        "TD", // Chad
        "CD", // Democratic Republic of the Congo
        "CG", // Republic of the Congo
        "CI", // Côte d'Ivoire
        "HR", // Croatia
        "EG", // Egypt
        "SZ", // Eswatini
        "GA", // Gabon
        "GM", // Gambia
        "GE", // Georgia
        "GH", // Ghana
        "GW", // Guinea-Bissau
        "IS", // Iceland
        "IQ", // Iraq
        "JO", // Jordan
        "KZ", // Kazakhstan
        "KE", // Kenya
        "KW", // Kuwait
        "KG", // Kyrgyzstan
        "LB", // Lebanon
        "LR", // Liberia
        "LY", // Libya
        "MG", // Madagascar
        "MW", // Malawi
        "MY", // Malaysia
        "ML", // Mali
        "MR", // Mauritania
        "MU", // Mauritius
        "MD", // Moldova
        "MA", // Morocco
        "MZ", // Mozambique
        "NA", // Namibia
        "NE", // Niger
        "NG", // Nigeria
        "MK", // North Macedonia
        "OM", // Oman
        "PK", // Pakistan
        "PH", // Philippines
        "QA", // Qatar
        "RW", // Rwanda
        "ST", // São Tomé and Príncipe
        "SN", // Senegal
        "SC", // Seychelles
        "SL", // Sierra Leone
        "TJ", // Tajikistan
        "TN", // Tunisia
        "TM", // Turkmenistan
        "UG", // Uganda
        "UA", // Ukraine
        "UZ", // Uzbekistan
        "VN", // Vietnam
        "YE", // Yemen
        "ZM", // Zambia
        "ZW" // Zimbabwe
    ]

    // https://developer.apple.com/help/app-store-connect/reference/financial-report-regions-and-currencies
    // not for corporations but for currency conversion
    static let latinAmericaCaribbeanCountries: [String] = [
        "AI", // Anguilla
        "AG", // Antigua and Barbuda
        "AR", // Argentina
        "BS", // Bahamas
        "BB", // Barbados
        "BZ", // Belize
        "BM", // Bermuda
        "BO", // Bolivia
        "VG", // British Virgin Islands
        "KY", // Cayman Islands
        "CL", // Chile
        "CR", // Costa Rica
        "DM", // Dominica
        "DO", // Dominican Republic
        "EC", // Ecuador
        "SV", // El Salvador
        "GD", // Grenada
        "GT", // Guatemala
        "GY", // Guyana
        "HN", // Honduras
        "JM", // Jamaica
        "MS", // Montserrat
        "NI", // Nicaragua
        "PA", // Panama
        "PY", // Paraguay
        "LC", // Saint Lucia
        "KN", // St. Kitts and Nevis
        "VC", // St. Vincent and the Grenadines
        "SR", // Suriname
        "TT", // Trinidad and Tobago
        "TC", // Turks and Caicos Islands
        "UY", // Uruguay
        "VE" // Venezuela
    ]

    // https://developer.apple.com/help/app-store-connect/reference/financial-report-regions-and-currencies
    // not for corporations but for currency conversion
    static let pacificCountries: [String] = [
        "BT", // Bhutan
        "BN", // Brunei
        "KH", // Cambodia
        "FJ", // Fiji
        "LA", // Laos
        "MO", // Macau
        "MV", // Maldives
        "FM", // Micronesia
        "MN", // Mongolia
        "MM", // Myanmar
        "NR", // Nauru
        "NP", // Nepal
        "PW", // Palau
        "PG", // Papua New Guinea
        "SB", // Solomon Islands
        "LK", // Sri Lanka
        "TO", // Tonga
        "VU" // Vanuatu
    ]
}

public extension Date {
    static var subsidiaryChange2024: Date {
        let gregorianCalendar = Calendar(identifier: .gregorian)
        let dateComponents = DateComponents(calendar: gregorianCalendar, year: 2024, month: 10, day: 26)
        guard let subsidiaryChange2024 = gregorianCalendar.date(from: dateComponents) else {
            fatalError("Could not initialize date")
        }
        return subsidiaryChange2024
    }
}

enum LookupError: Error {
    case unknownCountryCode(String)
    case unknownAppleCorporation(String)
}

extension LookupError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknownCountryCode(let string):
            NSLocalizedString("Unknown country code: \(string).", comment: "Localized description for LookupError.unknownCountryCode")
        case .unknownAppleCorporation(let string):
            NSLocalizedString("Unknown apple corporation: \(string).", comment: "Localized description for LookupError.unknownAppleCorporation")
        }
    }
}
