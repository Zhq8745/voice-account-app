//
//  CurrencyPickerView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct CurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    
    private var currentSettings: AppSettings {
        settings.first ?? AppSettings()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                List {
                    ForEach(AppSettings.currencies, id: \.0) { currency in
                        Button(action: {
                            updateCurrency(currency.0)
                        }) {
                            HStack {
                                Text("\(currency.2) \(currency.1)")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if currentSettings.currency == currency.0 {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Color(red: 0.11, green: 0.11, blue: 0.12))
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("货币单位")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    private func updateCurrency(_ currency: String) {
        if let existingSettings = settings.first {
            existingSettings.currency = currency
        } else {
            let newSettings = AppSettings()
            newSettings.currency = currency
            modelContext.insert(newSettings)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    CurrencyPickerView()
        .modelContainer(for: [AppSettings.self], inMemory: true)
}