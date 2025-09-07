//
//  TestHelpers.swift
//  AICGallery
//
//  Created by Samyak Pawar on 07/09/2025.
//

import Foundation

// Small async wait helpers to keep tests readable.
enum TestWait {
    static func short() async throws {
        try await Task.sleep(nanoseconds: 150_000_000) // 150 ms
    }
    static func debounce() async throws {
        try await Task.sleep(nanoseconds: 300_000_000) // 300 ms (matches VM debounce)
    }
    static func medium() async throws {
        try await Task.sleep(nanoseconds: 600_000_000)
    }
    static func long() async throws {
        try await Task.sleep(nanoseconds: 1_200_000_000)
    }
}
