//
//  Kokoro-tts-lib
//
import Foundation
import MLX
import MLXNN

/// Conv1d with weight normalization.
///
/// Weight-norm and the bias reshape are input-independent, so they are computed
/// once at init instead of on every forward (the vocoder has many of these).
/// `eval` materializes the result so `weightG` / `weightV` can be dropped and
/// are not kept resident next to the normalized copy.
class ConvWeighted: Module {
  private let normalizedWeight: MLXArray
  private let shapedBias: MLXArray?

  let stride: Int
  let padding: Int
  let dilation: Int
  let outputPadding: Int
  let groups: Int

  init(
    weightG: MLXArray,
    weightV: MLXArray,
    bias: MLXArray?,
    stride: Int = 1,
    padding: Int = 1,
    dilation: Int = 1,
    outputPadding: Int = 0,
    groups: Int = 1
  ) {
    self.stride = stride
    self.padding = padding
    self.dilation = dilation
    self.outputPadding = outputPadding
    self.groups = groups

    // Materialize the normalized weight at init, then drop `weightG` / `weightV`
    // so we do not keep a second resident copy for the life of KokoroTTS.
    let normalized = ConvWeighted.weightNorm(weightV: weightV, weightG: weightG, dim: 0)
    let biasShaped = bias?.reshaped([1, 1, -1])
    eval(normalized)
    if let biasShaped { eval(biasShaped) }
    self.normalizedWeight = normalized
    self.shapedBias = biasShaped

    super.init()
  }

  static func computeNorm(
    x: MLXArray,
    p: Int,
    dim: [Int]? = nil,
    keepdim: Bool = false
  ) -> MLXArray {
    guard p == 1 || p == 2 else {
      fatalError("Only p-norms with p of 1 or 2 are supported")
    }

    let dimensions: [Int]
    if let dim = dim {
      dimensions = dim
    } else {
      dimensions = Array(0 ..< x.ndim)
    }

    if p == 1 {
      return MLX.sum(MLX.abs(x), axes: dimensions, keepDims: keepdim)
    } else {
      return MLX.sqrt(MLX.sum(x * x, axes: dimensions, keepDims: keepdim))
    }
  }

  static func weightNorm(
    weightV: MLXArray,
    weightG: MLXArray,
    dim: Int? = nil
  ) -> MLXArray {
    let rank = weightV.shape.count

    var axes: [Int]

    if let dim = dim {
      var adjustedDim = dim
      if dim < 0 {
        adjustedDim += rank
      }

      axes = Array(0 ..< rank)
      if adjustedDim != -1 {
        axes.removeAll(where: { $0 == adjustedDim })
      }
    } else {
      axes = Array(0 ..< rank)
    }

    let normV = computeNorm(x: weightV, p: 2, dim: axes, keepdim: true)

    let normalizedWeight = weightV / (normV + 1e-7)
    return normalizedWeight * weightG
  }

  public func callAsFunction(_ x: MLXArray, conv: (MLXArray, MLXArray, Int, Int, Int, Int, StreamOrDevice) -> MLXArray) -> MLXArray {
    applyConv(x: x, weight: normalizedWeight, bias: shapedBias) { input, weightToUse in
      conv(
        input,
        weightToUse,
        self.stride,
        padding,
        dilation,
        groups,
        .default
      )
    }
  }

  public func callAsFunction(_ x: MLXArray, conv: (MLXArray, MLXArray, Int, Int, Int, Int, Int, StreamOrDevice) -> MLXArray) -> MLXArray {
    applyConv(x: x, weight: normalizedWeight, bias: shapedBias) { input, weightToUse in
      conv(
        input,
        weightToUse,
        self.stride,
        padding,
        dilation,
        outputPadding,
        groups,
        .default
      )
    }
  }

  private func applyConv(
    x: MLXArray,
    weight: MLXArray,
    bias: MLXArray?,
    conv: (MLXArray, MLXArray) -> MLXArray
  ) -> MLXArray {
    let weightToUse: MLXArray
    if x.shape.last == weight.shape.last || groups > 1 {
      weightToUse = weight
    } else {
      weightToUse = weight.transposed()
    }

    let result = conv(x, weightToUse)
    if let bias {
      return result + bias
    }
    return result
  }
}
