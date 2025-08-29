//
//  EditCategoryView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct EditCategoryView: View {
    private let cloudSyncService = CloudSyncService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let category: ExpenseCategory
    
    @State private var categoryName: String
    @State private var selectedIcon: String
    @State private var selectedColor: Color
    @State private var showingIconPicker = false
    @State private var showingDeleteAlert = false
    
    // 预定义颜色
    private let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .mint,
        .teal, .cyan, .blue, .indigo, .purple,
        .pink, .brown, .gray
    ]
    
    init(category: ExpenseCategory) {
        self.category = category
        self._categoryName = State(initialValue: category.name)
        self._selectedIcon = State(initialValue: category.iconName)
        self._selectedColor = State(initialValue: Color(hex: category.colorHex) ?? .blue)
    }
    
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
                        
                        // 删除按钮（仅非默认分类显示）
                        if !category.isDefault {
                            deleteButton
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("编辑分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("保存") {
                    saveChanges()
                }
                .foregroundColor(Color.cyan)
                .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
            .preferredColorScheme(.dark)
        }
        .alert("删除分类", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteCategory()
            }
        } message: {
            Text("确定要删除这个分类吗？删除后无法恢复。")
        }
    }
    
    // 分类预览
    private var categoryPreview: some View {
        VStack(spacing: 16) {
            Text("预览")
                .font(.headline)
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                Circle()
                    .fill(selectedColor)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: selectedIcon)
                            .font(.system(size: 32))
                            .foregroundColor(Color.white)
                    )
                
                Text(categoryName.isEmpty ? "分类名称" : categoryName)
                    .font(.headline)
                    .foregroundColor(Color.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    // 分类名称输入
    private var categoryNameInput: some View {
        VStack(spacing: 0) {
            HStack {
                Text("分类名称")
                    .font(.headline)
                    .foregroundColor(Color.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "textformat")
                        .font(.system(size: 18))
                        .foregroundColor(Color.cyan)
                        .frame(width: 24, height: 24)
                    
                    TextField("请输入分类名称", text: $categoryName)
                        .foregroundColor(Color.white)
                        .textFieldStyle(PlainTextFieldStyle())
                        .disabled(category.isDefault) // 默认分类不允许修改名称
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            
            if category.isDefault {
                HStack {
                    Text("默认分类名称不可修改")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }
    
    // 图标选择
    private var iconSelection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("选择图标")
                    .font(.headline)
                    .foregroundColor(Color.white)
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
                            .foregroundColor(Color.cyan)
                            .frame(width: 24, height: 24)
                        
                        Text("当前图标")
                            .font(.subheadline)
                            .foregroundColor(Color.white)
                        
                        Spacer()
                        
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: selectedIcon)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.white)
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
                    .fill(Color(.systemGray6).opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
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
                    .foregroundColor(Color.white)
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
    
    // 删除按钮
    private var deleteButton: some View {
        Button(action: {
            showingDeleteAlert = true
        }) {
            HStack {
                Image(systemName: "trash")
                    .font(.system(size: 18))
                Text("删除分类")
                    .font(.headline)
            }
            .foregroundColor(Color.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                 RoundedRectangle(cornerRadius: 12)
                     .fill(Color(.systemGray6).opacity(0.2))
                     .overlay(
                         RoundedRectangle(cornerRadius: 12)
                             .stroke(Color.white.opacity(0.1), lineWidth: 1)
                     )
             )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 保存更改
    private func saveChanges() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // 只有非默认分类才能修改名称
        if !category.isDefault {
            category.name = trimmedName
        }
        
        category.iconName = selectedIcon
        category.colorHex = selectedColor.toHex()
        
        try? modelContext.save()
        
        // 触发自动同步
        cloudSyncService.triggerAutoSync(for: category.id)
        
        dismiss()
    }
    
    // 删除分类
    private func deleteCategory() {
        modelContext.delete(category)
        try? modelContext.save()
        
        // 触发自动同步
        cloudSyncService.triggerAutoSync(for: category.id)
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ExpenseCategory.self, configurations: config)
    
    let sampleCategory = ExpenseCategory(
        name: "餐饮",
        iconName: "fork.knife",
        colorHex: "#FF6B6B",
        isDefault: false
    )
    
    return EditCategoryView(category: sampleCategory)
        .modelContainer(container)
}