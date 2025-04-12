//
//  Array+Validation.swift
//  CubeLoaderKit
//
//  Created by George on 11/04/25.
//

// MARK: - Helpers
extension Array where Element == Float {
	func validated(count: Int) throws -> [Float] {
		guard self.count == count else { throw LUTError.invalidData }
		return self
	}
}
