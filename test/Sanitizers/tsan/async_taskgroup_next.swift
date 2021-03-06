// RUN: %target-run-simple-swift(-Xfrontend -enable-experimental-concurrency %import-libdispatch -parse-as-library -sanitize=thread)

// REQUIRES: executable_test
// REQUIRES: concurrency
// REQUIRES: libdispatch
// REQUIRES: tsan_runtime
// UNSUPPORTED: use_os_stdlib

var scratchBuffer: UnsafeMutableBufferPointer<Int> = .allocate(capacity: 1000)

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
func completeFastOrSlow(n: Int) async -> Int {
  if n % 2 == 0 {
    await Task.sleep(2_000_000_000)
  }
  assert(scratchBuffer[n] == 6)
  scratchBuffer[n] = 7
  return n
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
func test_sum_nextOnCompletedOrPending() async {
  scratchBuffer.initialize(repeating: 0)

  let numbers = 0..<1000
  let expected = 499_500

  let sum = await withTaskGroup(of: Int.self) { (group) async -> Int in
    for n in numbers {
      scratchBuffer[n] = 6
      await group.spawn {
        let res = await completeFastOrSlow(n: n)
        return res
      }
    }

    // We want to await on completed and pending child tasks.  This gives the
    // fast tasks some time to complete before we call group.next().
    await Task.sleep(1_000_000_000)

    var sum = 0
    while let r = try! await group.next() {
      assert(scratchBuffer[r] == 7)
      sum += r
    }

    assert(group.isEmpty, "Group must be empty after we consumed all tasks")

    print("task group returning: \(sum)")
    return sum
  }

  print("result: \(sum)")
  assert(sum == expected, "Expected: \(expected), got: \(sum)")
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
@main struct Main {
  static func main() async {
    await test_sum_nextOnCompletedOrPending()
  }
}
