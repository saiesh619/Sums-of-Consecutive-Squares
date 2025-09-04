//// src/lukas_core.gleam

import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option

// ---------- Messages ----------
pub type WorkerMsg {
  Work(start: Int, count: Int, k: Int, reply_to: process.Subject(BossMsg))
  Stop
}

pub type BossMsg {
  Result(found: List(Int))
  Registered(worker: process.Subject(WorkerMsg))
}

// ---------- Public API ----------
pub fn lukas(n: Int, k: Int, workers: Int, chunk: Int) -> List(Int) {
  let worker_count = case workers < 1 {
    True -> 1
    False -> workers
  }

  let chunk_size = case chunk < 1 {
    True -> 1
    False -> chunk
  }

  // 1) Spawn workers: they create their own inbox and send it back via `Registered`
  let registry = process.new_subject()
  spawn_n_workers(worker_count, registry)
  let worker_subjects = collect_workers(registry, worker_count, [])

  // 2) Boss reply mailbox (for results only)
  let reply = process.new_subject()

  // 3) Schedule work and collect results
  let starts =
    schedule_and_collect(
      reply,
      worker_subjects,
      1,
      // first_start
      n,
      // last_start (inclusive)
      chunk_size,
      k,
    )
    |> list.sort(int.compare)

  // 4) Shutdown workers
  stop_all(worker_subjects)
  starts
}

// ---------- Math helpers ----------
fn sumsq_1_to(n: Int) -> Int {
  let a = n
  let b = n + 1
  let c = 2 * n + 1
  a * b * c / 6
}

fn sum_of_consecutive_squares(a: Int, k: Int) -> Int {
  let n = a + k - 1
  sumsq_1_to(n) - sumsq_1_to(a - 1)
}

fn isqrt(n: Int) -> Int {
  case n <= 0 {
    True -> 0
    False -> newton_isqrt(n, n)
  }
}

fn newton_isqrt(n: Int, guess: Int) -> Int {
  let s = guess + n / guess
  let next = s / 2
  case next >= guess {
    True -> guess
    False -> newton_isqrt(n, next)
  }
}

fn is_square(n: Int) -> Bool {
  case n < 0 {
    True -> False
    False -> {
      let r = isqrt(n)
      r * r == n
    }
  }
}

// ---------- Chunk search ----------
fn find_in_chunk(start: Int, count: Int, k: Int) -> List(Int) {
  find_loop(start, count, k, [])
}

fn find_loop(a: Int, remain: Int, k: Int, acc: List(Int)) -> List(Int) {
  case remain <= 0 {
    True -> list.reverse(acc)
    False -> {
      let s = sum_of_consecutive_squares(a, k)
      let acc2 = case is_square(s) {
        True -> [a, ..acc]
        False -> acc
      }
      find_loop(a + 1, remain - 1, k, acc2)
    }
  }
}

// ---------- Worker ----------
fn worker_loop(inbox: process.Subject(WorkerMsg)) {
  case process.receive(inbox, within: 60_000) {
    Ok(Work(start, count, k, reply_to)) -> {
      let found = find_in_chunk(start, count, k)
      process.send(reply_to, Result(found))
      worker_loop(inbox)
    }
    Ok(Stop) -> Nil
    Error(Nil) -> worker_loop(inbox)
  }
}

// Create worker: the **child** creates its own inbox and registers it
fn spawn_worker(register_to: process.Subject(BossMsg)) {
  let _pid =
    process.spawn(fn() {
      let inbox = process.new_subject()
      // created by child
      process.send(register_to, Registered(inbox))
      // tell boss how to reach us
      worker_loop(inbox)
    })
  Nil
}

fn spawn_n_workers(n: Int, register_to: process.Subject(BossMsg)) {
  case n <= 0 {
    True -> Nil
    False -> {
      spawn_worker(register_to)
      spawn_n_workers(n - 1, register_to)
    }
  }
}

fn collect_workers(
  register_subject: process.Subject(BossMsg),
  need: Int,
  acc: List(process.Subject(WorkerMsg)),
) -> List(process.Subject(WorkerMsg)) {
  case need <= 0 {
    True -> list.reverse(acc)
    False -> {
      case process.receive(register_subject, within: 60_000) {
        Ok(Registered(w)) ->
          collect_workers(register_subject, need - 1, [w, ..acc])
        _ -> collect_workers(register_subject, need, acc)
      }
    }
  }
}

fn stop_all(ws: List(process.Subject(WorkerMsg))) {
  case ws {
    [] -> Nil
    [w, ..rest] -> {
      process.send(w, Stop)
      stop_all(rest)
    }
  }
}

