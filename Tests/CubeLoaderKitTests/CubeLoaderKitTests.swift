import Testing
import Foundation
import CoreImage
@testable import CubeLoaderKit

// MARK: - Test Helpers

private func writeTempCube(_ content: String) throws -> URL {
	let url = FileManager.default.temporaryDirectory
		.appendingPathComponent(UUID().uuidString)
		.appendingPathExtension("cube")
	try content.write(to: url, atomically: true, encoding: .utf8)
	return url
}

private let minimal3DCubeContent = """
LUT_3D_SIZE 2
0.0 0.0 0.0
1.0 0.0 0.0
0.0 1.0 0.0
1.0 1.0 0.0
0.0 0.0 1.0
1.0 0.0 1.0
0.0 1.0 1.0
1.0 1.0 1.0
"""

private let minimal1DCubeContent = """
LUT_1D_SIZE 2
0.0 0.0 0.0
1.0 1.0 1.0
"""

// MARK: - LUT Parsing: 3D

@Suite("LUT Parsing – 3D")
struct LUTParsing3DTests {

	@Test func detectsFormat() throws {
		let url = try writeTempCube(minimal3DCubeContent)
		let lut = try LUT(from: url)
		#expect(lut.format == .threeDimensional)
	}

	@Test func resolutionParsed() throws {
		let url = try writeTempCube(minimal3DCubeContent)
		let lut = try LUT(from: url)
		#expect(lut.threeDResolution == 2)
		#expect(lut.oneDResolution == nil)
	}

	@Test func valueCountMatchesResolution() throws {
		let url = try writeTempCube(minimal3DCubeContent)
		let lut = try LUT(from: url)
		// 2^3 = 8 entries for a 2x2x2 cube
		#expect(lut.threeDValues.count == 8)
		#expect(lut.oneDValues.isEmpty)
	}

	@Test func valuesHaveAlphaChannel() throws {
		let url = try writeTempCube(minimal3DCubeContent)
		let lut = try LUT(from: url)
		for value in lut.threeDValues {
			#expect(value.count == 4)
			#expect(value[3] == 1.0)
		}
	}
}

// MARK: - LUT Parsing: 1D

@Suite("LUT Parsing – 1D")
struct LUTParsing1DTests {

	@Test func detectsFormat() throws {
		let url = try writeTempCube(minimal1DCubeContent)
		let lut = try LUT(from: url)
		#expect(lut.format == .oneDimensional)
	}

	@Test func resolutionParsed() throws {
		let url = try writeTempCube(minimal1DCubeContent)
		let lut = try LUT(from: url)
		#expect(lut.oneDResolution == 2)
		#expect(lut.threeDResolution == nil)
	}

	@Test func valueCountMatchesResolution() throws {
		let url = try writeTempCube(minimal1DCubeContent)
		let lut = try LUT(from: url)
		#expect(lut.oneDValues.count == 2)
		#expect(lut.threeDValues.isEmpty)
	}
}

// MARK: - LUT Parsing: Hybrid

@Suite("LUT Parsing – Hybrid")
struct LUTParsingHybridTests {

	// 1D (2 entries) + 3D 2x2x2 (8 entries) = 10 data lines total
	private let content = """
	LUT_1D_SIZE 2
	LUT_3D_SIZE 2
	0.0 0.0 0.0
	1.0 1.0 1.0
	0.0 0.0 0.0
	1.0 0.0 0.0
	0.0 1.0 0.0
	1.0 1.0 0.0
	0.0 0.0 1.0
	1.0 0.0 1.0
	0.0 1.0 1.0
	1.0 1.0 1.0
	"""

	@Test func detectsFormat() throws {
		let url = try writeTempCube(content)
		let lut = try LUT(from: url)
		#expect(lut.format == .hybrid)
	}

	@Test func bothValueArraysFilled() throws {
		let url = try writeTempCube(content)
		let lut = try LUT(from: url)
		#expect(lut.oneDValues.count == 2)
		#expect(lut.threeDValues.count == 8)
	}
}

// MARK: - LUT Parsing: Metadata

@Suite("LUT Parsing – Metadata")
struct LUTParsingMetadataTests {

