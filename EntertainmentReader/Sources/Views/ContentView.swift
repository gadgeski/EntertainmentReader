//
//  ContentView.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/09.
//

//
//  ContentView.swift
//  EntertainmentReader
//
//  - ライブラリ起点
//  - しおり一覧導線
//  - [CHANGED] 非推奨の NavigationLink(isActive:) を廃止し、navigationDestination(isPresented:) を採用
//

import SwiftUI

struct ContentView: View {
    @StateObject private var libraryVM = LibraryViewModel()
    @StateObject private var settings = AppSettings()

    // しおり一覧へのナビゲーション制御
    @State private var showBookmarks: Bool = false

    var body: some View {
        NavigationStack {
            LibraryView(vm: libraryVM)
                .navigationTitle("ライブラリ")
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {

                        // [REMOVED] 非推奨の isActive リンク
                        // NavigationLink(isActive: $showBookmarks) { ... } label: { EmptyView() }.hidden()

                        // [UNCHANGED] テーマメニュー
                        Menu {
                            ForEach(ReadingTheme.allCases, id: \.self) { t in
                                Button { settings.theme = t } label: {
                                    Label(t.label, systemImage: icon(for: t))
                                }
                            }
                        } label: {
                            Image(systemName: "paintbrush")
                        }
                        .accessibilityLabel("テーマ")

                        // しおり一覧ボタン（押下でフラグON）
                        Button {
                            showBookmarks = true
                        } label: {
                            Image(systemName: "bookmark")
                        }
                        .accessibilityLabel("しおり一覧")
                    }
                }
                // [NEW] iOS16+ 推奨API：フラグでの遷移先をここで定義
                .navigationDestination(isPresented: $showBookmarks) {
                    BookmarksView(vm: libraryVM)
                }
        }
        .preferredColorScheme(settings.preferredColorScheme)
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

// MARK: - Preview
#Preview {
    ContentView()
}
