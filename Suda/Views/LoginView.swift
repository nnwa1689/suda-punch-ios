//
//  LoginView.swift
//  TestAPP
//
//  Created by Hazuya on 2025/12/25.
//
import SwiftUI

struct LoginView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var viewModel = LoginViewModel()
    @State private var protocolSelection = "https://"
    let protocols = ["https://", "http://"]
    
    // 定義主色調
    let primaryBlue = Color(red: 0.11, green: 0.53, blue: 0.94) // #1C87EF
    let textFieldBg = Color(red: 0.92, green: 0.94, blue: 0.96) // 淺藍灰色背景

    var body: some View {
        //@Bindable var viewModel = viewModel
        
        VStack(spacing: 25) {
            Spacer()
            
            // 1. Logo (這裡用圖示代替，你可以換成你的 Image)
            ZStack {
                Image("Suda")
                    .resizable()
                    .scaledToFit()
            }
            
            // 2. 標題
            Text("速打 - 快速搞定打卡大小事")
                .font(.headline)
                .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.6))
                .bold()
                .padding(10)
            
            // 3. 輸入框組
            VStack(spacing: 15) {
                HStack(spacing: 0) {
                    CustomProtocolPicker(selection: $protocolSelection)
                        .frame(width: 120)

                    CustomTextField(placeholder: "API連線伺服器", text: $viewModel.serverAddress)
                        .textInputAutocapitalization(.never) // 關閉自動大寫 (iOS 15+)
                        .disableAutocorrection(true) // 關閉自動校正
                        .keyboardType(.URL)
                }

                CustomTextField(placeholder: "請輸入帳號", text: $viewModel.username)
                CustomSecureField(placeholder: "請輸入密碼", text: $viewModel.password)
            }
            
            // 5. 登入按鈕
            Button(action: {
                Task { await viewModel.startLoginProcess(protocolPrefix: protocolSelection) }
            }) {
                if viewModel.isLoading {
                    ProgressView() // 顯示轉圈圈
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("登入")
                        .font(.headline)
                }
            }
            .disabled(viewModel.isLoading)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(primaryBlue)
            .cornerRadius(25)
            
            Spacer()
            
            // 6. 底部資訊
            VStack(spacing: 8) {
                Text("Suda - 速打打卡系統")
                Text("幫您快速完成打卡大小事")
                HStack(spacing: 10) {
                    Link("條款", destination: URL(string: "https://studio-44s.tw")!)
                    Text("·")
                    Link("官方網站", destination: URL(string: "https://studio-44s.tw/")!)
                    Text("·")
                    Link("幫助", destination: URL(string: "https://studio-44s.tw/")!)
                }
                .font(.footnote)
            }
            .foregroundColor(.secondary)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 30)
        .background(Color(red: 0.97, green: 0.98, blue: 0.99).ignoresSafeArea())
        .alert("提示", isPresented: $viewModel.showAlert){
            Button("確定", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("確定綁定此裝置？", isPresented: $viewModel.showBindAlert) {
            Button("取消", role: .cancel) {
                // 使用者按取消，可以在這裡決定是否強行登入或登出
            }
            Button("確定", role: .confirm) {
                Task {
                    await viewModel.confirmBinding(modelContext: modelContext)
                    
                    if viewModel.isLoginSuccess {
                        withAnimation(.spring()) { // 加入平滑轉場動畫
                            appState.isLoggedIn = true
                        }
                        print("Is Logged In: \(appState.isLoggedIn)")
                    }
                }
            }
        } message: {
            Text("請確認是否將此裝置作為您的打卡裝置。")
        }
    }
}

// MARK: - 子元件與樣式

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color(red: 0.92, green: 0.94, blue: 0.96))
            .cornerRadius(15)
    }
}

struct CustomSecureField: View {
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        SecureField(placeholder, text: $text)
            .padding()
            .background(Color(red: 0.92, green: 0.94, blue: 0.96))
            .cornerRadius(15)
    }
}

struct CustomProtocolPicker: View {
    @Binding var selection: String
    let protocols = ["https://", "http://"]
    
    var body: some View {
        Picker("", selection: $selection) {
            ForEach(protocols, id: \.self) { proto in
                Text(proto).tag(proto)
            }
        }
        .pickerStyle(.menu)
        .padding(.vertical, 10) // 調整與輸入框高度一致
        .padding(.horizontal, 10)
        .background(Color(red: 0.92, green: 0.94, blue: 0.96))
        .cornerRadius(15)
        .accentColor(.primary) // 讓箭頭顏色跟隨系統
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(configuration.isOn ? .blue : .gray.opacity(0.3))
        }
    }
}

#Preview{
    LoginView()
}
