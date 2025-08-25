//
//  APIKeyConfigView.swift
//  AiVC
//
//  Created by AI Assistant on 2024/01/01.
//

import SwiftUI
import Foundation

struct APIKeyConfigView: View {
    @ObservedObject private var securityManager = SecurityManager.shared
    @ObservedObject private var tongYiService = TongYiQianWenService()
    
    @State private var apiKey: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isConfiguring = false
    @State private var showAPIKey = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("阿里云通义千问API配置")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("API密钥")
                            Spacer()
                            Button(action: {
                                showAPIKey.toggle()
                            }) {
                                Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if showAPIKey {
                            TextField("请输入API密钥", text: $apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("请输入API密钥", text: $apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        Text("API密钥格式：sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("当前状态")) {
                    HStack {
                        Text("配置状态")
                        Spacer()
                        if securityManager.hasAPIKey(for: .tongYiQianWen) {
                            Label("已配置", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Label("未配置", systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    
                    if let maskedKey = securityManager.getMaskedAPIKey(for: .tongYiQianWen) {
                        HStack {
                            Text("当前密钥")
                            Spacer()
                            Text(maskedKey)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("配置进度")
                        Spacer()
                        Text("\(Int(securityManager.configurationProgress * 100))%")
                            .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("配置建议")) {
                    ForEach(securityManager.configurationSuggestions, id: \.self) { suggestion in
                        HStack {
                            Image(systemName: "lightbulb")
                                .foregroundColor(.orange)
                            Text(suggestion)
                                .font(.caption)
                        }
                    }
                }
                
                Section(header: Text("操作")) {
                    Button(action: configureAPIKey) {
                        HStack {
                            if isConfiguring {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "key.fill")
                            }
                            Text(isConfiguring ? "配置中..." : "保存配置")
                        }
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isConfiguring)
                    
                    if securityManager.hasAPIKey(for: .tongYiQianWen) {
                        Button(action: testAPIKey) {
                            HStack {
                                Image(systemName: "checkmark.shield")
                                Text("测试连接")
                            }
                        }
                        .disabled(isConfiguring)
                        
                        Button(action: deleteAPIKey) {
                            HStack {
                                Image(systemName: "trash")
                                Text("删除配置")
                            }
                        }
                        .foregroundColor(.red)
                        .disabled(isConfiguring)
                    }
                }
                
                Section(header: Text("帮助信息")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("如何获取API密钥：")
                            .font(.headline)
                        
                        Text("1. 访问阿里云DashScope平台")
                        Text("2. 注册并登录账号")
                        Text("3. 在控制台中创建API密钥")
                        Text("4. 复制密钥并粘贴到上方输入框")
                        
                        Link("访问DashScope平台", destination: URL(string: "https://dashscope.console.aliyun.com/")!)
                            .foregroundColor(.blue)
                    }
                    .font(.caption)
                }
            }
            .navigationTitle("API配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
        .onAppear {
            loadCurrentAPIKey()
        }
    }
    
    private func loadCurrentAPIKey() {
        if let currentKey = securityManager.getAPIKey(for: .tongYiQianWen) {
            apiKey = currentKey
        }
    }
    
    private func configureAPIKey() {
        isConfiguring = true
        
        let result = securityManager.setupTongYiQianWenAPI(key: apiKey)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isConfiguring = false
            alertTitle = result.success ? "配置成功" : "配置失败"
            alertMessage = result.message
            showingAlert = true
            
            if result.success {
                // 清空输入框
                apiKey = ""
            }
        }
    }
    
    private func testAPIKey() {
        isConfiguring = true
        
        Task {
            do {
                let testResult = try await tongYiService.analyzeExpenseText("测试连接")
                
                DispatchQueue.main.async {
                    isConfiguring = false
                    alertTitle = "测试成功"
                    alertMessage = "API连接正常，置信度: \(String(format: "%.1f%%", testResult.confidence * 100))"
                    showingAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    isConfiguring = false
                    alertTitle = "测试失败"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    private func deleteAPIKey() {
        let success = securityManager.deleteAPIKey(for: .tongYiQianWen)
        
        alertTitle = success ? "删除成功" : "删除失败"
        alertMessage = success ? "API密钥已从设备中删除" : "删除API密钥时发生错误"
        showingAlert = true
        
        if success {
            apiKey = ""
        }
    }
}

struct APIKeyConfigView_Previews: PreviewProvider {
    static var previews: some View {
        APIKeyConfigView()
    }
}