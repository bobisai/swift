// RUN: %empty-directory(%t)

enum CustomError: Error {
  case invalid
  case insecure
}

typealias SomeCallback = (String) -> Void
typealias SomeResultCallback = (Result<String, CustomError>) -> Void
typealias NestedAliasCallback = SomeCallback

// 1. Check various functions for having/not having async alternatives

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+4):1 | %FileCheck -check-prefix=ASYNC-SIMPLE %s
// RUN: %refactor -add-async-alternative -dump-text -source-filename %s -pos=%(line+3):6 | %FileCheck -check-prefix=ASYNC-SIMPLE %s
// RUN: %refactor -add-async-alternative -dump-text -source-filename %s -pos=%(line+2):12 | %FileCheck -check-prefix=ASYNC-SIMPLE %s
// RUN: %refactor -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):13 | %FileCheck -check-prefix=ASYNC-SIMPLE %s
func simple(completion: (String) -> Void) { }
// ASYNC-SIMPLE: basic.swift [[# @LINE-1]]:1 -> [[# @LINE-1]]:1
// ASYNC-SIMPLE-NEXT: @available(*, deprecated, message: "Prefer async alternative instead")
// ASYNC-SIMPLE-EMPTY:
// ASYNC-SIMPLE-NEXT: basic.swift [[# @LINE-4]]:43 -> [[# @LINE-4]]:46
// ASYNC-SIMPLE-NEXT: {
// ASYNC-SIMPLE-NEXT: async {
// ASYNC-SIMPLE-NEXT: let result = await simple()
// ASYNC-SIMPLE-NEXT: completion(result)
// ASYNC-SIMPLE-NEXT: }
// ASYNC-SIMPLE-NEXT: }
// ASYNC-SIMPLE-EMPTY:
// ASYNC-SIMPLE-NEXT: basic.swift [[# @LINE-12]]:46 -> [[# @LINE-12]]:46
// ASYNC-SIMPLE-EMPTY:
// ASYNC-SIMPLE-EMPTY:
// ASYNC-SIMPLE-EMPTY:
// ASYNC-SIMPLE-NEXT: basic.swift [[# @LINE-16]]:46 -> [[# @LINE-16]]:46
// ASYNC-SIMPLE-NEXT: func simple() async -> String { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=ASYNC-SIMPLENOLABEL %s
func simpleWithoutLabel(_ completion: (String) -> Void) { }
// ASYNC-SIMPLENOLABEL: {
// ASYNC-SIMPLENOLABEL-NEXT: async {
// ASYNC-SIMPLENOLABEL-NEXT: let result = await simpleWithoutLabel()
// ASYNC-SIMPLENOLABEL-NEXT: completion(result)
// ASYNC-SIMPLENOLABEL-NEXT: }
// ASYNC-SIMPLENOLABEL-NEXT: }
// ASYNC-SIMPLENOLABEL: func simpleWithoutLabel() async -> String { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=ASYNC-SIMPLEWITHARG %s
func simpleWithArg(a: Int, completion: (String) -> Void) { }
// ASYNC-SIMPLEWITHARG: {
// ASYNC-SIMPLEWITHARG-NEXT: async {
// ASYNC-SIMPLEWITHARG-NEXT: let result = await simpleWithArg(a: a)
// ASYNC-SIMPLEWITHARG-NEXT: completion(result)
// ASYNC-SIMPLEWITHARG-NEXT: }
// ASYNC-SIMPLEWITHARG-NEXT: }
// ASYNC-SIMPLEWITHARG: func simpleWithArg(a: Int) async -> String { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=ASYNC-MULTIPLERESULTS %s
func multipleResults(completion: (String, Int) -> Void) { }
// ASYNC-MULTIPLERESULTS: {
// ASYNC-MULTIPLERESULTS-NEXT: async {
// ASYNC-MULTIPLERESULTS-NEXT: let result = await multipleResults()
// ASYNC-MULTIPLERESULTS-NEXT: completion(result.0, result.1)
// ASYNC-MULTIPLERESULTS-NEXT: }
// ASYNC-MULTIPLERESULTS-NEXT: }
// ASYNC-MULTIPLERESULTS: func multipleResults() async -> (String, Int) { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=ASYNC-NONOPTIONALERROR %s
func nonOptionalError(completion: (String, Error) -> Void) { }
// ASYNC-NONOPTIONALERROR: {
// ASYNC-NONOPTIONALERROR-NEXT: async {
// ASYNC-NONOPTIONALERROR-NEXT: let result = await nonOptionalError()
// ASYNC-NONOPTIONALERROR-NEXT: completion(result.0, result.1)
// ASYNC-NONOPTIONALERROR-NEXT: }
// ASYNC-NONOPTIONALERROR-NEXT: }
// ASYNC-NONOPTIONALERROR: func nonOptionalError() async -> (String, Error) { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=ASYNC-NOPARAMS %s
func noParams(completion: () -> Void) { }
// ASYNC-NOPARAMS: {
// ASYNC-NOPARAMS-NEXT: async {
// ASYNC-NOPARAMS-NEXT: await noParams()
// ASYNC-NOPARAMS-NEXT: completion()
// ASYNC-NOPARAMS-NEXT: }
// ASYNC-NOPARAMS-NEXT: }
// ASYNC-NOPARAMS: func noParams() async { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=ASYNC-ERROR %s
func error(completion: (String?, Error?) -> Void) { }
// ASYNC-ERROR: {
// ASYNC-ERROR-NEXT: async {
// ASYNC-ERROR-NEXT: do {
// ASYNC-ERROR-NEXT: let result = try await error()
// ASYNC-ERROR-NEXT: completion(result, nil)
// ASYNC-ERROR-NEXT: } catch {
// ASYNC-ERROR-NEXT: completion(nil, error)
// ASYNC-ERROR-NEXT: }
// ASYNC-ERROR-NEXT: }
// ASYNC-ERROR: func error() async throws -> String { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=ASYNC-ERRORONLY %s
func errorOnly(completion: (Error?) -> Void) { }
// ASYNC-ERRORONLY: {
// ASYNC-ERRORONLY-NEXT: async {
// ASYNC-ERRORONLY-NEXT: do {
// ASYNC-ERRORONLY-NEXT: try await errorOnly()
// ASYNC-ERRORONLY-NEXT: completion(nil)
// ASYNC-ERRORONLY-NEXT: } catch {
// ASYNC-ERRORONLY-NEXT: completion(error)
// ASYNC-ERRORONLY-NEXT: }
// ASYNC-ERRORONLY-NEXT: }
// ASYNC-ERRORONLY-NEXT: }
// ASYNC-ERRORONLY: func errorOnly() async throws { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=ASYNC-ERRORNONOPTIONALRESULT %s
func errorNonOptionalResult(completion: (String, Error?) -> Void) { }
// We cannot convert the deprecated non-async method to call the async method because we can't synthesize the non-optional completion param. Smoke check for some keywords that would indicate we rewrote the body.
// ASYNC-ERRORNONOPTIONALRESULT-NOT: detach
// ASYNC-ERRORNONOPTIONALRESULT-NOT: await
// ASYNC-ERRORNONOPTIONALRESULT: func errorNonOptionalResult() async throws -> String { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=ASYNC-CUSTOMERROR %s
func customError(completion: (String?, CustomError?) -> Void) { }
// ASYNC-CUSTOMERROR: {
// ASYNC-CUSTOMERROR-NEXT: async {
// ASYNC-CUSTOMERROR-NEXT: do {
// ASYNC-CUSTOMERROR-NEXT: let result = try await customError()
// ASYNC-CUSTOMERROR-NEXT: completion(result, nil)
// ASYNC-CUSTOMERROR-NEXT: } catch {
// ASYNC-CUSTOMERROR-NEXT: completion(nil, error as! CustomError)
// ASYNC-CUSTOMERROR-NEXT: }
// ASYNC-CUSTOMERROR-NEXT: }
// ASYNC-CUSTOMERROR-NEXT: }
// ASYNC-CUSTOMERROR: func customError() async throws -> String { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=ASYNC-ALIAS %s
func alias(completion: SomeCallback) { }
// ASYNC-ALIAS: {
// ASYNC-ALIAS-NEXT: async {
// ASYNC-ALIAS-NEXT: let result = await alias()
// ASYNC-ALIAS-NEXT: completion(result)
// ASYNC-ALIAS-NEXT: }
// ASYNC-ALIAS-NEXT: }
// ASYNC-ALIAS: func alias() async -> String { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=ASYNC-NESTEDALIAS %s
func nestedAlias(completion: NestedAliasCallback) { }
// ASYNC-NESTEDALIAS: {
// ASYNC-NESTEDALIAS-NEXT: async {
// ASYNC-NESTEDALIAS-NEXT: let result = await nestedAlias()
// ASYNC-NESTEDALIAS-NEXT: completion(result)
// ASYNC-NESTEDALIAS-NEXT: }
// ASYNC-NESTEDALIAS-NEXT: }
// ASYNC-NESTEDALIAS: func nestedAlias() async -> String { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=ASYNC-SIMPLERESULT %s
func simpleResult(completion: (Result<String, Never>) -> Void) { }
// ASYNC-SIMPLERESULT: {
// ASYNC-SIMPLERESULT-NEXT: async {
// ASYNC-SIMPLERESULT-NEXT: let result = await simpleResult()
// ASYNC-SIMPLERESULT-NEXT: completion(.success(result))
// ASYNC-SIMPLERESULT-NEXT: }
// ASYNC-SIMPLERESULT-NEXT: }
// ASYNC-SIMPLERESULT: func simpleResult() async -> String { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=ASYNC-ERRORRESULT %s
func errorResult(completion: (Result<String, Error>) -> Void) { }
// ASYNC-ERRORRESULT: {
// ASYNC-ERRORRESULT-NEXT: async {
// ASYNC-ERRORRESULT-NEXT: do {
// ASYNC-ERRORRESULT-NEXT: let result = try await errorResult()
// ASYNC-ERRORRESULT-NEXT: completion(.success(result))
// ASYNC-ERRORRESULT-NEXT: } catch {
// ASYNC-ERRORRESULT-NEXT: completion(.failure(error))
// ASYNC-ERRORRESULT-NEXT: }
// ASYNC-ERRORRESULT-NEXT: }
// ASYNC-ERRORRESULT-NEXT: }
// ASYNC-ERRORRESULT: func errorResult() async throws -> String { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=ASYNC-CUSTOMERRORRESULT %s
func customErrorResult(completion: (Result<String, CustomError>) -> Void) { }
// ASYNC-CUSTOMERRORRESULT: {
// ASYNC-CUSTOMERRORRESULT-NEXT: async {
// ASYNC-CUSTOMERRORRESULT-NEXT: do {
// ASYNC-CUSTOMERRORRESULT-NEXT: let result = try await customErrorResult()
// ASYNC-CUSTOMERRORRESULT-NEXT: completion(.success(result))
// ASYNC-CUSTOMERRORRESULT-NEXT: } catch {
// ASYNC-CUSTOMERRORRESULT-NEXT: completion(.failure(error as! CustomError))
// ASYNC-CUSTOMERRORRESULT-NEXT: }
// ASYNC-CUSTOMERRORRESULT-NEXT: }
// ASYNC-CUSTOMERRORRESULT-NEXT: }
// ASYNC-CUSTOMERRORRESULT: func customErrorResult() async throws -> String { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=ASYNC-ALIASRESULT %s
func aliasedResult(completion: SomeResultCallback) { }
// ASYNC-ALIASRESULT: {
// ASYNC-ALIASRESULT-NEXT: async {
// ASYNC-ALIASRESULT-NEXT: do {
// ASYNC-ALIASRESULT-NEXT: let result = try await aliasedResult()
// ASYNC-ALIASRESULT-NEXT: completion(.success(result))
// ASYNC-ALIASRESULT-NEXT: } catch {
// ASYNC-ALIASRESULT-NEXT: completion(.failure(error as! CustomError))
// ASYNC-ALIASRESULT-NEXT: }
// ASYNC-ALIASRESULT-NEXT: }
// ASYNC-ALIASRESULT-NEXT: }
// ASYNC-ALIASRESULT: func aliasedResult() async throws -> String { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=MANY %s
func many(_ completion: (String, Int) -> Void) { }
// MANY: {
// MANY-NEXT: async {
// MANY-NEXT: let result = await many()
// MANY-NEXT: completion(result.0, result.1)
// MANY-NEXT: }
// MANY-NEXT: }
// MANY: func many() async -> (String, Int) { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=OPTIONAL-SINGLE %s
func optionalSingle(completion: (String?) -> Void) { }
// OPTIONAL-SINGLE: {
// OPTIONAL-SINGLE-NEXT: async {
// OPTIONAL-SINGLE-NEXT: let result = await optionalSingle()
// OPTIONAL-SINGLE-NEXT: completion(result)
// OPTIONAL-SINGLE-NEXT: }
// OPTIONAL-SINGLE-NEXT: }
// OPTIONAL-SINGLE: func optionalSingle() async -> String? { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=MANY-OPTIONAL %s
func manyOptional(_ completion: (String?, Int?) -> Void) { }
// MANY-OPTIONAL: {
// MANY-OPTIONAL-NEXT: async {
// MANY-OPTIONAL-NEXT: let result = await manyOptional()
// MANY-OPTIONAL-NEXT: completion(result.0, result.1)
// MANY-OPTIONAL-NEXT: }
// MANY-OPTIONAL-NEXT: }
// MANY-OPTIONAL: func manyOptional() async -> (String?, Int?) { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=GENERIC %s
func generic<T, R>(completion: (T, R) -> Void) { }
// GENERIC: {
// GENERIC-NEXT: async {
// GENERIC-NEXT: let result: (T, R) = await generic()
// GENERIC-NEXT: completion(result.0, result.1)
// GENERIC-NEXT: }
// GENERIC-NEXT: }
// GENERIC: func generic<T, R>() async -> (T, R) { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=GENERIC-RESULT %s
func genericResult<T>(completion: (T?, Error?) -> Void) where T: Numeric { }
// GENERIC-RESULT: {
// GENERIC-RESULT-NEXT: async {
// GENERIC-RESULT-NEXT: do {
// GENERIC-RESULT-NEXT: let result: T = try await genericResult()
// GENERIC-RESULT-NEXT: completion(result, nil)
// GENERIC-RESULT-NEXT: } catch {
// GENERIC-RESULT-NEXT: completion(nil, error)
// GENERIC-RESULT-NEXT: }
// GENERIC-RESULT-NEXT: }
// GENERIC-RESULT-NEXT: }
// GENERIC-RESULT: func genericResult<T>() async throws -> T where T: Numeric { }

