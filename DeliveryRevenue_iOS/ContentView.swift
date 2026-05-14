// create by rabisu

import SwiftUI

struct ContentView: View {
    @StateObject private var sharedViewModel = MainViewModel()
    @State private var isMenuOpen = false
    @State private var selectedFeature: AppFeature = .dailyReport
    // 第一個畫面為日營業額回報，而非未入機加總 .unrecordedTotal
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                Color.black.ignoresSafeArea()
                
                // 根據選擇的功能顯示對應畫面
                Group {
                    switch selectedFeature {
                    case .unrecordedTotal:
                        UnrecordedTotalView().environmentObject(sharedViewModel)
                    case .dailyReport:
                        DailyReportView(selectedFeature: $selectedFeature).environmentObject(sharedViewModel)
                    }
                }
                .disabled(isMenuOpen) // 選單打開時禁用主畫面點擊
                
                // 側滑選單遮罩 (點擊空白處關閉選單)
                if isMenuOpen {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation { isMenuOpen = false }
                        }
                }
                
                // 側滑選單本體
                HStack {
                    SidebarView(selectedFeature: $selectedFeature, isMenuOpen: $isMenuOpen)
                        .offset(x: isMenuOpen ? 0 : -270)
                    Spacer()
                }
            }
            .navigationTitle(selectedFeature.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 左邊的漢堡選單按鈕
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.spring()) { isMenuOpen.toggle() }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.orange)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
