import Testing
@testable import KokoroSwift

@Test func packageConfigurationLoadsFromModuleBundle() {
  let config = KokoroConfig.loadConfig()
  #expect(config.nToken > 0)
}

@Test func alignmentValuesExpandDurationsIntoContiguousOneHotRows() {
  let alignment = KokoroTTS.alignmentValues(durations: [2, 1, 3], rowCount: 3)

  #expect(alignment.totalFrames == 6)
  #expect(alignment.values == [
    1, 1, 0, 0, 0, 0,
    0, 0, 1, 0, 0, 0,
    0, 0, 0, 1, 1, 1,
  ])
}

@Test func alignmentValuesPreserveUnusedRowsAndMinimumDurations() {
  let alignment = KokoroTTS.alignmentValues(durations: [1, 1, 1], rowCount: 5)

  #expect(alignment.totalFrames == 3)
  #expect(alignment.values == [
    1, 0, 0,
    0, 1, 0,
    0, 0, 1,
    0, 0, 0,
    0, 0, 0,
  ])
}

@Test func alignmentValuesHandleVariedDurationsDeterministically() {
  let durations: [Int32] = [4, 2, 7, 1, 3, 5, 2]
  let first = KokoroTTS.alignmentValues(durations: durations, rowCount: durations.count)
  let second = KokoroTTS.alignmentValues(durations: durations, rowCount: durations.count)

  #expect(first.totalFrames == 24)
  #expect(first.values == second.values)
  #expect(first.values.filter { $0 == 1 }.count == 24)
  #expect(first.values.allSatisfy { $0 == 0 || $0 == 1 })
}

@Test func durationBudgetAcceptsBoundary() throws {
  try KokoroTTS.validateDurationBudget(totalFrames: 700, maximumFrames: 700)
}

@Test func durationBudgetRejectsFirstFrameOverBoundary() {
  #expect(throws: KokoroTTS.KokoroTTSError.durationLimitExceeded(
    totalFrames: 701,
    maximumFrames: 700
  )) {
    try KokoroTTS.validateDurationBudget(totalFrames: 701, maximumFrames: 700)
  }
}

@Test func durationBudgetRejectsInvalidMaximum() {
  #expect(throws: KokoroTTS.KokoroTTSError.durationLimitExceeded(
    totalFrames: 0,
    maximumFrames: 0
  )) {
    try KokoroTTS.validateDurationBudget(totalFrames: 0, maximumFrames: 0)
  }
}
