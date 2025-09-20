//
//  BookmarkStore.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/20.
//

//
//  BookmarkStore.swift
//  EntertainmentReader
//
//  しおり一覧の取得と操作を担う軽量ユーティリティ
//

import Foundation

// [NEW] 一覧用のエントリ
struct BookmarkEntry: Identifiable, Hashable {
    let work: Work
    let chapter: Chapter
    let paragraphIndex: Int

    var id: String { "\(work.id.uuidString)-\(chapter.id.uuidString)" }
}

enum BookmarkStore {

    // [NEW] しおりキー（NovelReaderView と同じ規約）
    private static func key(for workID: UUID, chapterID: UUID) -> String {
        "bookmark.\(workID.uuidString).\(chapterID.uuidString)"
    }

    /// [NEW] しおり一覧を収集（UserDefaults を走査）
    static func loadAll(from works: [Work]) -> [BookmarkEntry] {
        let ud = UserDefaults.standard
        // UserDefaults の全キーを取り出してフィルタ
        let keys = ud.dictionaryRepresentation().keys.filter { $0.hasPrefix("bookmark.") }

        var map: [String: Int] = [:]
        for k in keys {
            if let v = ud.object(forKey: k) as? Int, v >= 0 {
                map[k] = v
            }
        }

        // works/chapters を横断して該当キーがあるものだけ拾う
        var entries: [BookmarkEntry] = []
        for w in works {
            for ch in w.chapters {
                let k = key(for: w.id, chapterID: ch.id)
                if let idx = map[k] {
                    entries.append(BookmarkEntry(work: w, chapter: ch, paragraphIndex: idx))
                }
            }
        }

        // [NEW] 並び順：作品タイトル → 章タイトル
        return entries.sorted {
            if $0.work.title != $1.work.title {
                return $0.work.title.localizedCaseInsensitiveCompare($1.work.title) == .orderedAscending
            } else {
                return $0.chapter.title.localizedCaseInsensitiveCompare($1.chapter.title) == .orderedAscending
            }
        }
    }

    /// [NEW] 単一しおりの削除（= -1 にする）
    static func clear(workID: UUID, chapterID: UUID) {
        let ud = UserDefaults.standard
        ud.set(-1, forKey: key(for: workID, chapterID: chapterID))
    }
}
