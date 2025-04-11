//  LUT.swift
//  Camera
//
//  Created by George on 15/03/25.
//

import Foundation
import CoreImage.CIFilterBuiltins

public struct LUT: CustomDebugStringConvertible {
	public var name: String?
	public var format: LUTFormat = .unknown
	public var domain: LUTRange = LUTRange(min: [0, 0, 0], max: [1, 1, 1])
	public var threeDResolution: Int?
	public var oneDResolution: Int?
	public var inputRange: (min: Float, max: Float)?

	public var threeDValues: [[Float]] = []
	public var oneDValues: [[Float]] = []

	public init(from url: URL) throws {
		let data = try Data(contentsOf: url)
		guard let content = String(data: data, encoding: .utf8) else {
			throw LUTError.invalidData
		}
		guard !content.isEmpty else { throw LUTError.decodingFailed }
		let normalizedContent = content.replacingOccurrences(of: "\r\n", with: "\n")
		let lines = normalizedContent.split(separator: "\n")
		try setup(lines: lines)

		if oneDResolution != nil && threeDResolution != nil {
			format = .hybrid
		} else if oneDResolution != nil {
			format = .oneDimensional
		} else if threeDResolution != nil {
			format = .threeDimensional
		} else {
			throw LUTError.invalidFormat
		}
	}

	public func createFilter() throws -> CIFilter {
		switch format {
		case .threeDimensional:
			return try create3DFilterImplementation()

		case .oneDimensional:
			return try create1DFilterImplementation()

		case .hybrid:
			let cubeFilter = try create3DFilterImplementation()
			let oneDFilter = try create1DFilterImplementation()
			return CompositeLUTFilter(cubeFilter: cubeFilter, oneDFilter: oneDFilter)

		default:
			throw LUTError.invalidFormat
		}
	}

	private func create3DFilterImplementation() throws -> CIFilter {
		guard let res = threeDResolution else {
			throw LUTError.invalidResolution
		}

		let filter = CIFilter.colorCubeWithColorSpace()
		filter.cubeDimension = Float(res)
		filter.colorSpace = CGColorSpaceCreateDeviceRGB()

		let cubeData = Data(
			bytes: threeDValues.flatMap { $0 },
			count: threeDValues.count * 4 * MemoryLayout<Float>.size
		)
		filter.cubeData = cubeData
		if let name {
			filter.name = name
		}

		return filter
	}

	private func create1DFilterImplementation() throws -> CIFilter {
		guard let res = oneDResolution else {
			throw LUTError.invalidResolution
		}
		guard oneDValues.count == res else {
			throw LUTError.invalidData
		}

		let lutImage = try lutImageFrom1DValues(resolution: oneDValues.count, values: oneDValues)

		let filter = LUT1DFilter(lutImage: lutImage)
		if let name {
			filter.name = name
		}
		return filter
	}

	private func lutImageFrom1DValues(resolution: Int, values: [[Float]]) throws -> CIImage {
		var bytePixels = [UInt8]()
			for rgba in values {
				let red = UInt8(clamping: Int(rgba[0] * 255))
				let green = UInt8(clamping: Int(rgba[1] * 255))
				let blue = UInt8(clamping: Int(rgba[2] * 255))
				let alpha = UInt8(clamping: Int(rgba[3] * 255))
				bytePixels.append(contentsOf: [red, green, blue, alpha])
			}

			let data = bytePixels.withUnsafeBufferPointer { Data(buffer: $0) }

			let lutImage = CIImage(
				bitmapData: data,
				bytesPerRow: resolution * 4,
				size: CGSize(width: resolution, height: 1),
				format: .RGBA8,
				colorSpace: CGColorSpaceCreateDeviceRGB()
			)

			return lutImage
	}

	public class LUT1DFilter: CIFilter {
		@objc public var inputImage: CIImage?
		private let lutImage: CIImage

		public init(lutImage: CIImage) {
			self.lutImage = lutImage
			super.init()
		}

		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}

