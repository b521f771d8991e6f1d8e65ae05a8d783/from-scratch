import Testing
@testable import swift

@Test func example() async throws {
    let result = get1()
    assert(result == 1)
}
