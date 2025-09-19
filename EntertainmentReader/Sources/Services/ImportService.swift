//
//  ImportService.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/09.
//

//
//  ImportService.swift
//  EntertainmentReader
//
//  ノベル専用（Step B）
//  - [REMOVED] importImages(from:) を削除（画像インポート廃止）
//  - [NEW] 旧スキーマ(JSON: type/image)を読み込み → テキストだけ抽出してノベル化
//  - [NEW] サニタイズ（空章/空作品の除去）
//

import Foundation
import UniformTypeIdentifiers
import UIKit

enum ImportError: Error {
    case unreadableFile(URL)
    case unsupportedFormat(URL)
}

struct ImportService {

    // MARK: - Public: JSON Import

    /// JSON からの取り込み
    /// - 対応： [Work] / Work（現行スキーマ）、旧スキーマ（type/image を含む）
    static func importJSON(from urls: [URL]) throws -> [Work] {
        var results: [Work] = []

        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }

            let data: Data
            do { data = try Data(contentsOf: url) }
            catch { throw ImportError.unreadableFile(url) }

            // 1) 現行スキーマで decode を試みる
            if let many = try? decodeWorks(data) {
                results.append(contentsOf: many)
                continue
            }
            if let one = try? decodeWork(data) {
                results.append(one)
                continue
            }

            // 2) 旧スキーマ（type/image含む）で decode → ノベル化
            if let manyLegacy = try? decodeLegacyWorks(data) {
                results.append(contentsOf: manyLegacy.map(convertLegacyToWork))
                continue
            }
            if let oneLegacy = try? decodeLegacyWork(data) {
                results.append(convertLegacyToWork(oneLegacy))
                continue
            }

            // 3) どれにも当たらなければ不明形式
            throw ImportError.unsupportedFormat(url)
        }

        // [NEW] 空章/空作品を除去して返却
        return sanitizeWorksForNovelOnly(results)
    }

    // MARK: - Public: Text Import

    /// プレーンテキスト：1ファイル=1作品（1章=本文）
    static func importText(from urls: [URL]) throws -> [Work] {
        var results: [Work] = []
        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let text: String
            do { text = try String(contentsOf: url, encoding: .utf8) }
            catch { throw ImportError.unreadableFile(url) }

            let title = url.deletingPathExtension().lastPathComponent
            let work = Work(
                id: UUID(),
                title: title,
                author: "インポート",
                chapters: [Chapter(id: UUID(), title: "本文", pages: [.text(text)])]
            )
            results.append(work)
        }
        return sanitizeWorksForNovelOnly(results) // [NEW]
    }

    // [REMOVED] 画像インポート
    // static func importImages(from urls: [URL]) throws -> [Work] { ... }

    // MARK: - Sanitizer（ノベル専用の整形）

    /// [NEW] 空の章・空の作品を取り除く
    private static func sanitizeWorksForNovelOnly(_ works: [Work]) -> [Work] {
        works.compactMap { w in
            let cleanChapters = w.chapters.compactMap { ch -> Chapter? in
                let texts = ch.pages.compactMap { page -> Page? in
                    if case .text(let s) = page, s.isEmpty == false { return .text(s) }
                    return nil
                }
                return texts.isEmpty ? nil : Chapter(id: ch.id, title: ch.title, pages: texts)
            }
            return cleanChapters.isEmpty ? nil : Work(id: w.id, title: w.title, author: w.author, chapters: cleanChapters)
        }
    }

    // MARK: - Current Schema Decoders

    private static func decodeWorks(_ data: Data) throws -> [Work] {
        try JSONDecoder().decode([Work].self, from: data)
    }
    private static func decodeWork(_ data: Data) throws -> Work {
        try JSONDecoder().decode(Work.self, from: data)
    }

    // MARK: - Legacy Schema Support（type/image を含む古い形式）

    // 旧スキーマの簡易表現
    private struct LegacyRawPage: Codable {
        let kind: String
        let value: String
    }
    private struct LegacyChapter: Codable {
        let id: UUID
        let title: String
        let pages: [LegacyRawPage]
    }
    private struct LegacyWork: Codable {
        let id: UUID
        let title: String
        let author: String
        let type: String?      // "novel" / "manga" / or nil
        let chapters: [LegacyChapter]
    }

    private static func decodeLegacyWorks(_ data: Data) throws -> [LegacyWork] {
        try JSONDecoder().decode([LegacyWork].self, from: data)
    }
    private static func decodeLegacyWork(_ data: Data) throws -> LegacyWork {
        try JSONDecoder().decode(LegacyWork.self, from: data)
    }

    /// 旧スキーマ → 現行 Work へ変換（image ページは捨て、text のみ採用）
    private static func convertLegacyToWork(_ lw: LegacyWork) -> Work {
        let chapters: [Chapter] = lw.chapters.compactMap { lc in
            let texts: [Page] = lc.pages.compactMap { rp in
                rp.kind.lowercased() == "text" ? .text(rp.value) : nil
            }
            return texts.isEmpty ? nil : Chapter(id: lc.id, title: lc.title, pages: texts)
        }
        return Work(id: lw.id, title: lw.title, author: lw.author, chapters: chapters)
    }
}
