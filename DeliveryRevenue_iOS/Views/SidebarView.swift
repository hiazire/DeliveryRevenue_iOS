import SwiftUI

struct SidebarView: View {
    @Binding var selectedFeature: AppFeature
    @Binding var isMenuOpen: Bool
    
    let mainPurple = Color(red: 0.4, green: 0.2, blue: 0.6)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header: 店名或 Logo
            VStack(alignment: .leading) {
                Image(systemName: "house.fill")
                    .font(.largeTitle)
                    .foregroundColor(mainPurple)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("q8js") // 你的工作室名稱
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, 50)
            .padding(.horizontal)
            
            Divider().background(Color.gray)
            
            // 功能列表
            ForEach(AppFeature.allCases, id: \.self) { feature in
                Button(action: {
                    selectedFeature = feature
                    withAnimation { isMenuOpen = false }
                }) {
                    HStack(spacing: 15) {
                        Image(systemName: feature.icon)
                            .foregroundColor(selectedFeature == feature ? .orange : .gray)
                        Text(feature.rawValue)
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: selectedFeature == feature ? .bold : .regular))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedFeature == feature ? Color.white.opacity(0.1) : Color.clear)
                    .cornerRadius(10)
                }
            }
            
            Spacer()
                Text("DR_26may15_3_hermes")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 10)
        }
        .padding()
        .frame(maxWidth: 270, maxHeight: .infinity)
        .background(Color(white: 0.05)) // 極深色背景
    }
}