// FIXME: This doesn't compile after refactoring because we aren't using the generic argument `E` in the async method (SR-14560)
// RUN: %refactor -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=GENERIC-ERROR %s
func genericError<E>(completion: (String?, E?) -> Void) where E: Error { }
// GENERIC-ERROR: {
// GENERIC-ERROR-NEXT: async {
// GENERIC-ERROR-NEXT: do {
// GENERIC-ERROR-NEXT: let result: String = try await genericError()
// GENERIC-ERROR-NEXT: completion(result, nil)
// GENERIC-ERROR-NEXT: } catch {
// GENERIC-ERROR-NEXT: completion(nil, error as! E)
// GENERIC-ERROR-NEXT: }
// GENERIC-ERROR-NEXT: }
// GENERIC-ERROR-NEXT: }
// GENERIC-ERROR: func genericError<E>() async throws -> String where E: Error { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=OTHER-NAME %s
func otherName(execute: (String) -> Void) { }
// OTHER-NAME: {
// OTHER-NAME-NEXT: async {
// OTHER-NAME-NEXT: let result = await otherName()
// OTHER-NAME-NEXT: execute(result)
// OTHER-NAME-NEXT: }
// OTHER-NAME-NEXT: }
// OTHER-NAME: func otherName() async -> String { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix=DEFAULT_ARGS %s
func defaultArgs(a: Int, b: Int = 10, completion: (String) -> Void) { }
// DEFAULT_ARGS: {
// DEFAULT_ARGS-NEXT: async {
// DEFAULT_ARGS-NEXT: let result = await defaultArgs(a: a, b: b)
// DEFAULT_ARGS-NEXT: completion(result)
// DEFAULT_ARGS-NEXT: }
// DEFAULT_ARGS-NEXT: }
// DEFAULT_ARGS: func defaultArgs(a: Int, b: Int = 10) async -> String { }

