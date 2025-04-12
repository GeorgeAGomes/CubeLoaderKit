# 🎨 CubeLoaderKit

**CubeLoaderKit** is a Swift library for reading and applying LUTs (Lookup Tables) in `.cube` format—supporting 1D, 3D, and hybrid types—using Core Image.

It allows you to load LUTs directly from your app bundle and convert them into Core Image filters with minimal setup.

## ✅ Features

- 📦 Supports:
  - **1D LUTs** (simple color correction curves)
  - **3D LUTs** (complex color transformations)
  - **Hybrid LUTs** (combined 1D + 3D)
- 📁 Automatically loads `.cube` files from your app bundle
- 🎨 Converts LUTs into `CIFilter` ready for image and video processing
- 🧼 Clean, modern Swift API

## 📦 Installation

### ✅ Swift Package Manager (Recommended)

To add `CubeLoaderKit` to your project:

#### Using Xcode

1. Go to **File > Add Packages...**
2. Enter the URL:

   ```text
   https://github.com/GeorgeAGomes/CubeLoaderKit
   ```

3. Select the version and add the package to your target.

#### Using `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/GeorgeAGomes/CubeLoaderKit.git", from: "0.1.0-beta.1")
]
```

## 🛠️ Usage

1. Add your `.cube` LUT files to your Xcode project and make sure they're included in the **app bundle**.

2. Load and convert them into filters:

```swift
import CubeLoaderKit

let loader = CubeLoader.shared
loader.loadLUTsFromBundle()

let filters: [CIFilter] = loader.LUTs.toFilter()
```

3. Apply the filter to a `CIImage`:

```swift

func applyLUT(to image: UIImage) {
  let filter = filters[currentFilterIndex]
  if let result = ImageLUTApplier.apply(to: image, using: filter) {
    DispatchQueue.main.async {
      self.imageToShow = result
    }
  }
}
```

## 📂 Supported `.cube` Format Example

```
TITLE "Wanna Be Provia"

#LUT size
LUT_3D_SIZE 32

#data domain
DOMAIN_MIN 0.0 0.0 0.0
DOMAIN_MAX 1.0 1.0 1.0

#LUT data points
0.000000 0.000000 0.000000
0.028107 0.000000 0.000000

0.000000 0.000000 0.000000
0.015873 0.000000 0.000000
...
```
