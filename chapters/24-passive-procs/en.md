---
chapter: 24
title: Passive Procs and Concurrency
job: Suspend and resume work with passive procs, the single mechanism standing in for both async and threaded procedures, and state the scheduling limit instead of implying parallelism.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/24-passive-procs/passive.nim]
glossary_added: [passive proc, continuation, park, scheduler, state function, trampoline]
---

# Passive Procs and Concurrency

## What this chapter is for

Nimony has one mechanism for work that pauses: the `.passive` pragma. A passive proc compiles into a state
machine that can stop at a chosen point, hand a value back to whoever runs it, and continue later from the same
line with its locals intact. There is no `async` and no `await`: the differences page says it plainly, "instead
of `async` write `passive`" (`doc/differences.md:8-11`), and the design page puts the passive proc where Nim 2 had
both async and thread procedures (`doc/design.md:97-101`).

Two things this chapter will not let you assume, because neither is true at the pin. A passive proc is not
automatically concurrent: with the default scheduler, a call from regular code runs one chain of states to its
end (`advance` moves one state), so two passive procs take turns only if the code driving them takes turns.
And a parked proc does not resume itself:
something has to hold its continuation and run it again. The chapter teaches suspension, resumption and the
scheduler boundary, and says where the limit is instead of implying work runs in parallel.

## A procedure that can pause

The pragma goes on an ordinary `proc`. Nothing else about the body changes:

```nim
import std/syncio

proc double(x: int): int {.passive.} =
  result = x * 2

echo double(21)
```

That prints `42`. Called from regular code, a passive proc that never suspends behaves like a plain call: the
caller gets the value and carries on. The compiler turns a call from a non-passive routine into a `complete`
call (`src/hexer/cps.nim:116-200`), and `complete` runs the coroutine on the caller's thread until it is done —
or, if the coroutine parks, until whoever holds its continuation resumes it (`lib/std/system.nim:340-370`).

A passive proc calling another passive proc is the normal path too, and the order is the order you wrote:

```nim
proc inner(n: int): int {.passive.} =
  echo "inner ", n
  result = n + 1

proc outer() {.passive.} =
  echo "outer start"
  let a = inner(1)
  echo "outer got ", a
  echo "outer end"

outer()
```

```
outer start
inner 1
outer got 2
outer end
```

But the call is also a suspension point. When the callee parks, the caller parks with it, and the caller's
frame waits on the heap instead of on the hardware stack (`src/hexer/cps.nim:200-210`). That is the mechanism
behind the next two sections.

## delay builds a continuation, complete runs one

`delay(call)` builds the coroutine without running it, and `complete(c)` runs it:

```nim
let c = delay(solo("a"))
echo "built, not run"
complete(c)
```

`solo("a")` prints nothing before the `complete`; the whole body runs inside `complete`. `delay` has the
signature `func delay*(x: typed): Continuation` (`lib/std/system.nim:277`), and the doc calls the result "a
continuation representation of this call" (`:272-278`). Two coroutines completed in sequence interleave
nothing:

```
start a
end a
start b
end b
```

That is the default, and it is worth reading as a rule rather than an accident. `complete` makes its own `Join`
the coroutine's caller, then trampolines the coroutine on this thread until it finishes *or parks*, and if it
parked it waits for the resumer (`lib/std/system.nim:340-370`). A parked coroutine that nothing ever resumes
turns `complete` into an infinite wait: the program prints everything up to the park and then does nothing.
That is not a deadlock the compiler can see, and it is the most common way a first passive program hangs.

So: `complete` is for coroutines that cannot park. When the callee can park, you drive it yourself, which is
the next section.

## Parking at a point you choose

`delay()` with no argument captures the rest of the current proc, from the point of the call to the next
suspension point, as a continuation (`lib/std/system.nim:272-275`). `suspend()` parks the coroutine
(`:281-283`). The pair is a handshake: capture where to come back, then park.

