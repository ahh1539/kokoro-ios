import Testing
@testable import KokoroSwift

@Test func packageConfigurationLoadsFromModuleBundle() {
  let config = KokoroConfig.loadConfig()
  #expect(config.nToken > 0)
}
