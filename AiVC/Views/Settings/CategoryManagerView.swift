//
//  CategoryManagerView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct CategoryManagerView: View {
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
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 搜索栏
                    searchBar
                    
                    // 分类列表
                    categoryList
                }
            }
            .navigationTitle("分类管理")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("完成") {
                    dismiss()
                },
                trailing: Button(action: {
                    showingAddCategory = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
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
                .foregroundColor(.gray)
            
            TextField("搜索分类", text: $searchText)
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // 分类列表
    private var categoryList: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // 默认分类
                if !defaultCategories.isEmpty {
                    CategorySection(
                        title: "默认分类",
                        categories: defaultCategories,
                        onEdit: { category in
                            editingCategory = category
                        },
                        onDelete: { category in
                            deleteCategory(category)
                        }
                    )
                }
                
                // 自定义分类
                if !customCategories.isEmpty {
                    CategorySection(
                        title: "自定义分类",
                        categories: customCategories,
                        onEdit: { category in
                            editingCategory = category
                        },
                        onDelete: { category in
                            deleteCategory(category)
                        }
                    )
                }
                
                // 空状态
                if filteredCategories.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: searchText.isEmpty ? "folder" : "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text(searchText.isEmpty ? "暂无分类" : "未找到相关分类")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        if searchText.isEmpty {
                            Button("添加分类") {
                                showingAddCategory = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
        }
    }
    
    // 删除分类
    private func deleteCategory(_ category: ExpenseCategory) {
        withAnimation {
            modelContext.delete(category)
            try? modelContext.save()
        }
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
                    .foregroundColor(.white)
                Spacer()
                
                Text("\(categories.count)个")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
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
                            .background(Color.gray.opacity(0.3))
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
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
    
    var body: some View {
        Button(action: {
            if !category.isDefault {
                showingActionSheet = true
            }
        }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(category.color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: category.iconName)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    if category.isDefault {
                        Text("系统默认分类")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if category.isDefault {
                    Text("默认")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                        )
                        .foregroundColor(.gray)
                } else {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
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