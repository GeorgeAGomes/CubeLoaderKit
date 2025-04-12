//
//  LUT1DFilter.swift
//  CubeLoaderKit
//
//  Created by George on 11/04/25.
//

import CoreImage

class LUT1DFilter: CIFilter {
    @objc public var inputImage: CIImage?
    private let lutImage: CIImage

	private let xVector = CIVector(x: 1, y: 0, z: 0)
	private let wVector = CIVector(x: 0, y: 0, z: 0, w: 1)
	private let emptyVector = CIVector(x: 0, y: 0, z: 0)

	private let colorMap = "CIColorMap"
	private let colorMatrix = "CIColorMatrix"
	private let additionCompositing = "CIAdditionCompositing"
	private let inputGradientImage = "inputGradientImage"

	private let inputRVector = "inputRVector"
	private let inputGVector = "inputGVector"
	private let inputBVector = "inputBVector"
	private let inputAVector = "inputAVector"
	private let inputBiasVector = "inputBiasVector"

	public init(lutImage: CIImage) {
        self.lutImage = lutImage
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var outputImage: CIImage? {
        guard let inputImage = inputImage else { return nil }

        let redInput = extractGrayscaleChannel(from: inputImage, channelVector: CIVector(x: 1, y: 0, z: 0, w: 0))
        let greenInput = extractGrayscaleChannel(from: inputImage, channelVector: CIVector(x: 0, y: 1, z: 0, w: 0))
        let blueInput = extractGrayscaleChannel(from: inputImage, channelVector: CIVector(x: 0, y: 0, z: 1, w: 0))

        let redMapped = redInput.applyingFilter(colorMap, parameters: [inputGradientImage: lutImage])
        let greenMapped = greenInput.applyingFilter(colorMap, parameters: [inputGradientImage: lutImage])
        let blueMapped = blueInput.applyingFilter(colorMap, parameters: [inputGradientImage: lutImage])

		let redOnly = isolateSingleChannel(from: redMapped, r: 1)
		let greenOnly = isolateSingleChannel(from: greenMapped, g: 1)
		let blueOnly = isolateSingleChannel(from: blueMapped, b: 1)

		let combined = combineRGBChannels(red: redOnly, green: greenOnly, blue: blueOnly)
		return combined
    }

	private func extractGrayscaleChannel(from image: CIImage, channelVector: CIVector) -> CIImage {

		let isolated = image.applyingFilter(colorMatrix, parameters: [
			inputRVector: channelVector,
			inputGVector: emptyVector,
			inputBVector: emptyVector,
			inputAVector: wVector,
			inputBiasVector: emptyVector
		])

		return isolated.applyingFilter(colorMatrix, parameters: [
			inputRVector: xVector,
			inputGVector: xVector,
			inputBVector: xVector,
			inputAVector: wVector,
			inputBiasVector: emptyVector
		])
	}

	private func isolateSingleChannel(from image: CIImage, r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0) -> CIImage {
		return image.applyingFilter(colorMatrix, parameters: [
			inputRVector: CIVector(x: r, y: 0, z: 0, w: 0),
			inputGVector: CIVector(x: 0, y: g, z: 0, w: 0),
			inputBVector: CIVector(x: 0, y: 0, z: b, w: 0),
			inputAVector: wVector,
			inputBiasVector: emptyVector
		])
	}

	func combineRGBChannels(red: CIImage, green: CIImage, blue: CIImage) -> CIImage? {
		guard let redPlusGreen = CIFilter(name: additionCompositing, parameters: [
			kCIInputImageKey: red,
			kCIInputBackgroundImageKey: green
		])?.outputImage else {
			return nil
		}

		return CIFilter(name: additionCompositing, parameters: [
			kCIInputImageKey: blue,
			kCIInputBackgroundImageKey: redPlusGreen
		])?.outputImage
	}
}


