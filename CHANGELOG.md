# Changelog

All notable changes to CubeLoaderKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-23

### Added
- `CubeLoader` — loads and manages `.cube` LUT files from the app bundle recursively
- `LUT` — parses `.cube` files supporting 1D, 3D, and hybrid (1D + 3D) formats
- `LUT1DFilter` — custom `CIFilter` that applies a 1D LUT to each RGB channel independently
- `CompositeLUTFilter` — custom `CIFilter` that chains a 3D cube filter followed by a 1D filter for hybrid LUTs
- `ImageLUTApplier` — applies a `CIFilter` to a `UIImage` using `CIContext`
- `LUTFormat` — enum representing `oneDimensional`, `threeDimensional`, `hybrid`, and `unknown` formats (`Codable`)
- `LUTRange` — struct for `DOMAIN_MIN` / `DOMAIN_MAX` boundaries (`Codable`)
- `LUTError` — typed errors: `decodingFailed`, `invalidResolution`, `unsupported1DLUT`, `invalidFormat`, `invalidData`
- Support for `.cube` keywords: `TITLE`, `LUT_1D_SIZE`, `LUT_3D_SIZE`, `LUT_3D_INPUT_RANGE`, `DOMAIN_MIN`, `DOMAIN_MAX`
- Support for comments (`#`) and CRLF line endings in `.cube` files
- `Collection<LUT>.toFilter()` — convenience method to convert a collection of LUTs to `[CIFilter]`
- Test suite with 45 tests across 11 suites covering parsing, filter creation, errors, and codable conformance