```nim
var resumeCont: Continuation

proc worker(name: string) {.passive.} =
  echo "start ", name
  resumeCont = delay()
  suspend()
  echo "resumed ", name
```

The compiler lowers `delay()` to a continuation pointing at the next state function, and `suspend()` to a
return of `Continuation(fn: nil, env: this)` (`src/hexer/cps.nim:264-285`). The `env` is what makes the parked
continuation distinct from a finished one:

| Continuation | `parked` | `finished` | `stopping` |
| --- | --- | --- | --- |
| nil (`fn` nil, `env` nil) | `false` | `true` | `true` |
| parked (`fn` nil, `env` set) | `true` | `false` | `true` |
| runnable (`fn` set) | `false` | `false` | `false` |

The three predicates are defined in `lib/std/system.nim:421-433`.

Both halves must be in the same body, and the pin enforces the pairing asymmetrically. A bare `suspend()` with
no preceding `delay()` is not a park at all: the compiler treats it as a synchronous transition to the next
state, so the code after it runs on the same pass (`src/hexer/cps.nim:272-280`; a probe printing before and
after a bare `suspend()` prints both lines and returns normally). A `delay()` with no following suspension
point is worse: the compiler asserts while generating code and dies with

```
'state != -1' delay() no-arg must precede suspension point
```

(`src/hexer/cps.nim:269`). One half is silently ignored, the other crashes the compiler. Write them together.

## Driving a parked coroutine

Once `worker` parks, the continuation saved in `resumeCont` is a runnable continuation: `fn` points at the
state after `suspend()`, `env` at the coroutine frame. Running it continues the proc at the line after
`suspend()`, with every local still holding its value. A driver is a loop over `advance`, which asks the
scheduler for exactly one state transition (`lib/std/system.nim:300-303`):

```nim
proc drive(c: Continuation) =
  var c = c
  while not stopping(c):
    c = advance(c)

drive(delay(worker("a")))
echo "parked"
drive(resumeCont)
echo "done"
```

```
start a
parked
resumed a
done
```

Locals survive the park because they are lifted into the coroutine frame: a counter that is `1` before
`suspend()` and is incremented after it prints `42`, not `1` and not a crash. That is the difference between a
continuation and a saved callback: the stack frame, the variables and the position all come back together.

## Two coroutines, one thread

Nothing in the language chooses an interleaving. `advance` calls the active scheduler, and the default is
`trivialTick`, which runs exactly the continuation it is given (`lib/std/system.nim:285-286`). Replace it with
`setScheduler` (`:295-298`) and you can count or redirect every step; a counting scheduler around a proc that
echoes, suspends and echoes again sees two ticks. What a scheduler cannot do by itself is make a parked
coroutine runnable again, because the resume point lives in the coroutine, not in the scheduler.

Interleaving is therefore a property of the driver, not of the pragma. Park two workers, then run their saved
continuations in the order you choose:

```nim
drive(delay(worker("a", 0)))
drive(delay(worker("b", 1)))
echo "both parked"
drive(resumeA)
drive(resumeB)
```

```
a 1
b 1
both parked
a 2
b 2
```

Both were started, both parked, and the second half of each ran after the first half of both. Swap those last two
`drive` calls and `b 2` comes first. The book's sample takes the same shape with two workers, and there
`worker c end` comes before `worker b end` because the driver resumes `c` first. The scheduler decides, and here
the scheduler is you.

The pin also carries a thread pool, `std/threadpool`, with `initPool`, `submit(continuation)` and
`shutdownPool` (`lib/std/threadpool.nim:114`, `:198`, `:376`, `:417`). A continuation submitted to the pool runs
on a worker, which is how the IO modules get resumed off the polling thread. It is a scheduler, not a promise:
two coroutines submitted to a two-worker pool can still finish one after the other, as the probe does, because
non-blocking work runs straight to its end on whichever worker picked it up. Work that blocks is where overlap
shows — two tasks that each `sleep(200)` finish together in about that time, not in twice it — so overlap is a
property of what the tasks do, and this chapter never promises it from the pragma alone. The passive-procs page
warns that a scheduler which dispatches unrelated continuations inside a trampoline keeps intermediate stack
frames alive (`doc/passive_procs.md:149-161`). This book does not teach that submitting two
procs makes them overlap. It teaches where the decision lives.

