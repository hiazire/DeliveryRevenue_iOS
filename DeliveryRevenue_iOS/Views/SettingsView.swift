import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss
    
    // 新增：用來控制密碼是否顯示的狀態
    @State private var isPasswordVisible = false

    var body: some View {
        NavigationStack {
            Form {
                Section("寄件者設定 (Gmail)") {
                    TextField("寄件者信箱", text: $viewModel.settings.senderEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true) // 防止鍵盤自動亂改
                    
                    // 新增：顯示/隱藏密碼的切換區塊
                    HStack {
                        if isPasswordVisible {
                            TextField("16位數應用程式密碼", text: $viewModel.settings.senderPassword)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("16位數應用程式密碼", text: $viewModel.settings.senderPassword)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section("收件者設定") {
                    TextField("收件者信箱", text: $viewModel.settings.recipientEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .navigationTitle("App 設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("完成") { dismiss() }
            }
        }
        .preferredColorScheme(.dark)
    }
}
