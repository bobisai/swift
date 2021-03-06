//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Swift

/// A service which can execute jobs.
@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public protocol Executor: AnyObject, Sendable {
  func enqueue(_ job: UnownedJob)
}

/// A service which can execute jobs.
@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public protocol SerialExecutor: Executor {
  // This requirement is repeated here as a non-override so that we
  // get a redundant witness-table entry for it.  This allows us to
  // avoid drilling down to the base conformance just for the basic
  // work-scheduling operation.
  @_nonoverride
  func enqueue(_ job: UnownedJob)

  /// Convert this executor value to the optimized form of borrowed
  /// executor references.
  func asUnownedSerialExecutor() -> UnownedSerialExecutor
}

/// An unowned reference to a serial executor (a `SerialExecutor`
/// value).
///
/// This is an optimized type used internally by the core scheduling
/// operations.  It is an unowned reference to avoid unnecessary
/// reference-counting work even when working with actors abstractly.
/// Generally there are extra constraints imposed on core operations
/// in order to allow this.  For example, keeping an actor alive must
/// also keep the actor's associated executor alive; if they are
/// different objects, the executor must be referenced strongly by the
/// actor.
@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
@frozen
public struct UnownedSerialExecutor {
  #if compiler(>=5.5) && $BuiltinExecutor
  @usableFromInline
  internal var executor: Builtin.Executor
  #endif

  @inlinable
  internal init(_ executor: Builtin.Executor) {
    #if compiler(>=5.5) && $BuiltinExecutor
    self.executor = executor
    #endif
  }

  @inlinable
  public init<E: SerialExecutor>(ordinary executor: __shared E) {
    #if compiler(>=5.5) && $BuiltinBuildExecutor
    self.executor = Builtin.buildOrdinarySerialExecutorRef(executor)
    #else
    fatalError("Swift compiler is incompatible with this SDK version")
    #endif
  }
}

// Used by the concurrency runtime
@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
@_silgen_name("_swift_task_enqueueOnExecutor")
internal func _enqueueOnExecutor<E>(job: UnownedJob, executor: E)
where E: SerialExecutor {
  executor.enqueue(job)
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
@_transparent
public // COMPILER_INTRINSIC
func _checkExpectedExecutor(_filenameStart: Builtin.RawPointer,
                            _filenameLength: Builtin.Word,
                            _filenameIsASCII: Builtin.Int1,
                            _line: Builtin.Word,
                            _executor: Builtin.Executor) {
  if _taskIsCurrentExecutor(_executor) {
    return
  }

  _reportUnexpectedExecutor(
    _filenameStart, _filenameLength, _filenameIsASCII, _line, _executor)
}
