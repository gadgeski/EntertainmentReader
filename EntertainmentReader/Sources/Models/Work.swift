//
//  Work.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/09.
//

import Foundation

enum WorkType: String, Codable { case novel, manga }

struct Work: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let author: String
    let type: WorkType
    let chapters: [Chapter]
}

struct Chapter: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let pages: [Page]
}

enum Page: Codable, Hashable {
    case text(String)
    case image(String) // 画像名（Assets or Bundle）

    private enum CodingKeys: String, CodingKey { case kind, value }
    private enum Kind: String, Codable { case text, image }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(Kind.self, forKey: .kind)
        switch kind {
        case .text:  self = .text(try c.decode(String.self, forKey: .value))
        case .image: self = .image(try c.decode(String.self, forKey: .value))
        }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let s):  try c.encode(Kind.text,  forKey: .kind);  try c.encode(s, forKey: .value)
        case .image(let n): try c.encode(Kind.image, forKey: .kind); try c.encode(n, forKey: .value)
        }
    }
}
