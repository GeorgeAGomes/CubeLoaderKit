//
//  CIImage+LUT1D.swift
//  CubeLoaderKit
//
//  Created by George on 11/04/25.
//

import CoreImage

extension CIImage {
	static func createFrom1D(values: [[Float]], resolution: Int) throws -> CIImage {
		var bytePixels = [UInt8]()
		for rgba in values {
			bytePixels.append(contentsOf: rgba.prefix(4).map { UInt8(clamping: Int($0 * 255)) })
		}
		let data = bytePixels.withUnsafeBufferPointer { Data(buffer: $0) }
		return CIImage(
			bitmapData: data,
			bytesPerRow: resolution * 4,
			size: CGSize(width: resolution, height: 1),
			format: .RGBA8,
			colorSpace: CGColorSpaceCreateDeviceRGB()
		)
	}
}
