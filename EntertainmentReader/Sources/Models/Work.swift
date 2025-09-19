//
//  Work.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/09.
//

//
//  Work.swift
//  EntertainmentReader
//
//  ノベル専用モデル（Step B）
//  - [REMOVED] WorkType（novel/manga）を撤廃
//  - [REMOVED] Page.image を撤廃（テキストのみ）
//  - [NEW] 旧データ（type / image ページ）を「無視して読み込む」後方互換デコードを実装
//

import Foundation

// MARK: - Page（テキストのみ）
public enum Page: Hashable, Codable {
    case text(String)

    // エンコードは {kind:"text", value:"..."} 形式を維持（既存JSONと互換）
    private enum CodingKeys: String, CodingKey { case kind, value }
    private enum Kind: String, Codable { case text /* , image(旧) */ }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let s):
            try c.encode(Kind.text, forKey: .kind)
            try c.encode(s, forKey: .value)
        }
    }

    // デコードは Chapter 側で一括処理するため未使用
    public init(from decoder: Decoder) throws {
        // 直デコード経路は使わないが、互換のため実装は残す
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try? c.decode(Kind.self, forKey: .kind)
        if kind == .text {
            let s = try c.decode(String.self, forKey: .value)
            self = .text(s)
        } else {
            // [NEW] 旧 "image" 等は空テキストにフォールバック（実質的には上流で弾く）
            self = .text("")
        }
    }
}

// MARK: - Chapter
public struct Chapter: Identifiable, Hashable, Codable {
    public let id: UUID
    public let title: String
    public let pages: [Page]

    public init(id: UUID, title: String, pages: [Page]) {
        self.id = id
        self.title = title
        self.pages = pages
    }

    private enum CodingKeys: String, CodingKey { case id, title, pages }

    // [NEW] 旧フォーマット {kind:"image"} を読み飛ばす後方互換デコード
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.title = try c.decode(String.self, forKey: .title)

        // 旧フォーマットに合わせた RawPage を介して pages を復元
        struct RawPage: Codable {
            let kind: String
            let value: String
        }

        if let raw = try? c.decode([RawPage].self, forKey: .pages) {
            // text だけ採用、image 等は無視
            let mapped: [Page] = raw.compactMap { rp in
                if rp.kind.lowercased() == "text" {
                    return .text(rp.value)
                } else {
                    return nil // [NEW] 旧 "image" は読み飛ばし
                }
            }
            self.pages = mapped
        } else {
            // プレーンテキスト直配列など非標準ケースの緩和（念のため）
            if let texts = try? c.decode([String].self, forKey: .pages) {
                self.pages = texts.map { .text($0) }
            } else {
                self.pages = []
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        // 既存互換：{kind,value} 形式で書き出す
        struct RawPage: Codable { let kind: String; let value: String }
        let raws: [RawPage] = pages.compactMap { page in
            switch page {
            case .text(let s): return RawPage(kind: "text", value: s)
            }
        }
        try c.encode(raws, forKey: .pages)
    }
}

// MARK: - Work（type を撤廃。旧 "type" は無視）
public struct Work: Identifiable, Hashable, Codable {
    public let id: UUID
    public let title: String
    public let author: String
    public let chapters: [Chapter]

    public init(id: UUID, title: String, author: String, chapters: [Chapter]) {
        self.id = id
        self.title = title
        self.author = author
        self.chapters = chapters
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, author, chapters
        case type // [REMOVED] 論理的には未使用だが、旧JSONのキーを受け取るためだけに定義
    }

    // [NEW] 旧 "type" を読み捨て、Chapter の互換ロジックに委ねる
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.title = try c.decode(String.self, forKey: .title)
        self.author = try c.decode(String.self, forKey: .author)
        _ = try? c.decodeIfPresent(String.self, forKey: .type) // ← 旧 "novel"/"manga" を無視
        self.chapters = (try? c.decode([Chapter].self, forKey: .chapters)) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(author, forKey: .author)
        try c.encode(chapters, forKey: .chapters)
        // [REMOVED] "type" は書き出さない（ノベル専用）
    }
}
