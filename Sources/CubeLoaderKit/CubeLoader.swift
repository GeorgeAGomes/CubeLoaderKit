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

	public private(set) var LUTs: [LUT] = []

	public func loadLUTsFromBundle() {
		guard let urls = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil) else {
			print("No resources found")
			return
		}

		let cubeURLs = urls.filter { $0.pathExtension.lowercased() == "cube" }

		for url in cubeURLs {
			do {
				let lut = try LUT(from: url)
				LUTs.append(lut)
			} catch {
				print("Error loading LUT: \(error)")
			}
		}
	}
}

extension Collection where Element == LUT {
	public func toFilter() -> [CIFilter] {
		return self.compactMap { lut in
			try? lut.createFilter()
		}
	}
}
