//
//  CompositeLUTFilter.swift
//  CubeLoaderKit
//
//  Created by George on 11/04/25.
//

import CoreImage

public class CompositeLUTFilter: CIFilter {
    @objc public var inputImage: CIImage?
    let cubeFilter: CIFilter
    let oneDFilter: CIFilter

    public init(cubeFilter: CIFilter, oneDFilter: CIFilter) {
        self.cubeFilter = cubeFilter
        self.oneDFilter = oneDFilter
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var outputImage: CIImage? {
        guard let image = inputImage else { return nil }
        cubeFilter.setValue(image, forKey: kCIInputImageKey)
        guard let cubeOutput = cubeFilter.outputImage else { return nil }
        oneDFilter.setValue(cubeOutput, forKey: kCIInputImageKey)
        return oneDFilter.outputImage
    }
}
