//
//  FilterSummaryBar.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/09.
//

import SwiftUI

struct FilterSummaryBar: View {
    @ObservedObject var vm: LibraryViewModel
    let filteredCount: Int
    let totalCount: Int

    private var hasAnyFilter: Bool {
        !(vm.query.isEmpty) || vm.typeFilter != nil
    }

    private var typeLabel: String? {
        guard let t = vm.typeFilter else { return nil }
        return (t == .novel) ? "ノベル" : "マンガ"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 件数表示
            Text("\(filteredCount)件（全\(totalCount)件）")
                .font(.subheadline).bold()

            // 条件チップ + クリアボタン
            HStack(spacing: 8) {
                if !vm.query.isEmpty {
                    Chip(text: "検索: \"\(vm.query)\"")
                }
                if let typeLabel {
                    Chip(text: "タイプ: \(typeLabel)")
                }
                if !hasAnyFilter {
                    Chip(text: "条件なし")
                }

                Spacer()

                Button("クリア") {
                    vm.query = ""
                    vm.typeFilter = nil
                }
                .disabled(!hasAnyFilter)
            }
            .font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        // 見やすい半透明バー
        .background(.thinMaterial)
        .overlay(Divider(), alignment: .bottom)
    }
}

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

#Preview {
    let vm = LibraryViewModel()
    return FilterSummaryBar(vm: vm, filteredCount: vm.filtered.count, totalCount: vm.works.count)
}
