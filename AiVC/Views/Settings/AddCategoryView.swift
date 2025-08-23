//
//  AddCategoryView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var categoryName = ""
    @State private var selectedIcon = "questionmark"
    @State private var selectedColor = Color.blue
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false
    
    // 预定义图标
    private let availableIcons = [
        "fork.knife", "cup.and.saucer", "car", "bus", "tram",
        "house", "bed.double", "lightbulb", "tv", "gamecontroller",
        "book", "graduationcap", "stethoscope", "cart", "bag",
        "gift", "heart", "star", "leaf", "flame",
        "drop", "bolt", "sun.max", "moon", "cloud",
        "umbrella", "snow", "thermometer", "wind", "tornado"
    ]
    
    // 预定义颜色
    private let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .mint,
        .teal, .cyan, .blue, .indigo, .purple,
        .pink, .brown, .gray
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 预览
                        categoryPreview
                        
                        // 分类名称
                        categoryNameInput
                        
                        // 图标选择
                        iconSelection
                        
                        // 颜色选择
                        colorSelection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("添加分类")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("保存") {
                    saveCategory()
                }
                .foregroundColor(.blue)
                .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
            .preferredColorScheme(.dark)
        }
    }
    
    // 分类预览
    private var categoryPreview: some View {
        VStack(spacing: 16) {
            Text("预览")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                Circle()
                    .fill(selectedColor)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: selectedIcon)
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    )
                
                Text(categoryName.isEmpty ? "分类名称" : categoryName)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
            )
        }
    }
    
    // 分类名称输入
    private var categoryNameInput: some View {
        VStack(spacing: 0) {
            HStack {
                Text("分类名称")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "textformat")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)
                    
                    TextField("请输入分类名称", text: $categoryName)
                        .foregroundColor(.white)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
            )
        }
    }
    
    // 图标选择
    private var iconSelection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("选择图标")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                Button(action: {
                    showingIconPicker = true
                }) {
                    HStack {
                        Image(systemName: "square.grid.3x3")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        
                        Text("当前图标")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: selectedIcon)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            )
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
            )
        }
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(selectedIcon: $selectedIcon)
        }
    }
    
    // 颜色选择
    private var colorSelection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("选择颜色")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            VStack(spacing: 16) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(availableColors.indices, id: \.self) { index in
                        let color = availableColors[index]
                        Button(action: {
                            selectedColor = color
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: selectedColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
            )
        }
    }
    
    // 保存分类
    private func saveCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newCategory = ExpenseCategory(
            name: trimmedName,
            iconName: selectedIcon,
            colorHex: selectedColor.toHex(),
            isDefault: false
        )
        
        modelContext.insert(newCategory)
        try? modelContext.save()
        
        dismiss()
    }
}

// 图标选择器
struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIcon: String
    
    private let availableIcons = [
        "fork.knife", "cup.and.saucer", "car", "bus", "tram",
        "house", "bed.double", "lightbulb", "tv", "gamecontroller",
        "book", "graduationcap", "stethoscope", "cart", "bag",
        "gift", "heart", "star", "leaf", "flame",
        "drop", "bolt", "sun.max", "moon", "cloud",
        "umbrella", "snow", "thermometer", "wind", "tornado",
        "phone", "envelope", "camera", "music.note", "headphones",
        "airplane", "bicycle", "scooter", "sailboat", "figure.walk"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                                dismiss()
                            }) {
                                Circle()
                                    .fill(selectedIcon == icon ? Color.blue : Color(red: 0.11, green: 0.11, blue: 0.12))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: icon)
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("选择图标")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("取消") {
                    dismiss()
                }
            )
            .preferredColorScheme(.dark)
        }
    }
}

// Color扩展，用于转换为十六进制
extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255)
        return String(format: "#%06x", rgb)
    }
}

#Preview {
    AddCategoryView()
        .modelContainer(for: [ExpenseCategory.self], inMemory: true)
}