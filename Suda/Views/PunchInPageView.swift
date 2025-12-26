//
//  PunchInPageView.swift
//  Suda
//
//  Created by Hazuya on 2025/12/27.
//

import SwiftUI

struct PunchInPageView: View {
    @State private var viewModel = MainHomeViewModel()
    let bgColor = Color(red: 0.97, green: 0.98, blue: 0.99)
    let cardBgColor = Color(red: 0.92, green: 0.94, blue: 0.96)

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
                        Text("今日工作時間").font(.title3.bold())
                        HStack {
                            Text("應打卡時間").foregroundColor(.gray)
                            Spacer()
                            Text(viewModel.expectedPunchTime)
                        }
                        
                        // 地點選擇器
                        Menu {
                            ForEach(viewModel.locations, id: \.self) { loc in
                                Button(loc) { viewModel.selectedLocation = loc }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.selectedLocation)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down").font(.caption)
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
                        .background(cardBgColor).foregroundColor(.black).cornerRadius(15)
                }
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 30) // 留一點空間給 TabBar
        }
        .background(bgColor.ignoresSafeArea())
    }
}