		public override var outputImage: CIImage? {
			guard let inputImage = inputImage else { return nil }

			let normalizedInput = inputImage

			func extractGrayscaleChannel(from image: CIImage, channelVector: CIVector) -> CIImage {
				let isolated = image.applyingFilter("CIColorMatrix", parameters: [
					"inputRVector": channelVector,
					"inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
					"inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
					"inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
					"inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
				])

				return isolated.applyingFilter("CIColorMatrix", parameters: [
					"inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
					"inputGVector": CIVector(x: 1, y: 0, z: 0, w: 0),
					"inputBVector": CIVector(x: 1, y: 0, z: 0, w: 0),
					"inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
					"inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
				])
			}

			let redInput = extractGrayscaleChannel(from: normalizedInput, channelVector: CIVector(x: 1, y: 0, z: 0, w: 0))
			let greenInput = extractGrayscaleChannel(from: normalizedInput, channelVector: CIVector(x: 0, y: 1, z: 0, w: 0))
			let blueInput = extractGrayscaleChannel(from: normalizedInput, channelVector: CIVector(x: 0, y: 0, z: 1, w: 0))

			let redMapped = redInput.applyingFilter("CIColorMap", parameters: ["inputGradientImage": lutImage])
			let greenMapped = greenInput.applyingFilter("CIColorMap", parameters: ["inputGradientImage": lutImage])
			let blueMapped = blueInput.applyingFilter("CIColorMap", parameters: ["inputGradientImage": lutImage])

			let redOnly = redMapped.applyingFilter("CIColorMatrix", parameters: [
				"inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
				"inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
				"inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
				"inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
				"inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
			])

			let greenOnly = greenMapped.applyingFilter("CIColorMatrix", parameters: [
				"inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
				"inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
				"inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
				"inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
				"inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
			])

			let blueOnly = blueMapped.applyingFilter("CIColorMatrix", parameters: [
				"inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
				"inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
				"inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
				"inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
				"inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
			])

			guard let redPlusGreen = CIFilter(name: "CIAdditionCompositing", parameters: [
				kCIInputImageKey: redOnly,
				kCIInputBackgroundImageKey: greenOnly
			])?.outputImage else {
				return nil
			}

			let finalRGB = CIFilter(name: "CIAdditionCompositing", parameters: [
				kCIInputImageKey: blueOnly,
				kCIInputBackgroundImageKey: redPlusGreen
			])?.outputImage

			return finalRGB
		}
	}

	public class CompositeLUTFilter: CIFilter {
		@objc dynamic public var inputImage: CIImage?
		let cubeFilter: CIFilter
		let oneDFilter: CIFilter

		public init(cubeFilter: CIFilter, oneDFilter: CIFilter) {
			self.cubeFilter = cubeFilter
			self.oneDFilter = oneDFilter
			super.init()
		}

		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implementado")
		}

		public override var outputImage: CIImage? {
			guard let image = inputImage else { return nil }
			cubeFilter.setValue(image, forKey: kCIInputImageKey)
			guard let cubeOutput = cubeFilter.outputImage else { return nil }
			oneDFilter.setValue(cubeOutput, forKey: kCIInputImageKey)
			return oneDFilter.outputImage
		}
	}

	public var debugDescription: String {
		var desc = "LUT \(name ?? "Unnamed") | Format: \(format) | "
		switch format {
		case .oneDimensional:
			desc += "1D Size: \(oneDResolution ?? 0) | 1D Points: \(oneDValues.count)"
		case .threeDimensional:
			desc += "3D Size: \(threeDResolution ?? 0) | 3D Points: \(threeDValues.count)"
		case .hybrid:
			desc += "1D Size: \(oneDResolution ?? 0) (\(oneDValues.count) pts) | " +
			"3D Size: \(threeDResolution ?? 0) (\(threeDValues.count) pts)"
		case .unknown:
			desc += "Unknown format"
		}
		return desc
	}

	// MARK: - Processing the .cube file
	private mutating func setup(lines: [String.SubSequence]) throws {
		try lines.forEach { line in
			let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
			guard !cleaned.isEmpty, !cleaned.hasPrefix("#") else { return }

			let components = cleaned.split(separator: " ").map { String($0) }
			try processLine(components)
		}
	}

	private mutating func processLine(_ components: [String]) throws {
		guard let key = components.first else { return }

		switch key {
		case "TITLE":
			parseTitle(components)
		case "LUT_3D_SIZE":
			try parseLUT3DSize(components)
		case "LUT_1D_SIZE":
			try parseLUT1DSize(components)
		case "LUT_3D_INPUT_RANGE":
			try parseLUT3DInputRange(components)
		case "DOMAIN_MIN":
			try parseDomainMin(components)
		case "DOMAIN_MAX":
			try parseDomainMax(components)
		default:
			try parseColorValues(components)
		}
	}

	private mutating func parseTitle(_ components: [String]) {
		self.name = components.dropFirst().joined(separator: " ").replacingOccurrences(of: "\"", with: "")
	}

	private mutating func parseLUT3DSize(_ components: [String]) throws {
		guard let size = Int(components.last ?? "") else {
			throw LUTError.invalidResolution
		}
		threeDResolution = size
		if oneDResolution != nil {
			format = .hybrid
		} else {
			format = .threeDimensional
		}
	}

	private mutating func parseLUT1DSize(_ components: [String]) throws {
		guard let size = Int(components.last ?? "") else {
			throw LUTError.invalidResolution
		}
		oneDResolution = size
		if threeDResolution != nil {
			format = .hybrid
		} else {
			format = .oneDimensional
		}
	}

	private mutating func parseLUT3DInputRange(_ components: [String]) throws {
		let rangeValues = components.dropFirst().compactMap { Float($0) }
		guard rangeValues.count == 2 else { throw LUTError.invalidData }
		inputRange = (min: rangeValues[0], max: rangeValues[1])
		if domain.min == [0, 0, 0] && domain.max == [1, 1, 1] {
			domain = LUTRange(min: [rangeValues[0], rangeValues[0], rangeValues[0]],
							  max: [rangeValues[1], rangeValues[1], rangeValues[1]])
		}
	}

	private mutating func parseDomainMin(_ components: [String]) throws {
		let minValues = components.dropFirst().compactMap { Float($0) }
		guard minValues.count == 3 else { throw LUTError.invalidData }
		domain.min = minValues
	}

	private mutating func parseDomainMax(_ components: [String]) throws {
		let maxValues = components.dropFirst().compactMap { Float($0) }
		guard maxValues.count == 3 else { throw LUTError.invalidData }
		domain.max = maxValues
	}

	private mutating func parseColorValues(_ components: [String]) throws {
		let colorValues = components.compactMap { Float($0) }
		guard colorValues.count == 3 else {
			print(components)
			throw LUTError.invalidData
		}
		let extendedValues = colorValues + [1.0]
		if let oneDRes = oneDResolution, oneDValues.count < oneDRes {
			oneDValues.append(extendedValues)
		} else if threeDResolution != nil {
			threeDValues.append(extendedValues)
		} else {
			throw LUTError.invalidFormat
		}
	}
}

// MARK: - Sup
public struct LUTRange: Codable {
	var min: [Float]
	var max: [Float]
}

public enum LUTFormat: Codable {
	case oneDimensional
	case threeDimensional
	case hybrid
	case unknown
}

public struct InputRangeWrapper: Codable {
	var min: Float
	var max: Float

	init(_ tuple: (min: Float, max: Float)) {
		self.min = tuple.min
		self.max = tuple.max
	}

	func toTuple() -> (min: Float, max: Float) {
		return (min, max)
	}
}

public enum LUTError: Error {
	case decodingFailed
	case invalidResolution
	case unsupported1DLUT
	case invalidFormat
	case invalidData
}
