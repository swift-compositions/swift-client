import Client
import Either
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

@Suite
struct `Client promoted Tests` {

    enum Refusal: Swift.Error, Equatable {
        case negative
    }

    enum Outage: Swift.Error, Equatable {
        case down
    }

    static var guarded: Client<Int, Int, Refusal> {
        .init(
            run: { value throws(Refusal) in
                guard value >= 0 else {
                    throw .negative
                }
                return value
            }
        )
    }

    @Test
    func `promotion embeds the domain refusal on the right`() async throws {
        let promoted: Client<Int, Int, Either<Outage, Refusal>> = Self.guarded.promoted()
        #expect(try await promoted(7) == 7)
        do throws(Either<Outage, Refusal>) {
            _ = try await promoted(-1)
            Issue.record("expected a refusal")
        } catch {
            #expect(error == .right(.negative))
        }
    }
}

@Suite
struct `Client collapsed Tests` {

    enum Refusal: Swift.Error, Equatable {
        case negative
    }

    enum Outage: Swift.Error, Equatable {
        case down
    }

    static var guarded: Client<Int, Int, Refusal> {
        .init(
            run: { value throws(Refusal) in
                guard value >= 0 else {
                    throw .negative
                }
                return value
            }
        )
    }

    @Test
    func `a promoted client collapses back to the domain refusal`() async {
        let promoted: Client<Int, Int, Either<Swift.Never, Refusal>> = Self.guarded.promoted()
        let back: Client<Int, Int, Refusal> = promoted.collapsed()
        do throws(Refusal) {
            _ = try await back(-1)
            Issue.record("expected a refusal")
        } catch {
            #expect(error == .negative)
        }
    }

    @Test
    func `an infallible remote row collapses to the external failure alone`() async {
        let failing = Client<Int, Int, Either<Outage, Swift.Never>>(
            run: { _ throws(Either<Outage, Swift.Never>) in
                throw .left(.down)
            }
        )
        let collapsed: Client<Int, Int, Outage> = failing.collapsed()
        do throws(Outage) {
            _ = try await collapsed(1)
            Issue.record("expected an outage")
        } catch {
            #expect(error == .down)
        }
    }
}
