//
//  ContentView.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/09.
//

import SwiftUI

struct ContentView: View {
    // ✅ 状態の単一化：ここでだけ生成・保持
    @StateObject private var libraryVM = LibraryViewModel()
    // [NEW] テーマ設定
    @StateObject private var settings = AppSettings()

    var body: some View {
        NavigationStack {
            // ✅ 子へ注入
            LibraryView(vm: libraryVM)
                .navigationTitle("ライブラリ")
                // [NEW] ルートでテーマメニュー
                .toolbar {
                    Menu {
                        ForEach(ReadingTheme.allCases, id: \.self) { t in
                            Button {
                                settings.theme = t
                            } label: {
                                Label(t.label, systemImage: icon(for: t))
                            }
                        }
                    } label: {
                        Image(systemName: "paintbrush")
                    }
                    .accessibilityLabel("テーマ")
                }
        }
        // [NEW] テーマ反映（sepia は light ベース）
        .preferredColorScheme(settings.preferredColorScheme)
        // [NEW] 子ビューへ配布
        .environmentObject(settings)
    }

    private func icon(for t: ReadingTheme) -> String {
        switch t {
        case .system: return "gearshape"
        case .light:  return "sun.max"
        case .dark:   return "moon"
        case .sepia:  return "drop.fill"
        }
    }
}

#Preview {
    ContentView()
}

