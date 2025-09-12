//
//  LibraryViewModel.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/09.
//

import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    // 作品一覧（更新のたびに自動保存）
    @Published var works: [Work] = [] {
        didSet { saveLibrary() }
    }

    @Published var query = ""
    @Published var typeFilter: WorkType? = nil

    init() {
        loadLibrary()  // ← 起動時に Documents/library.json と sample.json をマージ読み込み
    }

    var filtered: [Work] {
        works.filter { w in
            (query.isEmpty || w.title.localizedCaseInsensitiveContains(query) || w.author.localizedCaseInsensitiveContains(query)) &&
            (typeFilter == nil || typeFilter == w.type)
        }
    }

    // 外部インポートで作品を追加（ID重複を除去して追加）
    func addWorks(_ new: [Work]) {
        var map = Dictionary(uniqueKeysWithValues: works.map { ($0.id, $0) })
        for w in new { map[w.id] = w }
        works = Array(map.values).sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    // MARK: - 永続化

    /// Documents/library.json のURL
    private var libraryURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("library.json")
    }

    /// 起動時に永続ファイルと同梱サンプルをマージしてロード（ID基準で重複排除）
    private func loadLibrary() {
        let persisted = loadFromDisk() ?? []
        let bundled = loadFromBundleSample() ?? []

        // 既存（persisted）を優先し、サンプルは「未収載のものだけ」追加
        var map = Dictionary(uniqueKeysWithValues: persisted.map { ($0.id, $0) })
        for w in bundled where map[w.id] == nil { map[w.id] = w }

        works = Array(map.values).sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

        // 初回起動（persisted 不在）でも library.json を作っておく
        saveLibrary()
    }

    /// Documents/library.json を保存
    private func saveLibrary() {
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try enc.encode(works)
            try data.write(to: libraryURL, options: [.atomic])
        } catch {
            // 失敗しても動作は継続（ログのみ）
            print("saveLibrary error:", error)
        }
    }

    /// Documents/library.json から読み込み
    private func loadFromDisk() -> [Work]? {
        do {
            let fm = FileManager.default
            guard fm.fileExists(atPath: libraryURL.path) else { return nil }
            let data = try Data(contentsOf: libraryURL)
            let dec = JSONDecoder()
            return try dec.decode([Work].self, from: data)
        } catch {
            print("loadFromDisk error:", error)
            return nil
        }
    }

    /// 同梱 sample.json を読み込み（存在しない/失敗時は nil）
    private func loadFromBundleSample() -> [Work]? {
        do {
            guard let url = Bundle.main.url(forResource: "sample", withExtension: "json") else {
                return nil
            }
            let data = try Data(contentsOf: url)
            let dec = JSONDecoder()
            return try dec.decode([Work].self, from: data)
        } catch {
            print("loadFromBundleSample error:", error)
            return nil
        }
    }
}
