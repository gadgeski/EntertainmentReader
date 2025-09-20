//
//  BookmarksView.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/20.
//

//
//  BookmarksView.swift
//  EntertainmentReader
//
//  しおり一覧画面：ライブラリ横断で表示し、タップで該当章へジャンプ
//

import SwiftUI

struct BookmarksView: View {
    @ObservedObject var vm: LibraryViewModel  // [NEW] ライブラリ（作品一覧）を参照
    @State private var entries: [BookmarkEntry] = [] // [NEW] 現在のしおり一覧

    var body: some View {
        List {
            if entries.isEmpty {
                ContentUnavailableView(
                    "しおりはありません",
                    systemImage: "bookmark.slash",
                    description: Text("ノベルのリーダー画面で🔖をタップすると、ここに表示されます。")
                )
            } else {
                ForEach(entries) { e in
                    NavigationLink {
                        // [NEW] 直接リーダーへ。しおり位置から開始
                        NovelReaderView(workID: e.work.id, chapter: e.chapter, startAtBookmark: true)
                            .navigationTitle(e.chapter.title)
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(e.work.title).font(.headline)
                                Text(e.chapter.title).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("段落 \(e.paragraphIndex + 1)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            BookmarkStore.clear(workID: e.work.id, chapterID: e.chapter.id) // [NEW] しおり解除
                            refresh()
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("しおり一覧")
        .toolbar {
            Button {
                refresh() // [NEW] 手動更新
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .accessibilityLabel("更新")
        }
        .onAppear { refresh() }
        .onChange(of: vm.works) { refresh() } // [NEW] ライブラリ変化で再読込
    }

    // [NEW] 一覧を再取得
    private func refresh() {
        entries = BookmarkStore.loadAll(from: vm.works)
    }
}

#Preview("BookmarksView", traits: .sizeThatFitsLayout) {
    NavigationStack {
        BookmarksView(vm: LibraryViewModel())
    }
}
