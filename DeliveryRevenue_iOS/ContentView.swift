import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject var viewModel = MainViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showSettings = false
    
    // 定義主色調
    let mainPurple = Color(red: 0.4, green: 0.2, blue: 0.6)
    let accentOrange = Color.orange
    
    // 控制彈出視窗
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // 存放使用者手動滾輪選取的日期
    @State private var manualSelectedDate = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea() // 背景全黑
                
                VStack {
                    // 1. 圖片清單區 (拆分出來降低編譯器負擔)
                    imageListArea
                    
                    // 2. 底部按鈕與統計區 (拆分出來)
                    bottomControlArea
                }
            }
            .navigationTitle("外送營業額")
            .toolbar {
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(mainPurple)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
            }
            // 修改 onChange 寫法，適應較新的 iOS 版本，避免編譯器卡死
            .onChange(of: selectedItems) { oldValue, newValue in
                handlePickerSelection()
            }
            .onChange(of: viewModel.emailState) { oldValue, newValue in
                switch newValue {
                case .success:
                    alertTitle = "寄送成功！"
                    alertMessage = "營業額報告已經順利寄出。"
                    showAlert = true
                    viewModel.resetEmailState() // 恢復按鈕狀態
                case .error(let errorMsg):
                    alertTitle = "寄送失敗"
                    alertMessage = "發生錯誤：\n\(errorMsg)\n\n請檢查「設定」中的信箱與16位數密碼是否正確（請勿包含空白）。"
                    showAlert = true
                    viewModel.resetEmailState() // 恢復按鈕狀態
                default:
                    break
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            // 強迫整個主畫面進入深色模式，滾輪的字就會變成清脆的白色！
            .preferredColorScheme(.dark)
        }
    }
    
    // ─── 子視圖區塊 (Sub-Views) ───
    
    @ViewBuilder
    private var imageListArea: some View {
        if viewModel.imageItems.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("尚未加入圖片")
                    .foregroundColor(.gray)
            }
            .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(viewModel.imageItems) { item in
                        ImageRow(item: item) {
                            viewModel.removeImage(id: item.id)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    @ViewBuilder
    private var bottomControlArea: some View {
        VStack(spacing: 15) {
            // 狀態統計卡片
            if case let .done(total, count, date, _, _) = viewModel.appState {
                summaryCard(total: total, count: count, detectedDate: date)
            }
            
            // 動作按鈕
            HStack(spacing: 15) {
                PhotosPicker(selection: $selectedItems, matching: .images) {
                    HStack {
                        Image(systemName: "plus")
                        Text("新增圖片")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(white: 0.1))
                    .foregroundColor(accentOrange)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentOrange, lineWidth: 1))
                }
                
                Button(action: { viewModel.clearAll() }) {
                    Image(systemName: "trash")
                        .padding()
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func summaryCard(total: Double, count: Int, detectedDate: String?) -> some View {
        VStack(spacing: 15) {
            
            // 👇 如果系統抓不到日期，展開警告與滾輪選擇器
            if detectedDate == nil {
                VStack(spacing: 5) {
                    Text("⚠️ 偵測不到日期，請手動輸入")
                        .font(.subheadline).bold()
                        .foregroundColor(.red)
                    
                    // 這就是你要的 iOS 鬧鐘滾輪樣式！
                    DatePicker("", selection: $manualSelectedDate, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 120) // 限制高度，不會佔用太多畫面
                        .clipped()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.top, 10)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("總交易金額")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("NT$ \(String(format: "%.0f", total))")
                        .font(.title).bold()
                        .foregroundColor(accentOrange)
                    
                    // 顯示最終決定的回報日期與筆數
                    if let d = detectedDate {
                        Text("\(d) (\(count) 筆)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        // 強調顯示使用者手動選擇的日期
                        Text("回報日期：\(formattedManualDate) (\(count) 筆)")
                            .font(.caption)
                            .foregroundColor(accentOrange)
                    }
                }
                Spacer()
                
                Button(action: {
                    // 按下發送時，如果抓不到日期，就把手選的日期傳給總司令
                    viewModel.sendEmail(manualDate: detectedDate == nil ? manualSelectedDate : nil)
                }) {
                    HStack {
                        if viewModel.emailState == .sending {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("寄送報告")
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 12)
                    .background(mainPurple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(white: 0.15))
        .cornerRadius(16)
    }
    
    // ─── 邏輯處理區塊 ───
    
    // 處理選取圖片
    private func handlePickerSelection() {
        for item in selectedItems {
            item.loadTransferable(type: Data.self) { result in
                switch result {
                case .success(let data):
                    if let data = data, let uiImage = UIImage(data: data) {
                        DispatchQueue.main.async {
                            viewModel.addImage(image: uiImage, imageData: data)
                            viewModel.processImages()
                        }
                    }
                case .failure: break
                }
            }
        }
        selectedItems = []
    }
    
    // 格式化手動選擇的日期供畫面顯示
    private var formattedManualDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: manualSelectedDate)
    }
    
}



    // 圖片卡片組件
    struct ImageRow: View {
        let item: ImageItem
        let onDelete: () -> Void
        
        var body: some View {
            HStack(spacing: 15) {
                Image(uiImage: item.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .clipped()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.date ?? "讀取中...")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    if item.isProcessed {
                        if let error = item.error {
                            Text(error).font(.caption).foregroundColor(.red)
                        } else {
                            Text("NT$ \(String(format: "%.0f", item.extractedAmounts.reduce(0, +))) (\(item.extractedAmounts.count) 筆)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        ProgressView().tint(.gray)
                    }
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "xmark").foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(white: 0.1))
            .cornerRadius(12)
        }
    }
