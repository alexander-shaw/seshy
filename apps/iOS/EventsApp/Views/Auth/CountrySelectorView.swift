//
//  CountrySelectorView.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

import SwiftUI

struct CountrySelectorView: View {
    @Environment(\.theme) private var theme
    @Binding var selectedCountry: CountryCode?
    var onCountrySelected: (CountryCode) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText: String = ""
    
    private var filteredCountries: [CountryCode] {
        if searchText.isEmpty {
            return CountryCodeData.countryCodes
        }
        let lowercased = searchText.lowercased()
        return CountryCodeData.countryCodes.filter { country in
            country.name.lowercased().contains(lowercased) ||
            country.callingCode.contains(searchText) ||
            country.countryCode2.lowercased().contains(lowercased)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBarView(
                    text: $searchText,
                    placeholder: "Search",
                    autofocus: false
                )
                .padding(.top, theme.spacing.small)
                .padding(.horizontal, theme.spacing.small)
                
                // Country List:
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredCountries, id: \.countryCode2) { country in
                            Button {
                                onCountrySelected(country)
                                dismiss()
                            } label: {
                                HStack(spacing: theme.spacing.small) {
                                    Text(country.flag)
                                        .iconStyle()
                                    
                                    Text(country.callingCode)
                                        .foregroundStyle(selectedCountry?.countryCode2 == country.countryCode2 ? theme.colors.mainText : theme.colors.offText)
                                        .bodyTextStyle()
                                        .frame(width: 60, alignment: .leading)
                                    
                                    Text(country.name)
                                        .foregroundStyle(selectedCountry?.countryCode2 == country.countryCode2 ? theme.colors.mainText : theme.colors.offText)
                                        .bodyTextStyle()
                                    
                                    Spacer()
                                    
                                    if selectedCountry?.countryCode2 == country.countryCode2 {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(theme.colors.accent)
                                            .bodyTextStyle()
                                    }
                                }
                                .padding(.vertical, theme.spacing.small)
                                .padding(.horizontal, theme.spacing.medium)
                                .contentShape(Rectangle())
                            }
                            
                            Divider()
                                .foregroundStyle(theme.colors.surface)
                        }
                    }
                    .padding(.vertical, theme.spacing.medium)
                }
            }
            .background(theme.colors.background)
        }
    }
}
