//
//  CountryCode.swift
//  CoreDomain
//
//  Created by Шоу on 10/31/25.
//

import Foundation

// Represents a country with its dialing code and metadata.
public struct CountryCode : Sendable {
    public let flag: String
    public let name: String
    public let countryCode2: String  // ISO 3166-1 alpha-2.
    public let countryCode3: String  // ISO 3166-1 alpha-3.
    public let callingCode: String   // E.164 format: +1.
    
    public init(flag: String, name: String, countryCode2: String, countryCode3: String, callingCode: String) {
        self.flag = flag
        self.name = name
        self.countryCode2 = countryCode2
        self.countryCode3 = countryCode3
        self.callingCode = callingCode
    }
}

// Country code data and utilities.
public enum CountryCodeData {
    // Array of all supported countries with their calling codes.
    public static let countryCodes: [CountryCode] = [
        CountryCode(flag: "🇺🇸", name: "United States", countryCode2: "US", countryCode3: "USA", callingCode: "+1"),
        CountryCode(flag: "🇨🇦", name: "Canada", countryCode2: "CA", countryCode3: "CAN", callingCode: "+1"),
        
        CountryCode(flag: "🇦🇷", name: "Argentina", countryCode2: "AR", countryCode3: "ARG", callingCode: "+54"),
        CountryCode(flag: "🇦🇺", name: "Australia", countryCode2: "AU", countryCode3: "AUS", callingCode: "+61"),
        CountryCode(flag: "🇦🇹", name: "Austria", countryCode2: "AT", countryCode3: "AUT", callingCode: "+43"),
        CountryCode(flag: "🇧🇩", name: "Bangladesh", countryCode2: "BD", countryCode3: "BGD", callingCode: "+880"),
        CountryCode(flag: "🇧🇪", name: "Belgium", countryCode2: "BE", countryCode3: "BEL", callingCode: "+32"),
        CountryCode(flag: "🇧🇷", name: "Brazil", countryCode2: "BR", countryCode3: "BRA", callingCode: "+55"),
        CountryCode(flag: "🇧🇬", name: "Bulgaria", countryCode2: "BG", countryCode3: "BGR", callingCode: "+359"),
        CountryCode(flag: "🇨🇳", name: "China", countryCode2: "CN", countryCode3: "CHN", callingCode: "+86"),
        CountryCode(flag: "🇭🇷", name: "Croatia", countryCode2: "HR", countryCode3: "HRV", callingCode: "+385"),
        CountryCode(flag: "🇨🇾", name: "Cyprus", countryCode2: "CY", countryCode3: "CYP", callingCode: "+357"),
        CountryCode(flag: "🇨🇿", name: "Czech Republic", countryCode2: "CZ", countryCode3: "CZE", callingCode: "+420"),
        CountryCode(flag: "🇩🇰", name: "Denmark", countryCode2: "DK", countryCode3: "DNK", callingCode: "+45"),
        CountryCode(flag: "🇪🇪", name: "Estonia", countryCode2: "EE", countryCode3: "EST", callingCode: "+372"),
        CountryCode(flag: "🇪🇹", name: "Ethiopia", countryCode2: "ET", countryCode3: "ETH", callingCode: "+251"),
        CountryCode(flag: "🇫🇮", name: "Finland", countryCode2: "FI", countryCode3: "FIN", callingCode: "+358"),
        CountryCode(flag: "🇫🇷", name: "France", countryCode2: "FR", countryCode3: "FRA", callingCode: "+33"),
        CountryCode(flag: "🇩🇪", name: "Germany", countryCode2: "DE", countryCode3: "DEU", callingCode: "+49"),
        CountryCode(flag: "🇬🇷", name: "Greece", countryCode2: "GR", countryCode3: "GRC", callingCode: "+30"),
        CountryCode(flag: "🇭🇺", name: "Hungary", countryCode2: "HU", countryCode3: "HUN", callingCode: "+36"),
        CountryCode(flag: "🇮🇳", name: "India", countryCode2: "IN", countryCode3: "IND", callingCode: "+91"),
        CountryCode(flag: "🇮🇩", name: "Indonesia", countryCode2: "ID", countryCode3: "IDN", callingCode: "+62"),
        CountryCode(flag: "🇮🇪", name: "Ireland", countryCode2: "IE", countryCode3: "IRL", callingCode: "+353"),
        CountryCode(flag: "🇮🇹", name: "Italy", countryCode2: "IT", countryCode3: "ITA", callingCode: "+39"),
        CountryCode(flag: "🇰🇿", name: "Kazakhstan", countryCode2: "KZ", countryCode3: "KAZ", callingCode: "+7"),
        CountryCode(flag: "🇱🇻", name: "Latvia", countryCode2: "LV", countryCode3: "LVA", callingCode: "+371"),
        CountryCode(flag: "🇱🇹", name: "Lithuania", countryCode2: "LT", countryCode3: "LTU", callingCode: "+370"),
        CountryCode(flag: "🇱🇺", name: "Luxembourg", countryCode2: "LU", countryCode3: "LUX", callingCode: "+352"),
        CountryCode(flag: "🇲🇹", name: "Malta", countryCode2: "MT", countryCode3: "MLT", callingCode: "+356"),
        CountryCode(flag: "🇲🇽", name: "Mexico", countryCode2: "MX", countryCode3: "MEX", callingCode: "+52"),
        CountryCode(flag: "🇳🇱", name: "Netherlands", countryCode2: "NL", countryCode3: "NLD", callingCode: "+31"),
        CountryCode(flag: "🇳🇬", name: "Nigeria", countryCode2: "NG", countryCode3: "NGA", callingCode: "+234"),
        CountryCode(flag: "🇵🇰", name: "Pakistan", countryCode2: "PK", countryCode3: "PAK", callingCode: "+92"),
        CountryCode(flag: "🇵🇱", name: "Poland", countryCode2: "PL", countryCode3: "POL", callingCode: "+48"),
        CountryCode(flag: "🇵🇹", name: "Portugal", countryCode2: "PT", countryCode3: "PRT", callingCode: "+351"),
        CountryCode(flag: "🇷🇴", name: "Romania", countryCode2: "RO", countryCode3: "ROU", callingCode: "+40"),
        CountryCode(flag: "🇷🇺", name: "Russia", countryCode2: "RU", countryCode3: "RUS", callingCode: "+7"),
        CountryCode(flag: "🇸🇰", name: "Slovakia", countryCode2: "SK", countryCode3: "SVK", callingCode: "+421"),
        CountryCode(flag: "🇸🇮", name: "Slovenia", countryCode2: "SI", countryCode3: "SVN", callingCode: "+386"),
        CountryCode(flag: "🇪🇸", name: "Spain", countryCode2: "ES", countryCode3: "ESP", callingCode: "+34"),
        CountryCode(flag: "🇸🇪", name: "Sweden", countryCode2: "SE", countryCode3: "SWE", callingCode: "+46")
    ]
    
    // Finds a country code by locale region identifier: US, CA, etc.
    // Parameter regionCode: ISO 3166-1 alpha-2 region code.
    // Returns: If found, CountryCode.  Else, nil.
    public static func countryCode(for regionCode: String) -> CountryCode? {
        countryCodes.first { $0.countryCode2 == regionCode.uppercased() }
    }
    
    // Gets the default country code based on the current locale.
    // Returns: CountryCode for current region or US (+1) as a fallback.
    public static func defaultCountryCode() -> CountryCode {
        if let regionCode = Locale.current.region?.identifier, let country = countryCode(for: regionCode) {
            return country
        }
        
        // Fallback to US.
        return countryCodes.first { $0.callingCode == "+1" } ?? countryCodes[0]
    }
}
