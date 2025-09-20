//
//  WorkDetailView.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/09.
//

//
//  WorkDetailView.swift
//  EntertainmentReader
//
//  ノベル一本化（Step A）対応版
//  - 「続きから」導線は type 判定を外して常に表示対象へ（対象がある場合） [CHANGED]
//  - 章遷移は常に NovelReaderView へ（マンガ分岐を削除） [REMOVED]
//  - lastChapter.<workID> の動的キーで直近章を保存/復元（既存仕様を維持）
//

import SwiftUI

struct WorkDetailView: View {
    let work: Work

    // 作品ごとの「最後に読んだ章ID」を保持（動的キー）
    // 例: lastChapter.<workUUID> = <chapterUUIDString>
    @AppStorage private var lastChapterID: String
    init(work: Work) {
        self.work = work
        // [CHANGED] ノベル一本化だがキー仕様は据え置き（互換維持）
        _lastChapterID = AppStorage(wrappedValue: "", "lastChapter.\(work.id.uuidString)")
    }

    // 直近の章（保存があれば一致する章を返す）
    private var lastChapter: Chapter? {
        guard !lastChapterID.isEmpty else { return nil }
        return work.chapters.first { $0.id.uuidString == lastChapterID }
    }

    var body: some View {
        List {
            // [CHANGED] 作品タイプの分岐を撤廃し、保存があるなら常に「続きから」を出す
            if let resume = lastChapter {
                Section {
                    NavigationLink {
                        // [CHANGED] 常に NovelReaderView へ
                        NovelReaderView(workID: work.id, chapter: resume)
                    } label: {
                        Label("続きから: \(resume.title)", systemImage: "book.fill")
                            .font(.headline)
                    }
                }
            }

            // 章一覧（常にノベル表示として遷移）
            Section {
                ForEach(work.chapters) { ch in
                    NavigationLink(ch.title) {
                        // [REMOVED] if work.type == .novel { ... } else { MangaReaderView ... }
                        // [CHANGED] 常にノベルとして表示（NovelReaderView は .text ページのみ連結して描画）
                        NovelReaderView(workID: work.id, chapter: ch)
                    }
                }
            }
        }
        .navigationTitle(work.title)
    }
}

// MARK: - Preview

private extension Work {
    // [NEW] プレビュー用のサンプルデータを View の外に用意
    static var previewSample: Work {
        let chapter1 = Chapter(id: UUID(), title: "第一章 雨の匂い", pages: [
            .text("チャイムの余韻が、雨粒にほどけていった。\n\n放課後の廊下は薄い灰色で——")
        ])
        let chapter2 = Chapter(id: UUID(), title: "第二章 窓辺の合図", pages: [
            .text("窓ガラスを二度叩く小さな音。それが合図だった。\n\n譜面台の上には短い旋律だけが残っている。")
        ])
        // [CHANGED] Step B 後の Work は `type` を持たない
        return Work(id: UUID(),
                    title: "放課後、雨とピアノと、きみの嘘",
                    author: "白石 透",
                    chapters: [chapter1, chapter2])
    }
}

#Preview("WorkDetailView", traits: .sizeThatFitsLayout) { // [CHANGED] traits でレイアウト指定
    NavigationStack {
        // [CHANGED] `return` は不要。View をそのまま返す
        WorkDetailView(work: .previewSample)
    }
}
