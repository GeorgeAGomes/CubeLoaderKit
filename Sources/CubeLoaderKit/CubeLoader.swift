//
//  CubeLoader.swift
//  CubeLoaderKit
//
//  Created by George on 16/03/25.
//

import Foundation
import CoreImage

public class CubeLoader {

	@MainActor public static let shared = CubeLoader()
	public init() {}

	public private(set) var LUTs: [LUT] = []

	public func loadLUTsFromBundle(bundle: Bundle = .main) {
		LUTs.removeAll()
		let cubeURLs = Self.recursiveCubeURLs(in: bundle)
		guard !cubeURLs.isEmpty else {
			print("[CubeLoader] Nenhum arquivo .cube encontrado no bundle \(bundle.bundlePath)")
			return
		}

		for url in cubeURLs {
			do {
				let lut = try LUT(from: url)
				LUTs.append(lut)
			} catch {
				print("[CubeLoader] Falha ao carregar LUT \(url.lastPathComponent): \(error)")
			}
		}
	}

	private static func recursiveCubeURLs(in bundle: Bundle) -> [URL] {
		guard let resourceURL = bundle.resourceURL else { return [] }
		guard let enumerator = FileManager.default.enumerator(
			at: resourceURL,
			includingPropertiesForKeys: [.isRegularFileKey],
			options: [.skipsHiddenFiles, .skipsPackageDescendants]
		) else {
			return []
		}

		var cubeURLs: [URL] = []

		for case let fileURL as URL in enumerator {
			do {
				let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
				guard values.isRegularFile == true else { continue }
			} catch {
				continue
			}

			if fileURL.pathExtension.lowercased() == "cube" {
				cubeURLs.append(fileURL)
			}
		}

		return cubeURLs
	}
}

extension Collection where Element == LUT {
	public func toFilter() -> [CIFilter] {
		return self.compactMap { lut in
			try? lut.createFilter()
		}
	}
}
