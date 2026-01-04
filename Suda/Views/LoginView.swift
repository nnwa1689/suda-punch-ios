//
//  LoginView.swift
//  TestAPP
//
//  Created by Hazuya on 2025/12/25.
//
import SwiftUI

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var viewModel = LoginViewModel()
    @State private var protocolSelection = "https://"
    let protocols = ["https://", "http://"]

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
            
            // 3. 輸入框組
            VStack(spacing: 15) {
                HStack(spacing: 0) {
                    // 左側：協定選擇器 (http/https)
                    CustomProtocolPicker(selection: $protocolSelection)
                        .frame(width: 130) // 調整寬度使其更緊湊
                        .fixedSize(horizontal: true, vertical: false)
                        .background(Color.cardBgColor) // 稍微區隔選擇區域
                    
                    // 分隔線
                    Divider()
                        .frame(height: 24)
                    
                    // 右側：網址輸入
                    CustomTextField(iconName: "link", placeholder: "連線網址", text: $viewModel.serverAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                        .padding(.leading, 10)
                }
                // ✅ 這裡設定整體的樣式，讓它們看起來像一個框
                //.frame(height: 50)
                .background(Color.cardBgColor)
                .clipShape(RoundedRectangle(cornerRadius: 15))


                CustomTextField(iconName: "person.fill", placeholder: "請輸入帳號", text: $viewModel.username)
                CustomSecureField(iconName: "lock.fill", placeholder: "請輸入密碼", text: $viewModel.password)
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
            .background(Color.primaryBlue)
            .cornerRadius(25)
            
            Spacer()
            
            // 6. 底部資訊
            VStack(spacing: 8) {
                HStack {
                    // 使用「+」號將不同樣式的 Text 串接起來
                    Text("Su")
                        .foregroundColor(Color.primaryBlue) // 水藍色（可改用 Color(red: 0.3, green: 0.7, blue: 1.0) 調整更淡的水藍）
                    +
                    Text("da")
                        .foregroundColor(Color.textPrimary) // 灰色
                    +
                    Text(" 速打 - 快速打卡好輕鬆")
                        .foregroundColor(Color.textPrimary) // 跟隨系統的文字顏色
                }
                .font(.headline) // 你可以統一設定字體大小
                HStack(spacing: 10) {
                    Link("條款", destination: URL(string: "https://studio-44s.tw")!)
                    Text("·")
                    Link("官方網站", destination: URL(string: "https://studio-44s.tw/")!)
                    Text("·")
                    Link("幫助", destination: URL(string: "https://studio-44s.tw/")!)
                }
                .font(.footnote)
            }
            .foregroundColor(Color.textSecondary)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 30)
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
        .background(Color.bgColor)
    }
}

// MARK: - 子元件與樣式

struct CustomTextField: View {
    var iconName: String
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.gray.opacity(0.6))
                .frame(width: 20) // 固定寬度讓對齊更整齊
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Color.textSecondary))
                .padding()
                .background(Color.cardBgColor)
                .cornerRadius(15)
                .foregroundColor(Color.textSecondary)
        }
    }
}

struct CustomSecureField: View {
    var iconName: String
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.gray.opacity(0.6))
                .frame(width: 20) // 固定寬度讓對齊更整齊
            SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(Color.textSecondary))
                .padding()
                .background(Color.cardBgColor)
                .cornerRadius(15)
        }
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
        .background(Color.cardBgColor)
        .cornerRadius(15)
        .accentColor(Color.textSecondary) // 讓箭頭顏色跟隨系統
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