struct MyStruct {
  var someVar: (Int) -> Void {
    get {
      return {_ in }
    }
    // RUN: not %refactor -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):5
    set (completion) {
    }
  }

  init() { }

  // RUN: not %refactor -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):3
  init(completion: (String) -> Void) { }

  func retSelf() -> MyStruct { return self }

  // RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):10 | %FileCheck -check-prefix=MODIFIERS %s
  public func publicMember(completion: (String) -> Void) { }
  // MODIFIERS: public func publicMember() async -> String { }

  // RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):3 | %FileCheck -check-prefix=STATIC %s
  static func staticMember(completion: (String) -> Void) { }
  // STATIC: static func staticMember() async -> String { }

  // RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+2):11 | %FileCheck -check-prefix=DEPRECATED %s
  @available(*, deprecated, message: "Deprecated")
  private func deprecated(completion: (String) -> Void) { }
  // DEPRECATED: @available(*, deprecated, message: "Deprecated")
  // DEPRECATED-NEXT: private func deprecated() async -> String { }
}
func retStruct() -> MyStruct { return MyStruct() }

protocol MyProtocol {
  // RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+2):3 | %FileCheck -check-prefix=PROTO-MEMBER %s
  // RUN: %refactor-check-compiles -convert-to-async -dump-text -source-filename %s -pos=%(line+1):3 | %FileCheck -check-prefix=PROTO-MEMBER %s
  func protoMember(completion: (String) -> Void)
  // PROTO-MEMBER: func protoMember() async -> String{{$}}
}

