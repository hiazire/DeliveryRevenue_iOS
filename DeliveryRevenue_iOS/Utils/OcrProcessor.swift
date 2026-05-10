//
//  OcrProcessor.swift
//  DeliveryRevenue_iOS
//
//  Created by 蘇甫瀚 on 2026/5/9.
//
import Foundation
import Vision
import UIKit

class OcrProcessor {
    
    /// 提取圖片中的所有交易金額
    static func extractAmounts(from image: UIImage) async throws -> (amounts: [Double], rawText: String) {
        // 將 UIImage 轉換為 Vision 支援的 CGImage
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "OcrProcessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "無法讀取圖片格式"])
        }
        
        // 使用 Swift 的併發機制 (async/await) 來處理回呼
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: ([], "無辨識結果"))
                    return
                }
                
                // 執行我們客製化的雷達掃描邏輯
                let amounts = parseAmountsFromGeometry(observations)
                
                // 組合純文字供除錯或紀錄使用
                let rawText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                
                continuation.resume(returning: (amounts, rawText))
            }
            
            // 設定辨識語言 (繁體中文與英文) 與精準模式
            request.recognitionLanguages = ["zh-Hant", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // ── Layout Reconstruction & Radar Scanning ─────────────────────────────────
    
    private static func parseAmountsFromGeometry(_ observations: [VNRecognizedTextObservation]) -> [Double] {
        var amounts: [Double] = []
        
        // 建立一個方便運算的內部結構
        struct TextElement {
            let text: String
            let centerX: CGFloat
            let centerY: CGFloat
            let height: CGFloat
            let minX: CGFloat
        }
        
        var elements: [TextElement] = []
        
        // 攤平收集所有單字區塊與其座標
        // 注意：Apple Vision 的座標系統原點 (0,0) 在「左下角」，與 Android 的左上角不同，但相對距離的算法通用。
        for obs in observations {
            guard let candidate = obs.topCandidates(1).first else { continue }
            let box = obs.boundingBox
            
            let element = TextElement(
                text: candidate.string.replacingOccurrences(of: " ", with: ""),
                centerX: box.midX,
                centerY: box.midY,
                height: box.height,
                minX: box.minX
            )
            elements.append(element)
        }
        
        // 忽略大小寫，擴大外送平台的特徵字根 (加入 uber 與 food，完美攔截 UberBats 這種錯字)
        guard let platformRegex = try? NSRegularExpression(pattern: "(?i)(panda|eats|uber|food)") else { return [] }
        
        // 1. 找出所有「外送平台名稱」的單字座標當作錨點
        let platformElements = elements.filter { el in
            let range = NSRange(location: 0, length: el.text.utf16.count)
            return platformRegex.firstMatch(in: el.text, options: [], range: range) != nil
        }
        
        // 2. 針對每一個平台名稱錨點，往它的「右邊」發射雷達掃描
        for platform in platformElements {
            let rightElements = elements.filter { el in
                // 必須在平台名稱的右邊
                let isToRight = el.centerX > platform.centerX
                
                // 必須在同一區間內 (放寬垂直容忍度到字體高度的 1.5 倍，抵抗反光)
                let tolerance = platform.height * 1.5
                let isAligned = abs(el.centerY - platform.centerY) < tolerance
                
                let isDifferent = el.minX != platform.minX
                
                return isToRight && isAligned && isDifferent
            }.sorted { $0.minX < $1.minX } // 依照 X 座標由左至右排序
            
            // 3. 掃描右邊的單字，找出距離最近的第一個「純數字」
            for el in rightElements {
                // 避開時間欄位 (一旦撞到冒號代表掃過頭了)
                if el.text.contains(":") {
                    break
                }
                
                // 濾除所有非數字字元
                let digitsOnly = el.text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                if !digitsOnly.isEmpty, let amount = Double(digitsOnly) {
                    amounts.append(amount)
                    break // 成功找到這筆訂單的金額，換下一個平台錨點
                }
            }
        }
        
        return amounts
    }
}
