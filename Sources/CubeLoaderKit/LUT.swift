import Foundation
import CoreImage.CIFilterBuiltins

// MARK: - LUT Main Type
public struct LUT: CustomDebugStringConvertible {
	public var name: String?
	public var format: LUTFormat = .unknown
	public var domain: LUTRange = .init(min: [0, 0, 0], max: [1, 1, 1])
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

		let lines = content.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n")
		try setup(lines: lines)

		switch (oneDResolution, threeDResolution) {
		case (.some, .some): format = .hybrid
		case (.some, _): format = .oneDimensional
		case (_, .some): format = .threeDimensional
		default: throw LUTError.invalidFormat
		}
	}

	public func createFilter() throws -> CIFilter {
		switch format {
		case .threeDimensional: return try create3DFilter()
		case .oneDimensional: return try create1DFilter()
		case .hybrid:
			return CompositeLUTFilter(
				cubeFilter: try create3DFilter(),
				oneDFilter: try create1DFilter()
			)
		default: throw LUTError.invalidFormat
		}
	}

	// MARK: - Debug
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
}

// MARK: - Internal Filter Creation
private extension LUT {

	func create3DFilter() throws -> CIFilter {
		guard let res = threeDResolution else { throw LUTError.invalidResolution }

		let filter = CIFilter.colorCubeWithColorSpace()
		filter.cubeDimension = Float(res)
		filter.colorSpace = CGColorSpaceCreateDeviceRGB()

		let cubeData = Data(
			bytes: threeDValues.flatMap { $0 },
			count: threeDValues.count * 4 * MemoryLayout<Float>.size
		)
		filter.cubeData = cubeData
		if let name { filter.name = name }

		return filter
	}

	func create1DFilter() throws -> CIFilter {
		guard let res = oneDResolution else { throw LUTError.invalidResolution }
		guard oneDValues.count == res else { throw LUTError.invalidData }

		let lutImage = try CIImage.createFrom1D(values: oneDValues, resolution: res)
		let filter = LUT1DFilter(lutImage: lutImage)
		if let name { filter.name = name }

		return filter
	}
}

// MARK: - CIImage Helpers
private extension CIImage {
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

// MARK: - File Parsing
private extension LUT {
	mutating func setup(lines: [String.SubSequence]) throws {
		for line in lines {
			let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
			guard !cleaned.isEmpty, !cleaned.hasPrefix("#") else { continue }

			let components = cleaned.split(separator: " ").map(String.init)
			try processLine(components)
		}
	}

	mutating func processLine(_ components: [String]) throws {
		guard let key = components.first else { return }

		switch key {
		case "TITLE":
			name = components.dropFirst().joined(separator: " ").replacingOccurrences(of: "\"", with: "")
		case "LUT_3D_SIZE":
			threeDResolution = components.last.flatMap(Int.init)
		case "LUT_1D_SIZE":
			oneDResolution = components.last.flatMap(Int.init)
		case "LUT_3D_INPUT_RANGE":
			let range = components.dropFirst().compactMap(Float.init)
			guard range.count == 2 else { throw LUTError.invalidData }
			inputRange = (range[0], range[1])
			domain = LUTRange(min: [range[0], range[0], range[0]], max: [range[1], range[1], range[1]])
		case "DOMAIN_MIN":
			domain.min = try components.dropFirst().compactMap(Float.init).validated(count: 3)
		case "DOMAIN_MAX":
			domain.max = try components.dropFirst().compactMap(Float.init).validated(count: 3)
		default:
			let values = components.compactMap(Float.init)
			guard values.count == 3 else { throw LUTError.invalidData }
			let rgba = values + [1.0]
			if let oneD = oneDResolution, oneDValues.count < oneD {
				oneDValues.append(rgba)
			} else if threeDResolution != nil {
				threeDValues.append(rgba)
			} else {
				throw LUTError.invalidFormat
			}
		}
	}
}

// MARK: - Helpers
private extension Array where Element == Float {
	func validated(count: Int) throws -> [Float] {
		guard self.count == count else { throw LUTError.invalidData }
		return self
	}
}
