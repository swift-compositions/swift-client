import Client
import Testing

@Suite
struct `Client Tests` {

    @Test
    func `an infallible client runs without try`() async {
        let double = Client<Int, Int, Never>(run: { value in value * 2 })
        #expect(await double(21) == 42)
    }

    @Test
    func `a refusing client throws its declared failure`() async throws {
        enum Refusal: Swift.Error, Equatable {
            case negative
        }
        let guarded = Client<Int, Int, Refusal>(
            run: { value throws(Refusal) in
                guard value >= 0 else {
                    throw .negative
                }
                return value
            }
        )
        #expect(try await guarded(7) == 7)
        do throws(Refusal) {
            _ = try await guarded(-1)
            Issue.record("expected a refusal")
        } catch {
            #expect(error == .negative)
        }
    }
}
