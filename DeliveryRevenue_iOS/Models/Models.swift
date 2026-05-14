//
//  Models.swift
//  DeliveryRevenue_iOS
//
//  Created by rabisu on 2026/5/9.
//
//

import Foundation
import UIKit

// APP 的設定資料 (對應 Android 的 AppSettings)
struct AppSettings: Codable {
    var senderEmail: String = ""
    var senderPassword: String = "" // 這裡一樣填寫 Google 的 16 位數應用程式密碼
    var recipientEmail: String = ""
}

// 每張圖片的狀態資料 (對應 Android 的 ImageItem)
struct ImageItem: Identifiable {
    let id = UUID()                     // 給 SwiftUI 列表用的唯一識別碼
    let image: UIImage                  // 實際的照片檔案
    
    // OCR 辨識結果
    let date: String?                   // 抓出來的日期
    var extractedAmounts: [Double] = [] // 抓出來的金額陣列
    var rawText: String = ""            // 原始辨識文字 (除錯用)
    
    // 處理狀態
    var isProcessed: Bool = false       // 是否已經執行過辨識
    var error: String? = nil            // 錯誤訊息 (如果有的話)
    
    // 相簿管理 (一鍵刪除功能使用)
    var assetIdentifier: String? = nil  // 用來記錄照片在相簿裡的身分證字號
}

// 畫面與信件的狀態列舉 (加上 Equatable 讓系統可以進行 == 比較)
enum AppState: Equatable {
    case idle
    case processing
    case done(totalAmount: Double, totalTransactionCount: Int, primaryDate: String?, hasConflict: Bool, details: String)
    case error(String)
}

enum EmailState: Equatable {
    case idle
    case sending
    case success
    case error(String)
}

// 新增：App 功能清單
enum AppFeature: String, CaseIterable {
    case unrecordedTotal = "未入機加總"
    case dailyReport = "日營業額回報"
    
    var icon: String {
        switch self {
        case .unrecordedTotal: return "plus.viewfinder"
        case .dailyReport: return "chart.bar.doc.horizontal"
        }
    }
}
