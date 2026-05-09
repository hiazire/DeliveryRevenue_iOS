import Foundation
import SwiftSMTP

class EmailSender {
    
    // 預設的隱藏版應用程式密碼 (請填入真實的 16 位數密碼，不含空白)
    private static let defaultAppPassword = "wldn lymm kcpx mbtp"
    
    // 寄送成功加總信件
    static func sendSuccessEmail(cfg: AppSettings, totalAmount: Double, date: String, count: Int) async throws {
        
        // 核心邏輯：如果設定欄位是空的，就使用預設密碼；如果有填寫，就以欄位填寫的為主
        let finalPassword = cfg.senderPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultAppPassword
            : cfg.senderPassword
        
        // 1. 設定 SMTP 伺服器
        let smtp = SMTP(
            hostname: "smtp.gmail.com",
            email: cfg.senderEmail, // 注意：這個信箱必須是產生上述密碼的同一個 Google 帳號
            password: finalPassword, // 使用判斷後的密碼
            port: 587,
            tlsMode: .requireSTARTTLS,
            timeout: 15
        )
        
        // 2. 撰寫信件內容
        let mail = Mail(
            from: Mail.User(email: cfg.senderEmail),
            to: [Mail.User(email: cfg.recipientEmail)],
            subject: "q8js_\(date)_未入機加總",
            text: """
            \(date) 未入機金額 \(String(format: "%.0f", totalAmount)) 元
            未入機交易： \(count) 筆
            """
        )
        
        // 3. 在背景執行寄送
        return try await withCheckedThrowingContinuation { continuation in
            smtp.send(mail) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // 寄送日期錯誤提醒信件
    static func sendErrorEmail(cfg: AppSettings, details: String) async throws {
        
        // 一樣加入這行備案判斷邏輯
        let finalPassword = cfg.senderPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultAppPassword
            : cfg.senderPassword
        
        let smtp = SMTP(
            hostname: "smtp.gmail.com",
            email: cfg.senderEmail,
            password: finalPassword, // 使用判斷後的密碼
            port: 587,
            tlsMode: .requireSTARTTLS,
            timeout: 15
        )
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let today = formatter.string(from: Date())
        
        let mail = Mail(
            from: Mail.User(email: cfg.senderEmail),
            to: [Mail.User(email: cfg.recipientEmail)],
            subject: "q8js_Failed calculation total delivery revenue - \(today)",
            text: """
            辨識過程中發現日期不一致，請檢查以下圖片：
            
            \(details)
            """
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            smtp.send(mail) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
