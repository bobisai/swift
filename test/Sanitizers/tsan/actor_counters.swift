// RUN: %target-run-simple-swift(-Xfrontend -enable-experimental-concurrency %import-libdispatch -parse-as-library -sanitize=thread)

// REQUIRES: executable_test
// REQUIRES: concurrency
// REQUIRES: libdispatch
// REQUIRES: tsan_runtime
// UNSUPPORTED: linux
// UNSUPPORTED: windows

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
actor Counter {
  private var value = 0
  private let scratchBuffer: UnsafeMutableBufferPointer<Int>

  init(maxCount: Int) {
    scratchBuffer = .allocate(capacity: maxCount)
    scratchBuffer.initialize(repeating: 0)
  }

  func next() -> Int {
    let current = value

    // Make sure we haven't produced this value before
    assert(scratchBuffer[current] == 0)
    scratchBuffer[current] = 1

    value = value + 1
    return current
  }

  deinit {
      for i in 0..<value {
          assert(scratchBuffer[i] == 1)
      }
  }
}


@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
func worker(identity: Int, counters: [Counter], numIterations: Int) async {
  for i in 0..<numIterations {
    let counterIndex = Int.random(in: 0 ..< counters.count)
    let counter = counters[counterIndex]
    let nextValue = await counter.next()
    print("Worker \(identity) calling counter \(counterIndex) produced \(nextValue)")
  }
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
func runTest(numCounters: Int, numWorkers: Int, numIterations: Int) async {
  // Create counter actors.
  var counters: [Counter] = []
  for i in 0..<numCounters {
    counters.append(Counter(maxCount: numWorkers * numIterations))
  }

  // Create a bunch of worker threads.
  var workers: [Task.Handle<Void, Error>] = []
  for i in 0..<numWorkers {
    workers.append(
      detach { [counters] in
        usleep(UInt32.random(in: 0..<100) * 1000)
        await worker(identity: i, counters: counters, numIterations: numIterations)
      }
    )
  }

  // Wait until all of the workers have finished.
  for worker in workers {
    try! await worker.get()
  }

  print("DONE!")
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
@main struct Main {
  static func main() async {
    // Useful for debugging: specify counter/worker/iteration counts
    let args = CommandLine.arguments
    let counters = args.count >= 2 ? Int(args[1])! : 10
    let workers = args.count >= 3 ? Int(args[2])! : 100
    let iterations = args.count >= 4 ? Int(args[3])! : 1000
    print("counters: \(counters), workers: \(workers), iterations: \(iterations)")
    await runTest(numCounters: counters, numWorkers: workers, numIterations: iterations)
  }
}
