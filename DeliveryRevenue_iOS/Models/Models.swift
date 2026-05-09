//
//  Models.swift
//  DeliveryRevenue_iOS
//
//  Created by rabisu on 2026/5/9.
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
    let id = UUID()
    let image: UIImage
    let date: String?
    var extractedAmounts: [Double] = []
    var rawText: String = ""
    var isProcessed: Bool = false
    var error: String? = nil
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
