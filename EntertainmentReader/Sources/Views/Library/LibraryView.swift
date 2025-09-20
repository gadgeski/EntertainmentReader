//
//  LibraryView.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/09.
//

import SwiftUI

struct LibraryView: View {
    @ObservedObject var vm: LibraryViewModel
    @State private var showJSONPicker = false
    @State private var showTextPicker = false
    @State private var importError: String?

    var body: some View {
        List(vm.filtered) { work in
            NavigationLink(work.title) {
                WorkDetailView(work: work) // ← 分岐削除、常にノベル扱い
            }
        }
        .searchable(text: $vm.query)
        .toolbar {
            // ③ タイプメニューは削除
            Menu {
                Button { showJSONPicker = true }   label: { Label("JSON から追加", systemImage: "doc.badge.plus") }
                Button { showTextPicker = true }   label: { Label("テキストから追加 (.txt)", systemImage: "text.badge.plus") }
                // 画像インポートは削除
            } label: { Image(systemName: "tray.and.arrow.down") }
        }
        .safeAreaInset(edge: .top) {
            FilterSummaryBar(vm: vm, filteredCount: vm.filtered.count, totalCount: vm.works.count)
        }
        .fileImporter(isPresented: $showJSONPicker, allowedContentTypes: [.json], allowsMultipleSelection: true) { result in
            handleImport(result) { urls in
                let imported = try ImportService.importJSON(from: urls)
                vm.addWorks(imported)
            }
        }
        .fileImporter(isPresented: $showTextPicker, allowedContentTypes: [.plainText], allowsMultipleSelection: true) { result in
            handleImport(result) { urls in
                let imported = try ImportService.importText(from: urls)
                vm.addWorks(imported)
            }
        }
        .alert("インポートエラー", isPresented: .constant(importError != nil)) {
            Button("OK") { importError = nil }
        } message: { Text(importError ?? "") }
    }

    private func handleImport(_ result: Result<[URL], Error>, perform: ([URL]) throws -> Void) {
        if case .success(let urls) = result {
            do { try perform(urls) } catch { importError = "読み込みに失敗しました。" }
        }
    }
}
