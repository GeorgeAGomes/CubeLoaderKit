# Changelog

All notable changes to CubeLoaderKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-23

First stable release of CubeLoaderKit — a Swift package for loading, parsing, and applying `.cube` LUT files on iOS using Core Image.

### LUT Loading
- `CubeLoader` — singleton that recursively finds and loads all `.cube` files from the app bundle
- `LUT` — parses `.cube` files into a structured model supporting **1D**, **3D**, and **hybrid (1D + 3D)** formats
- Supports all standard `.cube` keywords: `TITLE`, `LUT_1D_SIZE`, `LUT_3D_SIZE`, `LUT_3D_INPUT_RANGE`, `DOMAIN_MIN`, `DOMAIN_MAX`
- Handles comments (`#`) and both LF and CRLF line endings

### Filters
- `LUT1DFilter` — custom `CIFilter` that applies a 1D LUT per RGB channel using Core Image
- `CompositeLUTFilter` — custom `CIFilter` that chains a 3D cube filter and a 1D filter for hybrid LUTs
- `Collection<LUT>.toFilter()` — convenience method to batch-convert LUTs to `[CIFilter]`

### Image Processing
- `ImageLUTApplier` — applies any `CIFilter` to a `UIImage`, with optional custom `CIContext`

### Types & Errors
- `LUTFormat` — `Codable` enum: `oneDimensional`, `threeDimensional`, `hybrid`, `unknown`
- `LUTRange` — `Codable` struct for domain min/max boundaries
- `LUTError` — typed errors: `decodingFailed`, `invalidResolution`, `unsupported1DLUT`, `invalidFormat`, `invalidData`

### Tests
- 45 tests across 11 suites covering parsing, filter creation, error handling, `Codable` conformance, and `CubeLoader`
