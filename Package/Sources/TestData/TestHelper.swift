//
//  TestHelper.swift
//  Package
//
//  Created by Ockey on 2025/09/09.
//

import Foundation

public enum TestHelper {
    public static func getTestDataFileURL(fileNameWithExtension: String) -> URL {
        // /swift-kraken/Package/Sources/TestData/TestHelper.swift
        let currentFileURL = URL(filePath: #filePath)

        // /swift-kraken/Package/Sources/TestData
        let testDataDirectoryURL = currentFileURL.deletingLastPathComponent()

        return testDataDirectoryURL.appendingPathComponent(fileNameWithExtension)
    }

    public static func findIndexStorePath() -> URL? {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let derivedDataDirectory = homeDirectory.appendingPathComponent("Library/Developer/Xcode/DerivedData")

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: derivedDataDirectory,
                includingPropertiesForKeys: [.isDirectoryKey],
            )

            // Look for directories starting with swift-kraken
            for url in contents where url.lastPathComponent.hasPrefix("swift-kraken-") {
                let indexStoreURL = url
                    .appendingPathComponent("Index.noindex")
                    .appendingPathComponent("DataStore")

                if FileManager.default.fileExists(atPath: indexStoreURL.path) {
                    return indexStoreURL
                }
            }
        } catch {
            return nil
        }

        return nil
    }
}
