//
//  WorkDetailView.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/09.
//

import SwiftUI

struct WorkDetailView: View {
    let work: Work

    // [NEW] この作品の「最後に読んだ章ID」を動的キーで保持
    @AppStorage private var lastChapterID: String
    init(work: Work) {
        self.work = work
        // [NEW] 作品ごとに別のキーにする（例: lastChapter.XXXXXXXX-...）
        _lastChapterID = AppStorage(wrappedValue: "", "lastChapter.\(work.id.uuidString)")
    }

    // [NEW] 保存された章IDに一致する章（ノベルのみを対象にするなら guard でもOK）
    private var lastChapter: Chapter? {
        guard !lastChapterID.isEmpty else { return nil }
        return work.chapters.first { $0.id.uuidString == lastChapterID }
    }

    var body: some View {
        List {
            // [NEW] ノベル作品かつ前回位置があれば「続きから」ショートカットを表示
            if work.type == .novel, let resume = lastChapter {
                Section {
                    NavigationLink {
                        NovelReaderView(workID: work.id, chapter: resume) // [CHANGED] workID を渡す
                    } label: {
                        Label("続きから: \(resume.title)", systemImage: "book.fill")
                            .font(.headline)
                    }
                }
            }

            // 章一覧
            Section {
                ForEach(work.chapters) { ch in
                    NavigationLink(ch.title) {
                        if work.type == .novel {
                            NovelReaderView(workID: work.id, chapter: ch)  // [CHANGED] workID を渡す
                        } else {
                            MangaReaderView(chapter: ch)
                        }
                    }
                }
            }
        }
        .navigationTitle(work.title)
    }
}

#Preview {
    let vm = LibraryViewModel()
    let sample = vm.works.first!
    WorkDetailView(work: sample)
}