// ---------- Boss & scheduling ----------
fn min(a: Int, b: Int) -> Int {
  case a < b {
    True -> a
    False -> b
  }
}

fn schedule_and_collect(
  reply: process.Subject(BossMsg),
  workers: List(process.Subject(WorkerMsg)),
  first_start: Int,
  last_start: Int,
  // inclusive
  chunk: Int,
  k: Int,
) -> List(Int) {
  let total_work_items = case last_start < first_start {
    True -> 0
    False -> last_start - first_start + 1
  }

  case total_work_items == 0 {
    True -> []
    False -> {
      let numer = total_work_items + chunk - 1
      let chunks_total = numer / chunk
      let initial = min(list.length(workers), chunks_total)

      let assigned0 =
        assign_first_wave(
          workers,
          reply,
          first_start,
          last_start,
          chunk,
          k,
          initial,
          0,
        )

      collect_loop(
        reply,
        workers,
        first_start + assigned0 * chunk,
        // last_assigned_start
        last_start,
        chunk,
        k,
        assigned0,
        // assigned_chunks
        0,
        // completed_chunks
        0,
        // rr_index
        [],
        // acc
      )
    }
  }
}

fn assign_first_wave(
  workers: List(process.Subject(WorkerMsg)),
  reply: process.Subject(BossMsg),
  start: Int,
  last_start: Int,
  chunk: Int,
  k: Int,
  need: Int,
  i: Int,
) -> Int {
  case i >= need {
    True -> i
    False -> {
      let who = nth(workers, i)
      let s = start + i * chunk
      case s > last_start {
        True -> i
        False -> {
          let remaining = last_start - s + 1
          let c = min(chunk, remaining)
          case who {
            option.Some(w) -> {
              process.send(w, Work(s, c, k, reply))
              assign_first_wave(
                workers,
                reply,
                start,
                last_start,
                chunk,
                k,
                need,
                i + 1,
              )
            }
            option.None -> i
          }
        }
      }
    }
  }
}

fn collect_loop(
  reply: process.Subject(BossMsg),
  workers: List(process.Subject(WorkerMsg)),
  last_assigned_start: Int,
  last_start: Int,
  chunk: Int,
  k: Int,
  assigned_chunks: Int,
  completed_chunks: Int,
  rr_index: Int,
  acc: List(Int),
) -> List(Int) {
  case completed_chunks >= assigned_chunks {
    True -> acc
    False -> {
      case process.receive(reply, within: 60_000) {
        Ok(Result(found)) -> {
          let acc2 = list.append(found, acc)
          let completed2 = completed_chunks + 1
          case last_assigned_start <= last_start {
            True -> {
              let remaining = last_start - last_assigned_start + 1
              let c = min(chunk, remaining)
              let #(w, rr2) = pick_rr(workers, rr_index)
              process.send(w, Work(last_assigned_start, c, k, reply))
              collect_loop(
                reply,
                workers,
                last_assigned_start + c,
                last_start,
                chunk,
                k,
                assigned_chunks + 1,
                completed2,
                rr2,
                acc2,
              )
            }
            False -> {
              collect_loop(
                reply,
                workers,
                last_assigned_start,
                last_start,
                chunk,
                k,
                assigned_chunks,
                completed2,
                rr_index,
                acc2,
              )
            }
          }
        }
        Error(Nil) -> {
          collect_loop(
            reply,
            workers,
            last_assigned_start,
            last_start,
            chunk,
            k,
            assigned_chunks,
            completed_chunks,
            rr_index,
            acc,
          )
        }
        Ok(Registered(worker:)) -> todo
      }
    }
  }
}

fn pick_rr(
  workers: List(process.Subject(WorkerMsg)),
  idx: Int,
) -> #(process.Subject(WorkerMsg), Int) {
  let len = list.length(workers)
  let j = case len == 0 {
    True -> 0
    False -> idx % len
  }
  case nth(workers, j) {
    option.Some(w) -> {
      let jp1 = j + 1
      let next_idx = case len == 0 {
        True -> 0
        False -> jp1 % len
      }
      #(w, next_idx)
    }
    option.None -> {
      case nth(workers, 0) {
        option.Some(w0) -> #(w0, 0)
        option.None -> {
          let dummy = process.new_subject()
          #(dummy, 0)
        }
      }
    }
  }
}

// ---------- Helpers ----------
fn nth(a: List(a), i: Int) -> option.Option(a) {
  nth_loop(a, i, 0)
}

fn nth_loop(a: List(a), target: Int, cur: Int) -> option.Option(a) {
  case a {
    [] -> option.None
    [x, ..xs] ->
      case cur == target {
        True -> option.Some(x)
        False -> nth_loop(xs, target, cur + 1)
      }
  }
}