## A chain of passive procs

When a passive proc calls another, the inner park propagates outward:

```nim
proc inner() {.passive.} =
  echo "inner 1"
  innerCont = delay()
  suspend()
  echo "inner 2"

proc outer() {.passive.} =
  echo "outer 1"
  inner()
  echo "outer 2"

drive(delay(outer()))
echo "outer parked"
drive(innerCont)
```

```
outer 1
inner 1
outer parked
inner 2
outer 2
```

Resuming the inner continuation finishes the inner proc *and* continues the outer one, because each state
returns its caller's continuation when it has no next step (`src/hexer/coro_transform.nim:600-608`). One
`drive` finishes the whole chain: the chain is not a set of independent tasks, it is one coroutine stack that
lives on the heap.

## What the compiler writes

The state machine is visible in the generated C. Compiling a file with one passive proc named `worker` produces
a `workerX60Qcoro` struct holding a `CoroutineBase`, and state functions named `workerX60Qs0` and, when the
proc suspends, `workerX60Qs1`:

```
typedef struct workerX60Qcoro_0_mai3r4ykk{
CoroutineBase_0_sysvq0asl Q;
...
Continuation_0_sysvq0asl workerX60Qs0_0_mai3r4ykk(workerX60Qcoro_0_mai3r4ykk*...
Continuation_0_sysvq0asl workerX60Qs1_0_mai3r4ykk(workerX60Qcoro_0_mai3r4ykk*...
```

The frame is heap-allocated when a passive proc calls another (`allocFrame`,
`src/hexer/cps.nim:200-210`), and stack-allocated when regular code calls one, because that caller waits for
the result and its own frame is alive for the whole call (`src/hexer/cps.nim:155-200`). The heap wrapper marks its
frame by pointing `callee` at the frame itself; the stack path leaves that field nil. The marker is the whole
test: `deallocFrame` frees a frame when `callee` is not nil and does nothing otherwise
(`lib/std/system.nim:706-709`). The stack shape is safe exactly because the caller stays put for the whole call,
and it is the wrong shape for a coroutine you mean to park and resume later, where the frame would outlive the
caller.

The trampoline is what keeps deep chains from exhausting the stack: each state returns to the loop instead of
calling the next state (`doc/passive_procs.md:468-471`). A loop of one hundred thousand ordinary passive calls
runs to completion in the probe, which a recursive call chain of that length would not.

## What the pin refuses, and why

Three refusals catch Nim 2 habits before they become crashes.

A `delay` may not take a callee whose parameters alias the caller's frame. `var`, `out` and `lent` parameters
are stored as bare pointers in the coroutine frame, and the frame can outlive the call site:

```
Error: `delay` hands `bump` to a scheduler, so its continuation can outlive this frame;
parameter `x: var int64` would alias a location that is already gone. Take it as `sink` instead
```

(`src/nimony/sem.nim:3885-3906`, `:3929-3935`). The same proc called normally rather than through `delay` is
fine, because the caller's frame stays alive for the whole call. Take the parameter by `sink` when the coroutine
must own it.

A `delay` may not take a callee that returns a value or raises, because the value or the error has nowhere to
go once the building expression is gone:

```
Error: `delay` hands `calc` to a scheduler, which runs it after this expression is gone;
`calc` returns `int64`, but nothing can receive the value there. Handle it inside the task instead
```

(`src/nimony/sem.nim:3908-3927`). A value-returning passive proc is fine when called from regular code, as the
first example showed; it is `delay` that cannot carry a result. Write the result into a heap object the driver
owns, or keep it inside the task: a `sink` parameter cannot hand a value back to the caller. Or call the proc
directly and let `complete` wait.

