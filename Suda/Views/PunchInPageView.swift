//
//  PunchInPageView.swift
//  Suda
//
//  Created by Hazuya on 2025/12/27.
//

import SwiftUI
import SwiftData

struct PunchInPageView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var viewModel: PunchInPageViewModel
    @State private var showPicker = false // 控制彈窗顯示的狀態
    
    init(auth: AuthData) {
        // 初始化 State 包裝的 ViewModel
        _viewModel = State(initialValue: PunchInPageViewModel(auth: auth))
    }

    var body: some View {
        Group {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 30) {
                        // --- 1. 時間顯示 ---
                        VStack(spacing: 10) {
                            Text(viewModel.currentTime)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(Color.textPrimary)
                            Text(viewModel.currentDate)
                                .font(.headline)
                                .foregroundColor(Color.textSecondary)
                        }
                        .padding(.top, 40)
                        
                        // --- 2. 今日工作時間區 ---
                        VStack(alignment: .leading, spacing: 15) {
                            Text("今日工作班別").font(.title3.bold()).foregroundColor(Color.textPrimary)
                            HStack {
                                Text("本日班別")
                                    .foregroundColor(Color.textSecondary)
                                Spacer()
                                Text(viewModel.scheduleName)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.primaryBlue) // 增加醒目度
                            }
                            
                            HStack {
                                Text("上班應打卡時間").foregroundColor(Color.textSecondary)
                                Spacer()
                                Text(viewModel.expectedPunchTime).foregroundColor(Color.textSecondary)
                            }
                            
                            HStack {
                                Text("下班應打卡時間").foregroundColor(Color.textSecondary)
                                Spacer()
                                Text(viewModel.expectedPunchTimeOut).foregroundColor(Color.textSecondary)
                            }
                            
                            PunchPointSelectionRow(
                                selectedPointName: viewModel.selectedPoint?.name
                            ) {
                                showPicker = true
                            }
                            .padding(.horizontal)
                            .sheet(isPresented: $showPicker) {
                                PunchPointPickerView(
                                    points: viewModel.punchPoints,
                                    selectedPoint: $viewModel.selectedPoint
                                )
                                .presentationDetents([.medium, .large])
                            }
                        }
                        
                        // --- 3. 上次打卡時間區 ---
                        VStack(alignment: .leading, spacing: 15) {
                            Text("上次打卡時間").font(.title3.bold()).foregroundColor(Color.textPrimary)
                            VStack(spacing: 12) {
                                HStack {
                                    Text("時間").foregroundColor(Color.textSecondary)
                                    Spacer()
                                    Text(viewModel.lastPunchTime).foregroundColor(Color.textSecondary)
                                }
                                HStack {
                                    Text("地點").foregroundColor(Color.textSecondary)
                                    Spacer()
                                    Text(viewModel.lastPunchLocation).foregroundColor(Color.textSecondary)
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
                            .background(Color.primaryBlue).foregroundColor(.white).cornerRadius(15)
                    }
                    
                    Button(action: { viewModel.performPunchOut() }) {
                        Text("下班打卡")
                            .font(.headline).bold()
                            .frame(maxWidth: .infinity).frame(height: 55)
                            .background(Color.cardBgColor).foregroundColor(.black).cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1) // 淺灰色、寬度為 1 的外框
                            )
                    }
                }
                .onDisappear { viewModel.stopBluetoothScan() }
                .padding(.horizontal, 25)
                .padding(.bottom, 30) // 留一點空間給 TabBar
            }
            .alert("系統提示", isPresented: $viewModel.showAlert) {
                Button("確定", role: .cancel) {
                    // 可以在這裡放按下確定後的動作
                }
            } message: {
                Text(viewModel.alertMessage) // 顯示 ViewModel 傳過來的訊息
            }
            .overlay {
                if viewModel.isPunchingBluetooth {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        VStack(spacing: 15) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("正在驗證實體打卡裝置...")
                                .foregroundColor(.white)
                        }
                        .padding(30)
                        .background(.secondary)
                        .cornerRadius(15)
                    }
                } else if viewModel.isPunching {
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
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    print("App 回到前台，重新同步時間")
                    Task {
                        await viewModel.fetchInitialServerTime()
                    }
                }
            }
        }
        .background(Color.bgColor.ignoresSafeArea())
    }
}

struct PunchPointSelectionRow: View {
    let selectedPointName: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                
                // 簡化邏輯：將邏輯判斷結果直接帶入
                Text(selectedPointName ?? "請選擇打卡地點")
                    .fontWeight(.medium)
                    .foregroundColor(selectedPointName == nil ? .gray : .black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PunchPointPickerView: View {
    let points: [PunchPoint]           // 只需要清單資料
    @Binding var selectedPoint: PunchPoint? // 用來回傳選擇結果
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""

    // 搜尋邏輯改用 points
    var filteredPoints: [PunchPoint] {
        if searchText.isEmpty { return points }
        return points.filter { point in
            // 無視大小寫
            point.name.localizedCaseInsensitiveContains(searchText) ||
            point.id.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                // 1. 強制指定 id 並確保 filteredPoints 是 [PunchPoint]
                ForEach(filteredPoints, id: \.id) { (point: PunchPoint) in
                    Button(action: {
                        selectedPoint = point
                        dismiss()
                    }) {
                        // 2. 這裡一定要用一個容器 (如 HStack 或 VStack) 包起來
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(point.name)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text("代號：\(point.id)")
                                    .font(.caption)
                                    .foregroundColor(Color.textSecondary)
                            }
                            Spacer()
                            
                            // 3. 顯示目前勾選狀態 (選選優化)
                            if selectedPoint?.id == point.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.primary)
                            }
                        }
                        .contentShape(Rectangle()) // 讓整列都可點擊
                    }
                }
                if filteredPoints.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView {
                        Label("找不到打卡點", systemImage: "mappin.slash.circle")
                    } description: {
                        Text("找不到任何可用的打卡點\n請確認網路連線或搜尋條件")
                    }
                }
            }
            .navigationTitle("選擇打卡點")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜尋打卡點名稱或代號")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") { dismiss() }
                }
            }
        }
    }
}
