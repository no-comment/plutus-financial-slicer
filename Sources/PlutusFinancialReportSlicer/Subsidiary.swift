public enum Subsidiary: CaseIterable, Codable, Comparable {
    case europe
    case us
    case australia
    case canada
    case japan
    case latam

    init?(code: String) {
        for subsidiary in Subsidiary.allCases {
            if subsidiary.overseeingCountries[code] != nil {
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
        }
    }
}

// MARK: Countries per Subsidy

/// Get name of country with given country code
func countryName(for code: String) throws -> String {
    for subsidiary in Subsidiary.allCases {
        if let countryName = subsidiary.overseeingCountries[code] {
            return countryName
        }
    }

    throw LookupError.unknownCountryCode(code)
}

// https://developer.apple.com/help/app-store-connect/reference/apple-legal-entities/
// https://developer.apple.com/help/app-store-connect/reference/financial-report-regions-and-currencies

public extension Subsidiary {
    var overseeingCountries: [String: String] {
        switch self {
        case .australia:
            [
                "AU": "Australia",
                "NZ": "New Zealand"
            ]
        case .canada:
            [
                "CA": "Canada"
            ]
        case .us:
            [
                "US": "United States"
            ]
        case .japan:
            [
                "JP": "Japan"
            ]
        case .latam:
            [
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
            [
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
        }
    }

    // https://developer.apple.com/help/app-store-connect/reference/financial-report-regions-and-currencies
    // not for corporations but for currency conversion
    static let restOfWorldCountries: [String] = [
        "AF", "AL", "DZ", "AO", "AM", "AZ", "BH", "BY", "BJ", "BT", "BW", "BN", "BF", "KH", "CM", "CV", "TD", "CG", "CD", "CI", "HR", "EG", "FJ", "GA", "GM", "GE", "GH", "GW", "IS", "IQ", "JO", "KZ", "KE", "KR", "KW", "KG", "LA", "LB", "LR", "LY", "MO", "MK", "MG", "MW", "MY", "MV", "ML", "MR", "MU", "FM", "MD", "MA", "MZ", "MM", "NA", "NR", "NP", "NE", "NG", "OM", "PK", "PW", "PG", "PH", "QA", "RW", "ST", "SN", "SC", "SL", "SB", "LK", "SZ", "TJ", "TZ", "TO", "TN", "TM", "UG", "UA", "UZ", "VU", "VN", "YE", "ZM", "ZW"
    ]

    // https://developer.apple.com/help/app-store-connect/reference/financial-report-regions-and-currencies
    // not for corporations but for currency conversion
    static let latinAmericaCaribbeanCountries: [String] = [
        "AI", "AG", "AR", "BS", "BB", "BZ", "BM", "BO", "BR", "VG", "KY", "CL", "CR", "DM", "DO", "EC", "SV", "GD", "GY", "GT", "HN", "JM", "MS", "NI", "PA", "PY", "KN", "LC", "VC", "SR", "TT", "TC", "UY", "VE"
    ]
}

enum LookupError: Error {
    case unknownCountryCode(String)
    case unknownAppleCorporation(String)
}