A passive proc is not a plain proc value. `let f = worker` keeps the type `proc ... {.passive.}`, and passing
that where `proc (x: int): int {.nimcall.}` is expected is refused with ``[1] `.passive` mismatch``
(`src/nimony/sigmatch.nim:245`): the calling conventions differ, and the compiler does not coerce one to the
other. The route is a small non-passive wrapper that calls the passive proc, which is also where the `complete`
wait becomes visible.

One more rule comes from Chapter 16's single-threaded promise and applies unchanged: a passive proc that
touches a module-level mutable variable hits the unsynchronized-global check, because the coroutine may run on
another thread. The probe for
this chapter hit it while saving `delay()` into a module-level `Continuation`:

```
Error: unsynchronized access to global variable 'resumeCont'; pass it to a `.sync` routine or use
`{.cast(assumeSync).}`
```

(`src/nimony/contracts_fir.nim:4119-4128`). The sample uses `{.feature: "assumeSync".}` at module level, which
is the promise the compiler's own pool makes for itself (`lib/std/threadpool.nim:12`). In real code, hold the
continuation in a `ref object` the driver owns — a heap cell belongs to nobody else, so it needs no promise — or
keep it inside the driver. `assumeSync` is for globals that have to stay globals.

## Nim 2 delta

*What Nim 2 did:* `async` procs, `await`, futures from `std/asyncdispatch`, and `thread`/`spawn` for parallel
work. A callback or a future was the handle to work that had not finished.

*What Nimony does:* `.passive` replaces `async` (`doc/differences.md:8-9`); a `Continuation` replaces the
future; `delay` and `complete` replace the task spawn; and the same pragma covers the work a thread procedure
did, because the same continuation can be handed to a pool. `std/asyncdispatch` does not exist at the pin, and
`await` is an undeclared identifier.

*What breaks if you keep the habit:* `import std / [asyncdispatch]` is a missing file; `await` fails at the
first use; and the mental model is the real casualty, because `complete` blocks. Nim 2 code awaited and moved
on, while a passive call from regular code waits for the whole chain, parks included. Code written as if the
call returned early will hang instead.

## Samples

`samples/24-passive-procs/passive.nim`, run at the pinned commit:

```
nimony c -r samples/24-passive-procs/passive.nim
```

Expected output, which the sample verifier prints in full:

```
double 21 = 42
built, not run
solo a start
solo a end
worker b start
worker c start
both parked
worker b end
worker c end
done
```

Line by line: a passive proc called from regular code returns its value; `delay` builds without running;
`complete` runs a coroutine that never parks; two workers start and park; the driver resumes them in the order
it chooses; and the program exits `0`, which is what the verifier reads. The sample uses
`{.feature: "assumeSync".}` because the resume continuations are module-level variables, as the rule above
requires.

## Checks

1. Write a `.passive` proc that returns `x + 1` and call it from regular code. Expected: the value, no park.
2. Build the same call with `delay`, print a line, then `complete` it. Expected: the printed line comes first.
3. Put a `suspend()` in the callee and `complete` it. Expected: the program prints up to the park and hangs;
the reason is the missing resumer.
4. Add `let c = delay()` before the park, save it to a module-level `var`, and drive it with `advance`.
Expected: the line after `suspend()` runs.
5. Call `delay()` with no `suspend()` anywhere after it. Expected: the compiler dies with
`'state != -1' delay() no-arg must precede suspension point`.
6. Call `suspend()` with no `delay()` before it. Expected: no park; the next line runs.
7. Pass a passive proc where a `proc (x: int): int {.nimcall.}` is expected. Expected: ``[1] `.passive` mismatch``.
8. Run a passive proc whose loop makes 100000 passive calls. Expected: it finishes; the trampoline keeps the
stack flat.

## Chapter checklist

draft 2026-11-13 · tech_review 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13
