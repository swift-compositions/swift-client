extension Client {

    @inlinable
    public func callAsFunction(_ input: Input) async throws(Failure) -> Output {
        try await run(input)
    }
}
