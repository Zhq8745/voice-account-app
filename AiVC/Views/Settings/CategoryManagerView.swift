//
//  CategoryManagerView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct CategoryManagerView: View {
    private let cloudSyncService = CloudSyncService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [ExpenseCategory]
    
    @State private var showingAddCategory = false
    @State private var editingCategory: ExpenseCategory?
    @State private var searchText = ""
    
    // 筛选后的分类
    private var filteredCategories: [ExpenseCategory] {
        if searchText.isEmpty {
            return categories.sorted { $0.name < $1.name }
        } else {
            return categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.name < $1.name }
        }
    }
    
    // 默认分类
    private var defaultCategories: [ExpenseCategory] {
        filteredCategories.filter { $0.isDefault }
    }
    
    // 自定义分类
    private var customCategories: [ExpenseCategory] {
        filteredCategories.filter { !$0.isDefault }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        if !defaultCategories.isEmpty {
                            CategorySection(
                                title: "默认分类",
                                categories: defaultCategories,
                                onEdit: { category in
                                    editingCategory = category
                                },
                                onDelete: deleteCategory
                            )
                        }
                        
                        if !customCategories.isEmpty {
                            CategorySection(
                                title: "自定义分类",
                                categories: customCategories,
                                onEdit: { category in
                                    editingCategory = category
                                },
                                onDelete: deleteCategory
                            )
                        }
                        
                        if filteredCategories.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray.opacity(0.6))
                                
                                Text(searchText.isEmpty ? "暂无分类" : "未找到匹配的分类")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                if searchText.isEmpty {
                                    Text("点击右上角的 + 按钮添加新分类")
                                        .font(.subheadline)
                                        .foregroundColor(.gray.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.top, 60)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.black)
            .navigationTitle("分类管理")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(.hidden, for: .tabBar)
            .navigationBarItems(
                leading: Button("完成") {
                    dismiss()
                },
                trailing: Button(action: {
                    showingAddCategory = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.cyan)
                                .shadow(
                                    color: Color.blue.opacity(0.3),
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                        )
                }
            )
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView()
        }
        .sheet(item: $editingCategory) { category in
            EditCategoryView(category: category)
        }
    }
    
    // 搜索栏
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray.opacity(0.6))
                .font(.system(size: 16))
            
            TextField("搜索分类", text: $searchText)
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray.opacity(0.6))
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
    

    
    // 删除分类
    private func deleteCategory(_ category: ExpenseCategory) {
        modelContext.delete(category)
        try? modelContext.save()
        // 触发自动同步
        cloudSyncService.triggerAutoSync(for: category.id)
    }
}

// 分类分组视图
struct CategorySection: View {
    let title: String
    let categories: [ExpenseCategory]
    let onEdit: (ExpenseCategory) -> Void
    let onDelete: (ExpenseCategory) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
                
                Text("\(categories.count)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray6).opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // 分类列表
            VStack(spacing: 0) {
                ForEach(categories, id: \.id) { category in
                    CategoryManagerRow(
                        category: category,
                        onEdit: { onEdit(category) },
                        onDelete: { onDelete(category) }
                    )
                    
                    if category.id != categories.last?.id {
                        Divider()
                            .background(Color(.systemGray6).opacity(0.2))
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6).opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

// 分类管理行
struct CategoryManagerRow: View {
    let category: ExpenseCategory
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingActionSheet = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if !category.isDefault {
                showingActionSheet = true
            }
        }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(category.color)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: category.iconName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .scaleEffect(1.0) // 固定缩放比例
                    .animation(nil, value: showingActionSheet) // 禁用所有动画
                
                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                if category.isDefault {
                    Text("默认")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(category.color)
                        )
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text(category.name),
                buttons: [
                    .default(Text("编辑")) {
                        onEdit()
                    },
                    .destructive(Text("删除")) {
                        onDelete()
                    },
                    .cancel(Text("取消"))
                ]
            )
        }
    }
}

#Preview {
    CategoryManagerView()
        .modelContainer(for: [ExpenseCategory.self], inMemory: true)
}