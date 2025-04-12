//
//  ImageLUTApplier.swift
//  CubeLoaderKit
//
//  Created by George on 11/04/25.
//

import UIKit
import CoreImage

public class ImageLUTApplier {
	public static func apply(
		ciContext: CIContext = CIContext(),
		to image: UIImage,
		using filter: CIFilter
	) -> UIImage? {
		guard let ciImage = CIImage(image: image) else { return nil }
		
		filter.setValue(ciImage, forKey: kCIInputImageKey)

		guard let outputImage = filter.outputImage,
			  let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
			return nil
		}

		return UIImage(cgImage: cgImage)
	}
}
