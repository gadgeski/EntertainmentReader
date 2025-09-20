//
//  NovelReaderView.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/09.
//

//
//  NovelReaderView.swift
//  EntertainmentReader
//
//  - 既存機能：章内スクロール保存 / しおりトグル
//  - [NEW] startAtBookmark: しおり位置から開始するオプションを追加
//

import SwiftUI

struct NovelReaderView: View {
    let workID: UUID
    let chapter: Chapter
    // [NEW] しおり一覧からの遷移時、しおり位置から開始するためのフラグ
    let startAtBookmark: Bool // [NEW]
    
    // 作品ID + 章ID にひも付く保存キー（段落インデックスを保存）
    @AppStorage private var lastParagraphIndex: Int
    init(workID: UUID, chapter: Chapter, startAtBookmark: Bool = false) { // [CHANGED] 既定値 false
        self.workID = workID
        self.chapter = chapter
        self.startAtBookmark = startAtBookmark // [NEW]
        _lastParagraphIndex = AppStorage(wrappedValue: 0, "novelScroll.\(workID.uuidString).\(chapter.id.uuidString)")
        _bookmarkIndexRaw   = AppStorage(wrappedValue: -1, "bookmark.\(workID.uuidString).\(chapter.id.uuidString)")
    }

    @AppStorage("novelFontSize") private var fontSize: Double = 18
    @State private var didRestore = false
    @State private var currentParagraphIndex: Int = 0

    // しおり保存（-1 = なし）
    @AppStorage private var bookmarkIndexRaw: Int
    private var hasBookmark: Bool {
        bookmarkIndexRaw >= 0 && bookmarkIndexRaw < paragraphs.count
    }

    @EnvironmentObject private var settings: AppSettings

    // 章テキストと段落配列
    private var text: String {
        chapter.pages.compactMap {
            if case let .text(s) = $0 { return s } else { return nil }
        }.joined(separator: "\n\n")
    }
    private var paragraphs: [String] {
        text.components(separatedBy: "\n\n").filter { !$0.isEmpty }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(paragraphs.enumerated()), id: \.offset) { idx, paragraph in
                        ParagraphView(index: idx, text: paragraph, fontSize: fontSize)
                            .id(idx)
                    }
                }
                .padding()
            }
            .background(settings.readerBackground)
            .foregroundStyle(settings.readerForeground)
            .coordinateSpace(name: "novelScroll")
            .navigationTitle(chapter.title)
            .toolbar {
                Stepper("文字", value: $fontSize, in: 12...28, step: 2).labelsHidden()

                if hasBookmark {
                    Button {
                        withAnimation { proxy.scrollTo(bookmarkIndexRaw, anchor: .top) }
                    } label: { Image(systemName: "bookmark.circle") }
                    .accessibilityLabel("しおりへ移動")
                }

                Button {
                    if hasBookmark {
                        bookmarkIndexRaw = -1
                    } else {
                        bookmarkIndexRaw = currentParagraphIndex
                    }
                } label: {
                    Image(systemName: hasBookmark ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel(hasBookmark ? "しおりを解除" : "しおりを保存")

                if lastParagraphIndex > 0 && lastParagraphIndex < paragraphs.count {
                    Button {
                        withAnimation { proxy.scrollTo(lastParagraphIndex, anchor: .top) }
                    } label: { Image(systemName: "arrow.down.to.line") }
                    .accessibilityLabel("続きへ移動")
                }
            }
            .onAppear {
                guard !didRestore else { return }
                didRestore = true
                // [CHANGED] 起点：しおり優先 or “続きから”
                let target: Int
                if startAtBookmark, hasBookmark {                 // [NEW]
                    target = bookmarkIndexRaw
                } else {
                    target = min(max(0, lastParagraphIndex), max(0, paragraphs.count - 1))
                }
                if target > 0 {
                    DispatchQueue.main.async {
                        withAnimation { proxy.scrollTo(target, anchor: .top) }
                    }
                }
            }
            .onPreferenceChange(ParagraphOffsetsKey.self) { entries in
                let visible = Self.pickTopMostIndex(from: entries)
                if visible != currentParagraphIndex {
                    currentParagraphIndex = visible
                    if lastParagraphIndex != visible {
                        lastParagraphIndex = visible
                    }
                }
            }
        }
    }

    private static func pickTopMostIndex(from entries: [ParagraphOffset]) -> Int {
        let positives = entries.filter { $0.minY >= 0 }.sorted { $0.minY < $1.minY }
        if let best = positives.first { return best.index }
        if let below = entries.sorted(by: { $0.minY > $1.minY }).first { return below.index }
        return 0
    }
}

// 既存の ParagraphView / PreferenceKey 群（変更なし）
private struct ParagraphView: View {
    let index: Int
    let text: String
    let fontSize: Double

    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GeometryReader { geo in
                    let minY = geo.frame(in: .named("novelScroll")).minY
                    Color.clear
                        .preference(
                            key: ParagraphOffsetsKey.self,
                            value: [ParagraphOffset(index: index, minY: minY)]
                        )
                }
            )
    }
}

private struct ParagraphOffset: Equatable { let index: Int; let minY: CGFloat }
private struct ParagraphOffsetsKey: PreferenceKey {
    static var defaultValue: [ParagraphOffset] = []
    static func reduce(value: inout [ParagraphOffset], nextValue: () -> [ParagraphOffset]) {
        value.append(contentsOf: nextValue())
    }
}

#Preview("Novel - startAtBookmark", traits: .sizeThatFitsLayout) {
    let ch = Chapter(id: UUID(), title: "プレビュー章", pages: [
        .text((1...20).map { "段落\($0)" }.joined(separator: "\n\n"))
    ])
    return NavigationStack {
        NovelReaderView(workID: UUID(), chapter: ch, startAtBookmark: true) // [NEW]
            .environmentObject(AppSettings())
    }
}