// RUN: not %refactor -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1
func nonCompletion(a: Int) { }

// RUN: not %refactor -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1
func multipleResults(completion: (Result<String, Error>, Result<String, Error>) -> Void) { }

// RUN: not %refactor -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1
func completionNotLast(completion: (String) -> Void, a: Int) { }

// RUN: not %refactor -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1
func nonVoid(completion: (String) -> Void) -> Int { return 0 }

// RUN: not %refactor -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1
func completionNonVoid(completion: (String) -> Int) -> Void { }

// RUN: not %refactor -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1
func alreadyThrows(completion: (String) -> Void) throws { }

// RUN: not %refactor -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1
func noParamAutoclosure(completion: @autoclosure () -> Void) { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix BLOCK-CONVENTION %s
func blockConvention(completion: @convention(block) () -> Void) { }
// BLOCK-CONVENTION: func blockConvention() async { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix C-CONVENTION %s
func cConvention(completion: @convention(c) () -> Void) { }
// C-CONVENTION: func cConvention() async { }

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix VOID-HANDLER %s
func voidCompletion(completion: (Void) -> Void) {}
// VOID-HANDLER: {
// VOID-HANDLER-NEXT: async {
// VOID-HANDLER-NEXT: await voidCompletion()
// VOID-HANDLER-NEXT: completion(())
// VOID-HANDLER-NEXT: }
// VOID-HANDLER-NEXT: }
// VOID-HANDLER: func voidCompletion() async {}

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix VOID-AND-ERROR-HANDLER %s
func voidAndErrorCompletion(completion: (Void?, Error?) -> Void) {}
// VOID-AND-ERROR-HANDLER: {
// VOID-AND-ERROR-HANDLER-NEXT: async {
// VOID-AND-ERROR-HANDLER-NEXT: do {
// VOID-AND-ERROR-HANDLER-NEXT: try await voidAndErrorCompletion()
// VOID-AND-ERROR-HANDLER-NEXT: completion((), nil)
// VOID-AND-ERROR-HANDLER-NEXT: } catch {
// VOID-AND-ERROR-HANDLER-NEXT: completion(nil, error)
// VOID-AND-ERROR-HANDLER-NEXT: }
// VOID-AND-ERROR-HANDLER-NEXT: }
// VOID-AND-ERROR-HANDLER-NEXT: }
// VOID-AND-ERROR-HANDLER: func voidAndErrorCompletion() async throws {}

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix TOO-MUCH-VOID-AND-ERROR-HANDLER %s
func tooMuchVoidAndErrorCompletion(completion: (Void?, Void?, Error?) -> Void) {}
// TOO-MUCH-VOID-AND-ERROR-HANDLER: {
// TOO-MUCH-VOID-AND-ERROR-HANDLER-NEXT: async {
// TOO-MUCH-VOID-AND-ERROR-HANDLER-NEXT: do {
// TOO-MUCH-VOID-AND-ERROR-HANDLER-NEXT: try await tooMuchVoidAndErrorCompletion()
// TOO-MUCH-VOID-AND-ERROR-HANDLER-NEXT: completion((), (), nil)
// TOO-MUCH-VOID-AND-ERROR-HANDLER-NEXT: } catch {
// TOO-MUCH-VOID-AND-ERROR-HANDLER-NEXT: completion(nil, nil, error)
// TOO-MUCH-VOID-AND-ERROR-HANDLER-NEXT: }
// TOO-MUCH-VOID-AND-ERROR-HANDLER-NEXT: }
// TOO-MUCH-VOID-AND-ERROR-HANDLER-NEXT: }
// TOO-MUCH-VOID-AND-ERROR-HANDLER: func tooMuchVoidAndErrorCompletion() async throws {}

// RUN: %refactor-check-compiles -add-async-alternative -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefix VOID-PROPER-AND-ERROR-HANDLER %s
func tooVoidProperAndErrorCompletion(completion: (Void?, String?, Error?) -> Void) {}
// VOID-PROPER-AND-ERROR-HANDLER: {
// VOID-PROPER-AND-ERROR-HANDLER-NEXT: async {
// VOID-PROPER-AND-ERROR-HANDLER-NEXT: do {
// VOID-PROPER-AND-ERROR-HANDLER-NEXT: let result = try await tooVoidProperAndErrorCompletion()
// VOID-PROPER-AND-ERROR-HANDLER-NEXT: completion((), result.1, nil)
// VOID-PROPER-AND-ERROR-HANDLER-NEXT: } catch {
// VOID-PROPER-AND-ERROR-HANDLER-NEXT: completion(nil, nil, error)
// VOID-PROPER-AND-ERROR-HANDLER-NEXT: }
// VOID-PROPER-AND-ERROR-HANDLER-NEXT: }
// VOID-PROPER-AND-ERROR-HANDLER-NEXT: }
// VOID-PROPER-AND-ERROR-HANDLER: func tooVoidProperAndErrorCompletion() async throws -> (Void, String) {}

// 2. Check that the various ways to call a function (and the positions the
//    refactoring is called from) are handled correctly

class MyClass {}

func simpleClassParam(completion: (MyClass) -> Void) { }

// TODO: We cannot check that the refactored code compiles because 'simple' and
// friends aren't refactored when only invoking the refactoring on this function.
// TODO: When changing this line to %refactor-check-compiles, 'swift-refactor'
// is crashing in '-dump-rewritten'. This is because
// 'swift-refactor -dump-rewritten' is removing 'RUN' lines. After removing
// those lines, we are trying to remove the function body, using its length
// before the 'RUN' lines were removed, thus pointing past the end of the
// rewritten buffer.

// RUN: %refactor -convert-to-async -dump-text -source-filename %s -pos=%(line+1):1 | %FileCheck -check-prefixes=CONVERT-FUNC,CALL,CALL-NOLABEL,CALL-WRAPPED,TRAILING,TRAILING-PARENS,TRAILING-WRAPPED,CALL-ARG,MANY-CALL,MEMBER-CALL,MEMBER-CALL2,MEMBER-PARENS,EMPTY-CAPTURE,CAPTURE,DEFAULT-ARGS-MISSING,DEFAULT-ARGS-CALL,BLOCK-CONVENTION-CALL,C-CONVENTION-CALL %s
func testCalls() {
// CONVERT-FUNC: {{^}}func testCalls() async {
  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+4):3 | %FileCheck -check-prefix=CALL %s
  // RUN: not %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+3):10
  // RUN: not %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+2):24
  // RUN: not %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):28
  simple(completion: { str in
    // RUN: not %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):5
    print("with label")
  })
  // CALL: let str = await simple(){{$}}
  // CALL-NEXT: {{^}}print("with label")

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):3 | %FileCheck -check-prefix=CALL-NOLABEL %s
  simpleWithoutLabel({ str in
    print("without label")
  })
  // CALL-NOLABEL: let str = await simpleWithoutLabel(){{$}}
  // CALL-NOLABEL-NEXT: {{^}}print("without label")

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+2):3 | %FileCheck -check-prefix=CALL-WRAPPED %s
  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):5 | %FileCheck -check-prefix=CALL-WRAPPED %s
  ((simple))(completion: { str in
    print("wrapped call")
  })
  // CALL-WRAPPED: let str = await ((simple))(){{$}}
  // CALL-WRAPPED-NEXT: {{^}}print("wrapped call")

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+2):3 | %FileCheck -check-prefix=TRAILING %s
  // RUN: not %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):12
  simple { str in
    print("trailing")
  }
  // TRAILING: let str = await simple(){{$}}
  // TRAILING-NEXT: {{^}}print("trailing")

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):3 | %FileCheck -check-prefix=TRAILING-PARENS %s
  simple() { str in
    print("trailing with parens")
  }
  // TRAILING-PARENS: let str = await simple(){{$}}
  // TRAILING-PARENS-NEXT: {{^}}print("trailing with parens")

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):5 | %FileCheck -check-prefix=TRAILING-WRAPPED %s
  ((simple)) { str in
    print("trailing with wrapped call")
  }
  // TRAILING-WRAPPED: let str = await ((simple))(){{$}}
  // TRAILING-WRAPPED-NEXT: {{^}}print("trailing with wrapped call")

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+3):3 | %FileCheck -check-prefix=CALL-ARG %s
  // RUN: not %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+2):17
  // RUN: not %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):20
  simpleWithArg(a: 10) { str in
    print("with arg")
  }
  // CALL-ARG: let str = await simpleWithArg(a: 10){{$}}
  // CALL-ARG-NEXT: {{^}}print("with arg")

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):3 | %FileCheck -check-prefix=MANY-CALL %s
  many { str, num in
    print("many")
  }
  // MANY-CALL: let (str, num) = await many(){{$}}
  // MANY-CALL-NEXT: {{^}}print("many")

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+2):15 | %FileCheck -check-prefix=MEMBER-CALL %s
  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):3 | %FileCheck -check-prefix=MEMBER-CALL %s
  retStruct().publicMember { str in
    print("call on member")
  }
  // MEMBER-CALL: let str = await retStruct().publicMember(){{$}}
  // MEMBER-CALL-NEXT: {{^}}print("call on member")

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):25 | %FileCheck -check-prefix=MEMBER-CALL2 %s
  retStruct().retSelf().publicMember { str in
    print("call on member 2")
  }
  // MEMBER-CALL2: let str = await retStruct().retSelf().publicMember(){{$}}
  // MEMBER-CALL2-NEXT: {{^}}print("call on member 2")

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+3):3 | %FileCheck -check-prefix=MEMBER-PARENS %s
  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+2):5 | %FileCheck -check-prefix=MEMBER-PARENS %s
  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):15 | %FileCheck -check-prefix=MEMBER-PARENS %s
  (((retStruct().retSelf()).publicMember)) { str in
    print("call on member parens")
  }
  // MEMBER-PARENS: let str = await (((retStruct().retSelf()).publicMember))(){{$}}
  // MEMBER-PARENS-NEXT: {{^}}print("call on member parens")

  // RUN: not %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):13
  let _: Void = simple { str in
    print("assigned")
  }
  // CONVERT-FUNC: let _: Void = simple { str in{{$}}
  // CONVERT-FUNC-NEXT: print("assigned"){{$}}
  // CONVERT-FUNC-NEXT: }{{$}}

  // RUN: not %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):3
  noParamAutoclosure(completion: print("autoclosure"))
  // CONVERT-FUNC: noParamAutoclosure(completion: print("autoclosure")){{$}}

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):3 | %FileCheck -check-prefix=EMPTY-CAPTURE %s
  simple { [] str in
    print("closure with empty capture list")
  }
  // EMPTY-CAPTURE: let str = await simple(){{$}}
  // EMPTY-CAPTURE-NEXT: {{^}}print("closure with empty capture list")

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+2):3 | %FileCheck -check-prefix=CAPTURE %s
  let myClass = MyClass()
  simpleClassParam { [unowned myClass] str in
    print("closure with capture list \(myClass)")
  }
  // CAPTURE: let str = await simpleClassParam(){{$}}
  // CAPTURE-NEXT: {{^}}print("closure with capture list \(myClass)")

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):3 | %FileCheck -check-prefix=OTHER-DIRECT %s
  otherName(execute: { str in
    print("otherName")
  })
  // OTHER-DIRECT: let str = await otherName(){{$}}
  // OTHER-DIRECT-NEXT: {{^}}print("otherName")
  // CONVERT-FUNC: otherName(execute: { str in{{$}}
  // CONVERT-FUNC-NEXT: print("otherName"){{$}}
  // CONVERT-FUNC-NEXT: }){{$}}

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):3 | %FileCheck -check-prefix=DEFAULT-ARGS-MISSING %s
  defaultArgs(a: 1) { str in
    print("defaultArgs missing")
  }
  // DEFAULT-ARGS-MISSING: let str = await defaultArgs(a: 1){{$}}
  // DEFAULT-ARGS-MISSING-NEXT: {{^}}print("defaultArgs missing")

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):3 | %FileCheck -check-prefix=DEFAULT-ARGS-CALL %s
  defaultArgs(a: 1, b: 2) { str in
    print("defaultArgs")
  }
  // DEFAULT-ARGS-CALL: let str = await defaultArgs(a: 1, b: 2){{$}}
  // DEFAULT-ARGS-CALL-NEXT: {{^}}print("defaultArgs")

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):3 | %FileCheck -check-prefix=BLOCK-CONVENTION-CALL %s
  blockConvention {
    print("blockConvention")
  }
  // BLOCK-CONVENTION-CALL: await blockConvention(){{$}}
  // BLOCK-CONVENTION-CALL-NEXT: {{^}}print("blockConvention")

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):3 | %FileCheck -check-prefix=C-CONVENTION-CALL %s
  cConvention {
    print("cConvention")
  }
  // C-CONVENTION-CALL: await cConvention(){{$}}
  // C-CONVENTION-CALL-NEXT: {{^}}print("cConvention")

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):3 | %FileCheck -check-prefix=VOID-AND-ERROR-CALL %s
  voidAndErrorCompletion { v, err in
    print("void and error completion \(v)")
  }
  // VOID-AND-ERROR-CALL: {{^}}try await voidAndErrorCompletion(){{$}}
  // VOID-AND-ERROR-CALL: {{^}}print("void and error completion \(<#v#>)"){{$}}

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):3 | %FileCheck -check-prefix=VOID-AND-ERROR-CALL2 %s
  voidAndErrorCompletion { _, err in
    print("void and error completion 2")
  }
  // VOID-AND-ERROR-CALL2: {{^}}try await voidAndErrorCompletion(){{$}}
  // VOID-AND-ERROR-CALL2: {{^}}print("void and error completion 2"){{$}}

  // RUN: %refactor -convert-call-to-async-alternative -dump-text -source-filename %s -pos=%(line+1):3 | %FileCheck -check-prefix=VOID-AND-ERROR-CALL3 %s
  tooMuchVoidAndErrorCompletion { v, v1, err in
    print("void and error completion 3")
  }
  // VOID-AND-ERROR-CALL3: {{^}}try await tooMuchVoidAndErrorCompletion(){{$}}
  // VOID-AND-ERROR-CALL3: {{^}}print("void and error completion 3"){{$}}
}
// CONVERT-FUNC: {{^}}}
