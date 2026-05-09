//
//  ExifUtil.swift
//  DeliveryRevenue_iOS
//
//  Created by rabisu on 2026/5/9.
//

import Foundation
import UIKit
import ImageIO

class ExifUtil {
    // 改為回傳 String? (加上問號代表允許空值)
    static func extractDate(from imageData: Data) -> String? {
        if let source = CGImageSourceCreateWithData(imageData as CFData, nil),
           let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] {
            
            if let exif = properties["{Exif}"] as? [String: Any],
               let dateString = exif["DateTimeOriginal"] as? String {
                return formatExifDate(dateString)
            }
            
            if let tiff = properties["{TIFF}"] as? [String: Any],
               let dateString = tiff["DateTime"] as? String {
                return formatExifDate(dateString)
            }
        }
        // 找不到日期，誠實回傳 nil
        return nil
    }
    
    private static func formatExifDate(_ dateString: String) -> String {
        let prefix = String(dateString.prefix(10))
        return prefix.replacingOccurrences(of: ":", with: "/")
    }
}
