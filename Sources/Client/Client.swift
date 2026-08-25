public struct Client<Input, Output, Failure: Swift.Error> {

    public var run: (Input) async throws(Failure) -> Output

    public init(
        run: @escaping (Input) async throws(Failure) -> Output
    ) {
        self.run = run
    }
}
