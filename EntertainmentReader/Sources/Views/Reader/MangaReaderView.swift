//
//  MangaReaderView.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/09.
//

import SwiftUI
import UIKit

struct MangaReaderView: View {
    let chapter: Chapter
    @AppStorage("mangaLastPage") private var lastPage: Int = 0

    private var images: [String] {
        chapter.pages.compactMap { if case let .image(n) = $0 { n } else { nil } }
    }

    var body: some View {
        TabView(selection: $lastPage) {
            ForEach(Array(images.enumerated()), id: \.offset) { idx, name in
                ZoomablePage(name: name)
                    .tag(idx)
            }
        }
        .tabViewStyle(.page)
        .navigationTitle(chapter.title)
    }
}

private struct ZoomablePage: View {
    let name: String
    @State private var scale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            Group {
                if let ui = loadUIImage(name: name) {
                    Image(uiImage: ui).resizable().scaledToFit()
                } else {
                    ZStack {
                        Rectangle().fill(.secondary.opacity(0.2))
                        Text("Missing image: \(name)").font(.caption)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .scaleEffect(scale)
            .gesture(MagnificationGesture().onChanged { scale = max(1, $0) })
        }
        .ignoresSafeArea()
    }

    // Documents 内に同名ファイルがあればそれを優先。無ければ Assets を参照
    private func loadUIImage(name: String) -> UIImage? {
        let fm = FileManager.default
        if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = docs.appendingPathComponent(name)
            if fm.fileExists(atPath: fileURL.path),
               let img = UIImage(contentsOfFile: fileURL.path) {
                return img
            }
        }
        return UIImage(named: name)
    }
}

#Preview {
    let ch = Chapter(id: UUID(), title: "プレビュー", pages: [.image("manga_page_1"), .image("manga_page_2")])
    MangaReaderView(chapter: ch)
}
