//
//  ImportService.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/09.
//

import Foundation
import UniformTypeIdentifiers
import UIKit

enum ImportError: Error {
    case unreadableFile(URL)
    case unsupportedFormat(URL)
}

struct ImportService {

    // JSON: [Work] もしくは Work 単体のどちらにも対応
    static func importJSON(from urls: [URL]) throws -> [Work] {
        var results: [Work] = []
        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let data: Data
            do { data = try Data(contentsOf: url) }
            catch { throw ImportError.unreadableFile(url) }

            let decoder = JSONDecoder()
            if let many = try? decoder.decode([Work].self, from: data) {
                results.append(contentsOf: many)
            } else if let one = try? decoder.decode(Work.self, from: data) {
                results.append(one)
            } else {
                throw ImportError.unsupportedFormat(url)
            }
        }
        return results
    }

    // プレーンテキスト: 1ファイル=1作品（1章=本文）
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
                type: .novel,
                chapters: [
                    Chapter(id: UUID(), title: "本文", pages: [.text(text)])
                ]
            )
            results.append(work)
        }
        return results
    }

    // 画像: 選択した画像群 = 1作品（1章=全ページ）
    static func importImages(from urls: [URL]) throws -> [Work] {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        var pageNames: [String] = []

        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }

            // 保存先の一意ファイル名を作成（オリジン名 + UUID）
            let ext = url.pathExtension.isEmpty ? "img" : url.pathExtension
            let base = url.deletingPathExtension().lastPathComponent
            let unique = base + "_" + UUID().uuidString.prefix(8) + "." + ext
            let dest = docs.appendingPathComponent(unique)

            do {
                if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
                try fm.copyItem(at: url, to: dest)
                pageNames.append(unique) // ← Documents 内のファイル名を保持
            } catch {
                throw ImportError.unreadableFile(url)
            }
        }

        // 並びはファイル名昇順に（見通しのため）
        pageNames.sort()

        let title = "画像インポート（\(pageNames.count)枚）"
        let chapter = Chapter(id: UUID(), title: "第1話", pages: pageNames.map { .image($0) })
        let work = Work(id: UUID(), title: title, author: "インポート", type: .manga, chapters: [chapter])
        return [work]
    }
}
