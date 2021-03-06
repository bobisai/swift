// RUN: %target-typecheck-verify-swift -enable-experimental-concurrency

// REQUIRES: concurrency

func f() async -> Int { 0 }

_ = await f() // expected-error{{'async' call in a function that does not support concurrency}}

spawn let y = await f() // expected-error{{'spawn let' in a function that does not support concurrency}}
// expected-error@-1{{'async' call in a function that does not support concurrency}}
