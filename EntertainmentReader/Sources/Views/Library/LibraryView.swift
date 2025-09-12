//
//  LibraryView.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/09.
//

import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @ObservedObject var vm: LibraryViewModel

    // ファイルインポート用ステート
    @State private var showJSONPicker = false
    @State private var showTextPicker = false
    @State private var showImagePicker = false
    @State private var importError: String?

    var body: some View {
        List(vm.filtered) { work in
            NavigationLink(work.title) {
                WorkDetailView(work: work)
            }
            .badge(work.type == .novel ? "Novel" : "Manga")
        }
        .searchable(text: $vm.query)
        .toolbar {
            // タイプフィルタ
            Menu("タイプ") {
                Button("すべて") { vm.typeFilter = nil }
                Button("ノベル") { vm.typeFilter = .novel }
                Button("マンガ") { vm.typeFilter = .manga }
            }

            // インポート
            Menu {
                Button {
                    showJSONPicker = true
                } label: {
                    Label("JSON から追加", systemImage: "doc.badge.plus")
                }
                Button {
                    showTextPicker = true
                } label: {
                    Label("テキストから追加 (.txt)", systemImage: "text.badge.plus")
                }
                Button {
                    showImagePicker = true
                } label: {
                    Label("画像から追加", systemImage: "photo.badge.plus")
                }
            } label: {
                Image(systemName: "tray.and.arrow.down")
            }
            .accessibilityLabel("インポート")
        }
        .safeAreaInset(edge: .top) {
            FilterSummaryBar(
                vm: vm,
                filteredCount: vm.filtered.count,
                totalCount: vm.works.count
            )
        }
        // JSON Picker
        .fileImporter(
            isPresented: $showJSONPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: true
        ) { result in
            handleImport(result) { urls in
                let imported = try ImportService.importJSON(from: urls)
                vm.addWorks(imported)
            }
        }
        // Text Picker
        .fileImporter(
            isPresented: $showTextPicker,
            allowedContentTypes: [.plainText],
            allowsMultipleSelection: true
        ) { result in
            handleImport(result) { urls in
                let imported = try ImportService.importText(from: urls)
                vm.addWorks(imported)
            }
        }
        // Image Picker
        .fileImporter(
            isPresented: $showImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            handleImport(result) { urls in
                let imported = try ImportService.importImages(from: urls)
                vm.addWorks(imported)
            }
        }
        .alert("インポートエラー", isPresented: .constant(importError != nil), actions: {
            Button("OK") { importError = nil }
        }, message: {
            Text(importError ?? "")
        })
    }

    // 共通ハンドラ（エラーメッセージを整形）
    private func handleImport(_ result: Result<[URL], Error>, perform: ([URL]) throws -> Void) {
        switch result {
        case .success(let urls):
            do {
                try perform(urls)
            } catch let ImportError.unreadableFile(url) {
                importError = "読み込めませんでした: \(url.lastPathComponent)"
            } catch let ImportError.unsupportedFormat(url) {
                importError = "対応していない形式です: \(url.lastPathComponent)"
            } catch {
                importError = "不明なエラーが発生しました。"
            }
        case .failure:
            // キャンセル時もここに来るが、エラー表示は不要
            break
        }
    }
}

#Preview {
    LibraryView(vm: LibraryViewModel())
}