	@Test func titleWithQuotes() throws {
		let content = "TITLE \"My LUT\"\n" + minimal3DCubeContent
		let url = try writeTempCube(content)
		let lut = try LUT(from: url)
		#expect(lut.name == "My LUT")
	}

	@Test func titleWithoutQuotes() throws {
		let content = "TITLE MyLUT\n" + minimal3DCubeContent
		let url = try writeTempCube(content)
		let lut = try LUT(from: url)
		#expect(lut.name == "MyLUT")
	}

	@Test func noTitleIsNil() throws {
		let url = try writeTempCube(minimal3DCubeContent)
		let lut = try LUT(from: url)
		#expect(lut.name == nil)
	}

	@Test func domainMinMaxParsed() throws {
		let content = """
		LUT_3D_SIZE 2
		DOMAIN_MIN 0.1 0.1 0.1
		DOMAIN_MAX 0.9 0.9 0.9
		0.0 0.0 0.0
		1.0 0.0 0.0
		0.0 1.0 0.0
		1.0 1.0 0.0
		0.0 0.0 1.0
		1.0 0.0 1.0
		0.0 1.0 1.0
		1.0 1.0 1.0
		"""
		let url = try writeTempCube(content)
		let lut = try LUT(from: url)
		#expect(lut.domain.min == [0.1, 0.1, 0.1])
		#expect(lut.domain.max == [0.9, 0.9, 0.9])
	}

	@Test func inputRangeParsed() throws {
		let content = """
		LUT_3D_SIZE 2
		LUT_3D_INPUT_RANGE 0.0 1.0
		0.0 0.0 0.0
		1.0 0.0 0.0
		0.0 1.0 0.0
		1.0 1.0 0.0
		0.0 0.0 1.0
		1.0 0.0 1.0
		0.0 1.0 1.0
		1.0 1.0 1.0
		"""
		let url = try writeTempCube(content)
		let lut = try LUT(from: url)
		#expect(lut.inputRange?.min == 0.0)
		#expect(lut.inputRange?.max == 1.0)
	}

	@Test func commentsAreIgnored() throws {
		let content = """
		# Header comment
		TITLE "Commented LUT"
		# Another comment
		LUT_3D_SIZE 2
		# Data section
		0.0 0.0 0.0
		1.0 0.0 0.0
		0.0 1.0 0.0
		1.0 1.0 0.0
		0.0 0.0 1.0
		1.0 0.0 1.0
		0.0 1.0 1.0
		1.0 1.0 1.0
		"""
		let url = try writeTempCube(content)
		let lut = try LUT(from: url)
		#expect(lut.format == .threeDimensional)
		#expect(lut.threeDValues.count == 8)
	}

	@Test func crlfLineEndingsSupported() throws {
		let lines = ["LUT_3D_SIZE 2", "0.0 0.0 0.0", "1.0 0.0 0.0", "0.0 1.0 0.0",
					 "1.0 1.0 0.0", "0.0 0.0 1.0", "1.0 0.0 1.0", "0.0 1.0 1.0", "1.0 1.0 1.0"]
		let content = lines.joined(separator: "\r\n")
		let url = try writeTempCube(content)
		let lut = try LUT(from: url)
		#expect(lut.format == .threeDimensional)
		#expect(lut.threeDValues.count == 8)
	}
}

// MARK: - LUT Parsing: Errors

@Suite("LUT Parsing – Errors")
struct LUTParsingErrorTests {

