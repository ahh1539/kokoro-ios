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
    // 0.30.2's iOS NAX kernel silently corrupts large ConvTransposed1d outputs,
    // which Kokoro exposes as loud static in longer synthesis chunks. 0.30.6
    // contains the upstream integer-overflow fix (ml-explore/mlx#3092).
    //
    // Junco fork of 0.30.6: identical mlx runtime except Metal's check_error logs
    // instead of throwing, so a Metal command-buffer error inside the completion
    // handler (raised when iOS revokes GPU access on background/lock mid-inference)
    // no longer aborts the process. Every manifest in this graph must reference the
    // same fork URL or SPM reports a duplicate mlx-swift package identity.
    .package(url: "https://github.com/ahh1539/mlx-swift", exact: "0.30.6-junco.1"),
    // .package(url: "https://github.com/mlalma/eSpeakNGSwift", from: "1.0.1"),
    // Controlled fork aligns Misaki's transitive MLX pin with Kokoro's fixed
    // runtime; upstream 1.0.6 still hard-pins the affected MLX 0.30.2.
    .package(url: "https://github.com/ahh1539/MisakiSwift", exact: "1.0.9"),
    .package(url: "https://github.com/ahh1539/MLXUtilsLibrary.git", exact: "0.0.6-junco.1")
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
