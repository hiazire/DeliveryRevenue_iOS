//  負責執行邏輯的大腦
//  MainViewModel.swift
//  DeliveryRevenue_iOS
//
//  Created by rabisu on 2026/5/9.
//

import Foundation
import SwiftUI
import Combine
import Photos

@MainActor // 確保所有狀態更新都在主執行緒 (Main Thread)，避免畫面卡頓或崩潰
class MainViewModel: ObservableObject {
    
    @Published var settings: AppSettings {
        didSet { saveSettings() } // 當設定有變更時，自動存檔
    }
    
    @Published var imageItems: [ImageItem] = []
    @Published var appState: AppState = .idle
    @Published var emailState: EmailState = .idle
    
    init() {
        // App 啟動時，從手機本地儲存空間讀取設定檔 (包含信箱與密碼)
        if let data = UserDefaults.standard.data(forKey: "AppSettings"),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = AppSettings()
        }
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "AppSettings")
        }
    }
    
    // ── 圖片清單管理 ───────────────────────────────────────────
    func addImage(image: UIImage, imageData: Data, assetIdentifier: String? = nil) {
        // EXIF 日期抓取邏輯
        let date = ExifUtil.extractDate(from: imageData)
        
        // 建立 Item 時，同時帶入日期與身分證字號
        let newItem = ImageItem(
            image: image,
            date: date,
            assetIdentifier: assetIdentifier
        )
        
        imageItems.append(newItem)
        
        // 狀態重置邏輯
        appState = .idle
        emailState = .idle
    }
    
    func removeImage(id: UUID) {
        imageItems.removeAll { $0.id == id }
        if imageItems.isEmpty { appState = .idle }
    }
    
    func clearAll() {
        imageItems.removeAll()
        appState = .idle
        emailState = .idle
    }
    
    // 專門執行刪除的函式
    func deleteProcessedPhotos(completion: @escaping (Bool) -> Void) {
        // 篩選出：已經辨識完畢 (isProcessed) 且 帶有身分證 (assetIdentifier) 的項目
        let identifiers = imageItems
            .filter { $0.isProcessed }
            .compactMap { $0.assetIdentifier }

        guard !identifiers.isEmpty else {
            completion(false)
            return
        }

        // 請求權限並執行刪除
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            let assetsToDelete = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assetsToDelete)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        // 刪除成功後，記得清空 App 裡的清單
                        self.imageItems.removeAll(where: { item in
                            item.isProcessed && item.assetIdentifier != nil
                        })
                    }
                    completion(success)
                }
            }
        }
    }

    func deleteUploadedPhotosFromDevice() {
        let ids = imageItems.compactMap { $0.assetIdentifier }
        guard !ids.isEmpty else { return }
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { s in
            guard s == .authorized || s == .limited else { return }
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
            PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.deleteAssets(assets) }) { _, _ in
                DispatchQueue.main.async { self.clearAll() }
            }
        }
    }

    // ── 核心處理邏輯 ───────────────────────────────────────────
    
    func processImages() {
        if imageItems.isEmpty { return }
        appState = .processing
        
        Task {
            var processedItems: [ImageItem] = []
            
            // 逐張處理圖片
            for item in self.imageItems {
                var mutableItem = item
                
                // 🚀 效能大躍進：只有當這張圖片「還沒被辨識過」時，才執行耗時的 OCR 運算
                if !mutableItem.isProcessed {
                    do {
                        let (amounts, rawText) = try await OcrProcessor.extractAmounts(from: mutableItem.image)
                        // 讓 Xcode 把原始文字印在底部的黑色除錯視窗
                        print("==== 圖片 OCR 原始文字 ====")
                        print(rawText)
                        mutableItem.extractedAmounts = amounts
                        mutableItem.rawText = rawText
                        mutableItem.isProcessed = true
                        mutableItem.error = amounts.isEmpty ? "未偵測到金額" : nil
                    } catch {
                        mutableItem.isProcessed = true
                        mutableItem.error = error.localizedDescription
                    }
                }
                processedItems.append(mutableItem)
            }
            
            self.imageItems = processedItems
            
            // 計算總金額與總筆數
            let total = processedItems.flatMap { $0.extractedAmounts }.reduce(0, +)
            let totalCount = processedItems.reduce(0) { $0 + $1.extractedAmounts.count }
            
            let dates = Set(processedItems.compactMap { $0.date })
            let hasConflict = dates.count > 1
            let primaryDate = hasConflict ? nil : dates.first
            
            let details = processedItems.map { "• 圖片: \($0.date ?? "無日期資訊")" }.joined(separator: "\n")
            
            self.appState = .done(
                totalAmount: total,
                totalTransactionCount: totalCount,
                primaryDate: primaryDate,
                hasConflict: hasConflict,
                details: details
            )
        }
    }
    
    // ── 寄信邏輯 ──────────────────────────────────────────────
    // 讓函式可以接收畫面的手動日期參數
    func sendEmail(manualDate: Date? = nil) {
        guard case let .done(totalAmount, totalCount, primaryDate, hasConflict, details) = appState else { return }
        
        emailState = .sending
        Task {
            do {
                if hasConflict {
                    try await EmailSender.sendErrorEmail(cfg: settings, details: details)
                } else {
                    // 決定最終要寄送的日期
                    let finalDateString: String
                    
                    if let autoDate = primaryDate {
                        finalDateString = autoDate // 優先使用系統抓到的日期
                    } else if let chosenDate = manualDate {
                        // 系統抓不到，改用使用者滾輪選的日期
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy/MM/dd"
                        finalDateString = formatter.string(from: chosenDate)
                    } else {
                        throw NSError(domain: "Mail", code: 1, userInfo: [NSLocalizedDescriptionKey: "無法取得寄送日期，請手動選擇"])
                    }
                    
                    try await EmailSender.sendSuccessEmail(
                        cfg: settings,
                        totalAmount: totalAmount,
                        date: finalDateString,
                        count: totalCount
                    )
                }
                self.emailState = .success
            } catch {
                self.emailState = .error(error.localizedDescription)
            }
        }
    }
    
    func resetEmailState() {
        emailState = .idle
    }
}
