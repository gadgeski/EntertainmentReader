//
//  NovelReaderView.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/09.
//

import SwiftUI

struct NovelReaderView: View {
    let workID: UUID
    let chapter: Chapter

    // 作品ID + 章ID にひも付く保存キー（段落インデックスを保存）
    @AppStorage private var lastParagraphIndex: Int
    init(workID: UUID, chapter: Chapter) {
        self.workID = workID
        self.chapter = chapter
        // 例: novelScroll.<workID>.<chapterID> = 23
        _lastParagraphIndex = AppStorage(wrappedValue: 0, "novelScroll.\(workID.uuidString).\(chapter.id.uuidString)")
        _bookmarkIndexRaw   = AppStorage(wrappedValue: -1, "bookmark.\(workID.uuidString).\(chapter.id.uuidString)") // [NEW]
    }

    @AppStorage("novelFontSize") private var fontSize: Double = 18
    @State private var didRestore = false
    @State private var currentParagraphIndex: Int = 0

    // [NEW] しおり保存（-1 = なし）
    @AppStorage private var bookmarkIndexRaw: Int
    private var hasBookmark: Bool {
        bookmarkIndexRaw >= 0 && bookmarkIndexRaw < paragraphs.count
    }

    // [NEW] テーマ
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
            .background(settings.readerBackground)              // [NEW]
            .foregroundStyle(settings.readerForeground)         // [NEW]
            .coordinateSpace(name: "novelScroll")
            .navigationTitle(chapter.title)
            .toolbar {
                // 文字サイズ
                Stepper("文字", value: $fontSize, in: 12...28, step: 2).labelsHidden()

                // [NEW] しおり：ジャンプ
                if hasBookmark {
                    Button {
                        withAnimation {
                            proxy.scrollTo(bookmarkIndexRaw, anchor: .top)
                        }
                    } label: {
                        Image(systemName: "bookmark.circle")
                    }
                    .accessibilityLabel("しおりへ移動")
                }

                // [NEW] しおり：保存/解除（トグル）
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

                // 既存: 「続きへ」（最後の段落保存にジャンプ）
                if lastParagraphIndex > 0 && lastParagraphIndex < paragraphs.count {
                    Button {
                        withAnimation {
                            proxy.scrollTo(lastParagraphIndex, anchor: .top)
                        }
                    } label: {
                        Image(systemName: "arrow.down.to.line")
                    }
                    .accessibilityLabel("続きへ移動")
                }
            }
            // 初回表示時に保存済み段落へ復元
            .onAppear {
                guard !didRestore else { return }
                didRestore = true
                let target = min(max(0, lastParagraphIndex), max(0, paragraphs.count - 1))
                if target > 0 {
                    DispatchQueue.main.async {
                        withAnimation { proxy.scrollTo(target, anchor: .top) }
                    }
                }
            }
            // 可視の先頭段落 index を検出し、変更時のみ保存
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

    /// 可視領域の「上端に最も近い段落 index」
    private static func pickTopMostIndex(from entries: [ParagraphOffset]) -> Int {
        let positives = entries.filter { $0.minY >= 0 }.sorted { $0.minY < $1.minY }
        if let best = positives.first { return best.index }
        if let below = entries.sorted(by: { $0.minY > $1.minY }).first { return below.index }
        return 0
    }
}

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

// 既存の PreferenceKey 群（変更なし）
private struct ParagraphOffset: Equatable { let index: Int; let minY: CGFloat }
private struct ParagraphOffsetsKey: PreferenceKey {
    static var defaultValue: [ParagraphOffset] = []
    static func reduce(value: inout [ParagraphOffset], nextValue: () -> [ParagraphOffset]) {
        value.append(contentsOf: nextValue())
    }
}

#Preview {
    let workID = UUID()
    let sampleText = """
    チャイムの余韻が、雨粒にほどけていった。\n\n
    放課後の廊下は薄い灰色で、窓を流れる水の線が、教室の静けさをやわらかく刻む。音楽室のドアを押すと、古いアップライトピアノの黒が、濡れた世界を吸い込むみたいに深く見えた。\n\n
    椅子に腰を下ろすと、止まっていたメトロノームが、小さく一度だけ息をする。——来たの？　窓際に立つ君がそう言って笑う。譜面の端に落ちた光が震え、雨が拍を数える。\n\n
    「本番、怖くない？」\n
    「怖いよ」\n
    「でも、雨の匂いがする日は、少し勇気が出る」\n\n
    右手で旋律を追いながら、左手で秘密を隠した。手首の内側に、六月の風が触れていく。君の嘘はとても透明で、だからこそ僕は、気づかないふりを選んだ。\n\n
    最後の和音が鳴り終わるころ、窓の向こうで雲がほどけた。しずくの鎖が切れて、一瞬だけ世界が明るくなる。僕らは目を合わせないまま、同じ呼吸を共有した。\n\n
    雨上がりの匂いは、約束のようで、さよならのようでもあった。もう一度、最初から弾こう。君がうなずく。メトロノームが、今度はちゃんと動き始めた。
    """
    let ch = Chapter(id: UUID(), title: "第一章 雨の匂い", pages: [.text(sampleText)])
    return NovelReaderView(workID: workID, chapter: ch)
        .environmentObject(AppSettings()) // テーマ適用プレビュー用
}
