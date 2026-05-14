// DailyReportView.swift 預留區
// 20260514 by rabisu

import SwiftUI

// 定義支出項目的資料結構
struct ExpenseItem: Identifiable {
    let id = UUID()
    var category: String
    var amount: String // 用 String 儲存以配合 TextField，計算時再轉 Int
}

struct DailyReportView: View {
    // ─── 使用者輸入的狀態 ───
    @Binding var selectedFeature: AppFeature
    @EnvironmentObject var sharedViewModel: MainViewModel
    @State private var reportDate = Date()
    @State private var importedDeliveryTotal: String = ""
    @State private var iposRevenue: String = ""
    @State private var iposCash: String = ""
    @State private var registerCash: String = ""

    // 支出項目的動態陣列
    @State private var expenses: [ExpenseItem] = []

    // 支出下拉選單的選項
    let expenseCategories = [
        "忠", "元味堂", "聖源糧行", "菜市場", "瓦斯GAS",
        "阿潭果菜", "環境清消", "自由時報", "豆漿", "戀職人鮮乳",
        "柳橙汁", "旺旺來", "好樂洗", "熱感應紙", "其他"
    ]

    let accentOrange = Color.orange

    // ─── 背景運算資料 (目前不顯示，未來使用) ───
    var totalExpenseAmount: Int {
        expenses.compactMap { Int($0.amount) }.reduce(0, +)
    }

    var actualCash: Int {
        (Int(registerCash) ?? 0) + totalExpenseAmount
    }

    var shortageOrOverage: Int {
        actualCash - (Int(iposCash) ?? 0)
    }
    // ─────────────────────────────────────

    var body: some View {
        Form {
            // 區塊 0：日期與外送加總
            Section {
                DatePicker("回報日期", selection: $reportDate, displayedComponents: .date)
                if case let .done(totalAmount, _, _, _, _) = sharedViewModel.appState {
                    HStack {
                        Text("未入機外送總計")
                        Spacer()
                        Text("NT$ \(Int(totalAmount))").foregroundColor(.green).fontWeight(.bold)
                        Button("帶入") { importedDeliveryTotal = String(Int(totalAmount)) }
                            .buttonStyle(.borderedProminent).tint(.orange)
                    }
                } else {
                    HStack {
                        Text("⚠️ 尚未計算外送訂單").foregroundColor(.gray)
                        Spacer()
                        Button("前往計算") { withAnimation { selectedFeature = .unrecordedTotal } }.foregroundColor(.orange).fontWeight(.bold)
                    }
                }
            }

            // 區塊 1：主要營業數據
            Section(header: Text("營業數據 (單位: 元)")) {
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

                // 外送加總帶入
                HStack {
                    Text("外送加總帶入")
                    Spacer()
                    TextField("由上方按鈕帶入", text: $importedDeliveryTotal)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.orange)
                }
            }

            // 區塊 2：支出項目 (動態新增)
            Section(
                header: HStack {
                    Text("支出項目")
                    Spacer()
                    // 右側的新增按鈕
                    Button(action: {
                        // 預設新增一筆分類為"忠"，金額為空的項目
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
                    List {
                        // 使用索引綁定來支援雙向綁定 (選擇分類與輸入金額)
                        ForEach($expenses) { $expense in
                            HStack {
                                // 下拉式選單
                                Picker("", selection: $expense.category) {
                                    ForEach(expenseCategories, id: \.self) { category in
                                        Text(category).tag(category)
                                    }
                                }
                                .labelsHidden()
                                .frame(minWidth: 160, maxWidth: 180, alignment: .leading)

                                Divider()

                                // 金額輸入框
                                TextField("輸入金額", text: $expense.amount)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        // 支援原生向左滑動刪除手勢
                        .onDelete(perform: deleteExpense)
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively) // 讓使用者滑動時可收起鍵盤
    }

    // 處理刪除的函式
    private func deleteExpense(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
    }
}

#Preview {
    DailyReportView(selectedFeature: .constant(.dailyReport))
        .environmentObject(MainViewModel())
        .preferredColorScheme(.dark)
}