//
//  LibraryViewModel.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/09.
//

//
//  LibraryViewModel.swift
//  EntertainmentReader
//
//  ノベル一本化（Step A）対応版
//  - UI 上はノベルのみ表示（マンガはデータ互換のため保持可）
//  - Documents/library.json に自動保存
//  - 起動時に library.json と sample.json をマージ読込（ID重複排除）
//  - Files Picker からの追加を addWorks(_:) で統合
//

import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {

    // MARK: - Public States

    /// 作品一覧：更新のたびに自動保存
    @Published var works: [Work] = [] {
        didSet { saveLibrary() }
    }

    /// 検索語（タイトル/著者に対して）
    @Published var query: String = ""

    // [REMOVED] タイプフィルタ（ノベル一本化のため）
    // @Published var typeFilter: WorkType? = nil

    // MARK: - Init

    init() {
        loadLibrary()             // 起動時ロード（library.json + sample.json マージ）
        removeMangaIfAny()        // [NEW] UI をノベル専用にするための掃除（互換温存）
    }

    // MARK: - Derived (UI)

    /// UI 表示用のフィルタ済み配列（ノベルのみ / 検索語反映 / タイトル昇順）
    var filtered: [Work] {
        works
            .filter { w in
                // [NEW] UI からマンガを除外（互換のためデータ自体は保持してもよい）
                (w.type != .manga)
                &&
                // 検索（タイトル・著者）
                (query.isEmpty
                 || w.title.localizedCaseInsensitiveContains(query)
                 || w.author.localizedCaseInsensitiveContains(query))
            }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    // MARK: - Mutations

    /// 外部インポートで作品を追加（ID重複は上書き、タイトル昇順）
    func addWorks(_ new: [Work]) {
        var map = Dictionary(uniqueKeysWithValues: works.map { ($0.id, $0) })
        for w in new {
            map[w.id] = w
        }
        works = Array(map.values)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        // 追加後もマンガは UI から隠すポリシーを維持
        removeMangaIfAny() // [NEW]
    }

    // MARK: - Novel-only Step A Helpers

    /// [NEW] マンガ作品を内部ストレージから除外（UI をノベル専用に）
    /// 互換性の観点では「保持」でも良いが、ここでは永続化コストを下げるため保存前に除外
    private func removeMangaIfAny() {
        let novels = works.filter { $0.type != .manga }
        if novels.count != works.count {
            works = novels // didSet で自動保存される
        }
    }

    // MARK: - Persistence

    /// Documents/library.json の URL
    private var libraryURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("library.json")
    }

    /// 起動時に永続ファイルと同梱サンプルをマージしてロード（ID基準で重複排除）
    private func loadLibrary() {
        let persisted = loadFromDisk() ?? []
        let bundled = loadFromBundleSample() ?? []

        // 既存（persisted）を優先し、サンプルは「未収載だけ」追加
        var map = Dictionary(uniqueKeysWithValues: persisted.map { ($0.id, $0) })
        for w in bundled where map[w.id] == nil {
            map[w.id] = w
        }

        works = Array(map.values)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

        // 初回起動（persisted 不在）の場合でも library.json を作成しておく
        saveLibrary()
    }

    /// Documents/library.json へ保存（原子的書き込み）
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

    /// Documents/library.json から読み込み（存在しなければ nil）
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
