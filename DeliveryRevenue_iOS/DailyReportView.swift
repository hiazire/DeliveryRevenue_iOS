//
//  DailyReportView.swift
//  DeliveryRevenue_iOS
//
//  Created by rabisu.
//

import SwiftUI

// 支出項目的資料結構
struct ExpenseItem: Identifiable {
    let id = UUID()
    var category: String
    var amount: String
}

struct DailyReportView: View {
    // ─── 跨畫面共享與跳轉 ───
    @Binding var selectedFeature: AppFeature
    @EnvironmentObject var sharedViewModel: MainViewModel
    
    // ─── 使用者輸入狀態 ───
    @State private var reportDate = Date()
    @State private var importedDeliveryTotal: String = "" // 外送加總欄位
    @State private var iposRevenue: String = ""
    @State private var iposCash: String = ""
    @State private var registerCash: String = ""
    @State private var deliveryRevenue: String = ""
    
    // 支出項目的動態陣列
    @State private var expenses: [ExpenseItem] = []
    
    // 支出下拉選單選項
    let expenseCategories = [
        "忠", "元味堂", "聖源糧行", "菜市場", "瓦斯GAS",
        "阿潭果菜", "環境清消", "自由時報", "豆漿", "戀職人鮮乳",
        "柳橙汁", "旺旺來", "好樂洗", "熱感應紙", "其他"
    ]
    
    let accentOrange = Color.orange
    
    var body: some View {
        Form {
            // 區塊 1：日期與外送資料帶入
            Section {
                DatePicker("回報日期", selection: $reportDate, displayedComponents: .date)
                
                if case let .done(totalAmount, _, _, _, _) = sharedViewModel.appState {
                    HStack {
                        Text("未入機外送總計")
                        Spacer()
                        Text("NT$ \(Int(totalAmount))")
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                        Button("帶入") {
                            importedDeliveryTotal = String(Int(totalAmount))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                } else {
                    HStack {
                        if deliveryRevenue.isEmpty {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                        } else {
                            Text("外送訂單")
                        }

                        TextField("手動輸入或前往計算", text: $deliveryRevenue)
                            .keyboardType(.numberPad)
                            .foregroundColor(deliveryRevenue.isEmpty ? .gray : .primary)

                        Spacer()

                        Button("前往計算") {
                            withAnimation { selectedFeature = .unrecordedTotal }
                        }
                        .foregroundColor(.orange)
                        .font(.subheadline)
                    }
                }
            }
            
            // 區塊 2：主要營業數據
            Section(header: Text("營業數據 (單位: 元)")) {
                HStack {
                    Text("外送加總帶入")
                    Spacer()
                    // 已修改提示文字為「輸入金額」，且支援手動輸入與數字鍵盤
                    TextField("輸入金額", text: $importedDeliveryTotal)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.orange)
                }
                
                HStack {
                    Text("iPOS營業額")
                    Spacer()
                    TextField("輸入金額", text: $iposRevenue)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("iPOS現金額 (應收)")
                    Spacer()
                    TextField("輸入金額", text: $iposCash)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("收銀機現金")
                    Spacer()
                    TextField("輸入金額", text: $registerCash)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            // 區塊 3：支出項目 (動態新增/刪除)
            Section(
                header: HStack {
                    Text("支出項目")
                    Spacer()
                    Button(action: {
                        expenses.append(ExpenseItem(category: "忠", amount: ""))
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(accentOrange)
                            .font(.title3)
                    }
                }
            ) {
                if expenses.isEmpty {
                    Text("目前無支出項目")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ForEach($expenses) { $expense in
                        HStack {
                            // 下拉選單：設定寬度確保 8 字串不被切斷
                            Picker("", selection: $expense.category) {
                                ForEach(expenseCategories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                            .labelsHidden()
                            .frame(minWidth: 160, maxWidth: 180, alignment: .leading)
                            
                            Divider()
                            
                            TextField("輸入金額", text: $expense.amount)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .onDelete(perform: deleteExpense) // 支援向左滑動刪除
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    private func deleteExpense(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
    }
}

#Preview {
    DailyReportView(selectedFeature: .constant(.dailyReport))
        .environmentObject(MainViewModel())
        .preferredColorScheme(.dark)
}
