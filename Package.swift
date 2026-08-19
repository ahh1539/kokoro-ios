// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "KokoroSwift",
  platforms: [
    .iOS(.v18), .macOS(.v15)
  ],
  products: [
    .library(
      name: "KokoroSwift",
      type: .dynamic,
      targets: ["KokoroSwift"]
    ),
  ],
  dependencies: [
    // Junco fork of mlx-swift on upstream mlx 0.32.0, which recovers from a Metal
    // command-buffer error (raised when iOS revokes GPU access on background/lock
    // mid-inference) instead of hanging or aborting the process. The mlx-c submodule
    // carries a one-line FFTNorm compat patch for 0.32. Every manifest in this graph
    // must reference the same fork URL or SPM reports a duplicate package identity.
    .package(url: "https://github.com/ahh1539/mlx-swift", exact: "0.31.6-junco.0.32.4"),
    // .package(url: "https://github.com/mlalma/eSpeakNGSwift", from: "1.0.1"),
    .package(url: "https://github.com/ahh1539/MisakiSwift", exact: "1.0.12"),
    .package(url: "https://github.com/ahh1539/MLXUtilsLibrary.git", exact: "0.0.6-junco.3")
  ],
  targets: [
    .target(
      name: "KokoroSwift",
      dependencies: [
        .product(name: "MLX", package: "mlx-swift"),
        .product(name: "MLXNN", package: "mlx-swift"),
        .product(name: "MLXRandom", package: "mlx-swift"),
        .product(name: "MLXFFT", package: "mlx-swift"),
        // .product(name: "eSpeakNGLib", package: "eSpeakNGSwift"),
        .product(name: "MisakiSwift", package: "MisakiSwift"),
        .product(name: "MLXUtilsLibrary", package: "MLXUtilsLibrary")
      ],
      resources: [
       .process("Resources")
      ]
    ),
    .testTarget(
      name: "KokoroSwiftTests",
      dependencies: ["KokoroSwift"]
    ),
  ]
)