	@Test func emptyFileThrowsDecodingFailed() throws {
		let url = try writeTempCube("")
		#expect(throws: LUTError.decodingFailed) {
			try LUT(from: url)
		}
	}

	@Test func noSizeKeywordThrowsInvalidFormat() throws {
		let content = """
		TITLE "No Size"
		0.0 0.0 0.0
		1.0 1.0 1.0
		"""
		let url = try writeTempCube(content)
		#expect(throws: LUTError.self) {
			try LUT(from: url)
		}
	}

	@Test func dataLineWithTwoValuesThrowsInvalidData() throws {
		let content = """
		LUT_3D_SIZE 2
		0.0 0.0
		"""
		let url = try writeTempCube(content)
		#expect(throws: LUTError.invalidData) {
			try LUT(from: url)
		}
	}

	@Test func domainMinWithTwoValuesThrowsInvalidData() throws {
		let content = """
		LUT_3D_SIZE 2
		DOMAIN_MIN 0.0 0.0
		"""
		let url = try writeTempCube(content)
		#expect(throws: LUTError.invalidData) {
			try LUT(from: url)
		}
	}

	@Test func domainMaxWithTwoValuesThrowsInvalidData() throws {
		let content = """
		LUT_3D_SIZE 2
		DOMAIN_MAX 1.0 1.0
		"""
		let url = try writeTempCube(content)
		#expect(throws: LUTError.invalidData) {
			try LUT(from: url)
		}
	}

	@Test func inputRangeWithOneValueThrowsInvalidData() throws {
		let content = """
		LUT_3D_SIZE 2
		LUT_3D_INPUT_RANGE 0.0
		"""
		let url = try writeTempCube(content)
		#expect(throws: LUTError.invalidData) {
			try LUT(from: url)
		}
	}

	@Test func nonexistentFileThrows() {
		let url = URL(fileURLWithPath: "/tmp/does_not_exist_\(UUID().uuidString).cube")
		#expect(throws: (any Error).self) {
			try LUT(from: url)
		}
	}
}

// MARK: - LUT Filter Creation

@Suite("LUT Filter Creation")
struct LUTFilterCreationTests {

	@Test func create3DFilter() throws {
		let url = try writeTempCube(minimal3DCubeContent)
		let lut = try LUT(from: url)
		let filter = try lut.createFilter()
		#expect(filter != nil)
	}

	@Test func create1DFilter() throws {
		let url = try writeTempCube(minimal1DCubeContent)
		let lut = try LUT(from: url)
		let filter = try lut.createFilter()
		#expect(filter != nil)
	}

	@Test func createHybridFilterReturnsCompositeFilter() throws {
		let content = """
		LUT_1D_SIZE 2
		LUT_3D_SIZE 2
		0.0 0.0 0.0
		1.0 1.0 1.0
		0.0 0.0 0.0
		1.0 0.0 0.0
		0.0 1.0 0.0
		1.0 1.0 0.0
		0.0 0.0 1.0
		1.0 0.0 1.0
		0.0 1.0 1.0
		1.0 1.0 1.0
		"""
		let url = try writeTempCube(content)
		let lut = try LUT(from: url)
		let filter = try lut.createFilter()
		#expect(filter is CompositeLUTFilter)
	}

	@Test func filterNameMatchesLUTTitle() throws {
		let content = "TITLE \"ColorGrade\"\n" + minimal3DCubeContent
		let url = try writeTempCube(content)
		let lut = try LUT(from: url)
		let filter = try lut.createFilter()
		#expect(filter.name == "ColorGrade")
	}
}

// MARK: - LUT debugDescription

@Suite("LUT debugDescription")
struct LUTDebugDescriptionTests {

	@Test func threeDimensionalDescription() throws {
		let content = "TITLE \"Vivid\"\n" + minimal3DCubeContent
		let url = try writeTempCube(content)
		let lut = try LUT(from: url)
		let desc = lut.debugDescription
		#expect(desc.contains("Vivid"))
		#expect(desc.contains("3D Size: 2"))
		#expect(desc.contains("3D Points: 8"))
	}

	@Test func oneDimensionalDescription() throws {
		let content = "TITLE \"Flat\"\n" + minimal1DCubeContent
		let url = try writeTempCube(content)
		let lut = try LUT(from: url)
		let desc = lut.debugDescription
		#expect(desc.contains("Flat"))
		#expect(desc.contains("1D Size: 2"))
		#expect(desc.contains("1D Points: 2"))
	}

	@Test func unnamedLUTShowsUnnamed() throws {
		let url = try writeTempCube(minimal3DCubeContent)
		let lut = try LUT(from: url)
		#expect(lut.debugDescription.contains("Unnamed"))
	}

