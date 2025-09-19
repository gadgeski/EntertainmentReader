//
//  FilterSummaryBar.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/09.
//

//
//  FilterSummaryBar.swift
//  EntertainmentReader
//
//  ノベル一本化（Step A）対応版
//  - タイプ（マンガ/ノベル）チップとクリア処理を削除
//  - 「検索」チップのみ表示し、クリアは検索語だけをリセット
//

import SwiftUI

struct FilterSummaryBar: View {
    @ObservedObject var vm: LibraryViewModel
    let filteredCount: Int
    let totalCount: Int

    // [CHANGED] フィルタ有無の基準を「検索語のみ」に簡素化
    // 以前: !(vm.query.isEmpty) || vm.typeFilter != nil
    private var hasAnyFilter: Bool {
        // [NEW] ノベル一本化に伴いタイプ条件を撤廃
        !vm.query.isEmpty
    }

    // [REMOVED] タイプ表示用のラベル生成
    // private var typeLabel: String? { ... }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 件数表示
            Text("\(filteredCount)件（全\(totalCount)件）")
                .font(.subheadline)
                .bold()

            // 条件チップ + クリアボタン
            HStack(spacing: 8) {
                // [CHANGED] 検索語チップのみ表示
                if !vm.query.isEmpty {
                    Chip(text: "検索: \"\(vm.query)\"") // [CHANGED]
                }

                // [CHANGED] 条件が何もない場合のチップ（タイプ撤廃のため文言も調整）
                if !hasAnyFilter {
                    Chip(text: "条件なし") // [CHANGED]
                }

                Spacer()

                // [CHANGED] クリアは検索語のみを対象に
                Button("クリア") {
                    vm.query = "" // [CHANGED] 以前は typeFilter もクリアしていた
                }
                .disabled(!hasAnyFilter)
            }
            .font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(.thinMaterial)
        .overlay(Divider(), alignment: .bottom)
    }
}

// MARK: - Chip

private struct Chip: View {
    let text: String
    var body: some View {
        Text(text)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(Color.secondary.opacity(0.15))
            )
    }
}

// MARK: - Preview

private struct FilterSummaryBar_PreviewWrapper: View {
    @StateObject private var vm = LibraryViewModel()

    var body: some View {
        // ここで表示用の状態を仕込む（Viewのライフサイクル内なのでOK）
        FilterSummaryBar(
            vm: vm,
            filteredCount: vm.filtered.count,
            totalCount: vm.works.count
        )
        .padding()
        .onAppear {
            if vm.query.isEmpty {
                vm.query = "ピアノ" // ← ここなら代入OK
            }
        }
    }
}

#Preview("FilterSummaryBar - sizeThatFits", traits: .sizeThatFitsLayout) {
    FilterSummaryBar_PreviewWrapper()
}
