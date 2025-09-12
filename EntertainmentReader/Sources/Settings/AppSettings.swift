//
//  AppSettings.swift
//  EntertainmentReader
//
//  Created by Dev Tech on 2025/09/10.
//

import SwiftUI

enum ReadingTheme: String, CaseIterable, Codable {
    case system, light, dark, sepia

    var label: String {
        switch self {
        case .system: return "システム"
        case .light:  return "ライト"
        case .dark:   return "ダーク"
        case .sepia:  return "セピア"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("readingTheme") private var rawTheme: String = ReadingTheme.system.rawValue

    var theme: ReadingTheme {
        get { ReadingTheme(rawValue: rawTheme) ?? .system }
        set { rawTheme = newValue.rawValue; objectWillChange.send() }
    }

    // ルートに適用する ColorScheme（sepia は light ベース）
    var preferredColorScheme: ColorScheme? {
        switch theme {
        case .system: return nil
        case .light, .sepia: return .light
        case .dark:  return .dark
        }
    }

    // リーダー部分の配色
    var readerBackground: Color {
        switch theme {
        case .sepia:
            return Color(red: 0.97, green: 0.94, blue: 0.88)
        case .dark:
            return Color.black
        default:
            return Color(.systemBackground)
        }
    }

    var readerForeground: Color {
        switch theme {
        case .sepia:
            return Color(red: 0.35, green: 0.25, blue: 0.15)
        case .dark:
            return Color.white
        default:
            return Color.primary
        }
    }
}