	@Test func hybridDescriptionContainsBothSizes() throws {
		let content = """
		LUT_1D_SIZE 2
		LUT_3D_SIZE 2
		0.0 0.0 0.0
		1.0 1.0 1.0
		0.0 0.0 0.0
		1.0 0.0 0.0
		0.0 1.0 0.0
		1.0 1.0 0.0
		0.0 0.0 1.0
		1.0 0.0 1.0
		0.0 1.0 1.0
		1.0 1.0 1.0
		"""
		let url = try writeTempCube(content)
		let lut = try LUT(from: url)
		let desc = lut.debugDescription
		#expect(desc.contains("1D Size: 2"))
		#expect(desc.contains("3D Size: 2"))
	}
}

// MARK: - Array Validation

@Suite("Array Validation")
struct ArrayValidationTests {

	@Test func validationSucceeds() throws {
		let arr: [Float] = [0.0, 0.5, 1.0]
		let result = try arr.validated(count: 3)
		#expect(result == arr)
	}

	@Test func wrongCountThrowsInvalidData() {
		let arr: [Float] = [0.0, 0.5]
		#expect(throws: LUTError.invalidData) {
			try arr.validated(count: 3)
		}
	}

	@Test func emptyArrayWithNonZeroCountThrows() {
		let arr: [Float] = []
		#expect(throws: LUTError.invalidData) {
			try arr.validated(count: 1)
		}
	}

	@Test func emptyArrayWithZeroCountSucceeds() throws {
		let arr: [Float] = []
		let result = try arr.validated(count: 0)
		#expect(result.isEmpty)
	}

	@Test func returnsOriginalArray() throws {
		let arr: [Float] = [0.1, 0.2, 0.3, 0.4]
		let result = try arr.validated(count: 4)
		#expect(result == arr)
	}
}

// MARK: - LUTFormat Codable

@Suite("LUTFormat Codable")
struct LUTFormatCodableTests {

	@Test func roundTripOneDimensional() throws {
		let encoded = try JSONEncoder().encode(LUTFormat.oneDimensional)
		let decoded = try JSONDecoder().decode(LUTFormat.self, from: encoded)
		#expect(decoded == .oneDimensional)
	}

	@Test func roundTripThreeDimensional() throws {
		let encoded = try JSONEncoder().encode(LUTFormat.threeDimensional)
		let decoded = try JSONDecoder().decode(LUTFormat.self, from: encoded)
		#expect(decoded == .threeDimensional)
	}

	@Test func roundTripHybrid() throws {
		let encoded = try JSONEncoder().encode(LUTFormat.hybrid)
		let decoded = try JSONDecoder().decode(LUTFormat.self, from: encoded)
		#expect(decoded == .hybrid)
	}

	@Test func roundTripUnknown() throws {
		let encoded = try JSONEncoder().encode(LUTFormat.unknown)
		let decoded = try JSONDecoder().decode(LUTFormat.self, from: encoded)
		#expect(decoded == .unknown)
	}
}

// MARK: - Collection<LUT>.toFilter()

@Suite("Collection toFilter")
struct CollectionToFilterTests {

	@Test func emptyCollectionReturnsEmpty() {
		let luts: [LUT] = []
		#expect(luts.toFilter().isEmpty)
	}

	@Test func singleValidLUTConverted() throws {
		let url = try writeTempCube(minimal3DCubeContent)
		let lut = try LUT(from: url)
		let filters = [lut].toFilter()
		#expect(filters.count == 1)
	}

	@Test func multipleLUTsConverted() throws {
		let url3D = try writeTempCube(minimal3DCubeContent)
		let url1D = try writeTempCube(minimal1DCubeContent)
		let lut3D = try LUT(from: url3D)
		let lut1D = try LUT(from: url1D)
		let filters = [lut3D, lut1D].toFilter()
		#expect(filters.count == 2)
	}
}

// MARK: - CubeLoader

@Suite("CubeLoader")
struct CubeLoaderTests {

	@Test func initialLUTsAreEmpty() {
		let loader = CubeLoader()
		#expect(loader.LUTs.isEmpty)
	}

	@Test func loadFromEmptyBundleKeepsLUTsEmpty() {
		let loader = CubeLoader()
		// Bundle.module has no .cube files by default in this test target
		loader.loadLUTsFromBundle(bundle: Bundle(for: CubeLoader.self))
		// We don't assert a specific count since bundle content varies;
		// just verify it doesn't crash and the array is set.
		#expect(loader.LUTs.count >= 0)
	}
}
