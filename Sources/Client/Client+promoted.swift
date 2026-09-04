public import Either

extension Client {

    public func promoted<External: Swift.Error>() -> Client<Input, Output, Either<External, Failure>> {
        .init(
            run: { input throws(Either<External, Failure>) in
                do throws(Failure) {
                    return try await self(input)
                } catch {
                    throw .right(error)
                }
            }
        )
    }
}
