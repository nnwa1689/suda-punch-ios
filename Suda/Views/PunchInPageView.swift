//
//  PunchInPageView.swift
//  Suda
//
//  Created by Hazuya on 2025/12/27.
//

import SwiftUI

struct PunchInPageView: View {
    @State private var viewModel: PunchInPageViewModel
    //let bgColor = Color(red: 0.97, green: 0.98, blue: 0.99)
    //let cardBgColor = Color(red: 0.92, green: 0.94, blue: 0.96)
    
    init(auth: AuthData) {
        // 初始化 State 包裝的 ViewModel
        _viewModel = State(initialValue: PunchInPageViewModel(auth: auth))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 30) {
                    // --- 1. 時間顯示 ---
                    VStack(spacing: 10) {
                        Text(viewModel.currentTime)
                            .font(.system(size: 48, weight: .bold))
                        Text(viewModel.currentDate)
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    
                    // --- 2. 今日工作時間區 ---
                    VStack(alignment: .leading, spacing: 15) {
                        Text("今日工作班別").font(.title3.bold())
                        HStack {
                            Text("本日班別")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(viewModel.scheduleName)
                                .fontWeight(.bold)
                                .foregroundColor(.blue) // 增加醒目度
                        }
                        
                        HStack {
                            Text("上班應打卡時間").foregroundColor(.gray)
                            Spacer()
                            Text(viewModel.expectedPunchTime)
                        }
                        
                        HStack {
                            Text("下班應打卡時間").foregroundColor(.gray)
                            Spacer()
                            Text(viewModel.expectedPunchTimeOut)
                        }
                        
                        // 地點選擇器
                        Menu {
                            // 檢查是否有地點資料，若無則顯示提示
                                if viewModel.punchPoints.isEmpty {
                                    Button("讀取中...") { }
                                        .disabled(true)
                                } else {
                                    ForEach(viewModel.punchPoints) { point in
                                        Button {
                                            // 選中後更新選中的物件
                                            viewModel.selectedPoint = point
                                        } label: {
                                            HStack {
                                                Text(point.name)
                                                if viewModel.selectedPoint?.id == point.id {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                }
                        } label: {
                            HStack {
                                    // 顯示目前選中的地點名稱，如果還沒選到則顯示預設文字
                                    Text(viewModel.selectedPoint?.name ?? "請選擇打卡地點")
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    // 箭頭圖示
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        }
                        .foregroundColor(.primary)
                    }
                    
                    // --- 3. 上次打卡時間區 ---
                    VStack(alignment: .leading, spacing: 15) {
                        Text("上次打卡時間").font(.title3.bold())
                        VStack(spacing: 12) {
                            HStack {
                                Text("時間").foregroundColor(.gray)
                                Spacer()
                                Text(viewModel.lastPunchTime)
                            }
                            HStack {
                                Text("地點").foregroundColor(.gray)
                                Spacer()
                                Text(viewModel.lastPunchLocation)
                            }
                        }
                    }
                }
                .padding(25)
            }
            
            // --- 4. 打卡按鈕 ---
            VStack(spacing: 15) {
                Button(action: { viewModel.performPunchIn() }) {
                    Text("上班打卡")
                        .font(.headline).bold()
                        .frame(maxWidth: .infinity).frame(height: 55)
                        .background(Color.blue).foregroundColor(.white).cornerRadius(15)
                }
                
                Button(action: { viewModel.performPunchOut() }) {
                    Text("下班打卡")
                        .font(.headline).bold()
                        .frame(maxWidth: .infinity).frame(height: 55)
                        .background(Color.cardBgColor).foregroundColor(.black).cornerRadius(15)
                }
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 30) // 留一點空間給 TabBar
        }
        .background(Color.bgColor.ignoresSafeArea())
        .alert("系統提示", isPresented: $viewModel.showAlert) {
            Button("確定", role: .cancel) {
                // 可以在這裡放按下確定後的動作
            }
        } message: {
            Text(viewModel.alertMessage) // 顯示 ViewModel 傳過來的訊息
        }
        .overlay {
            if viewModel.isPunching {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("正在驗證位置...")
                            .foregroundColor(.white)
                    }
                    .padding(30)
                    .background(.secondary)
                    .cornerRadius(15)
                }
            }
        }
    }
}
