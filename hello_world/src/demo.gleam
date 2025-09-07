import gleam/io
import gleam/list
import gleam/int
import lukas_core

pub fn main() {
  let n = 10_000_000   // big enough to show scaling
  let k = 24
  let workers = 16     // try 8, 12, 16; keep best
  let chunk = 75_000   // try 50k–100k

  io.println("n=" <> int.to_string(n) <>
             " k=" <> int.to_string(k) <>
             " workers=" <> int.to_string(workers) <>
             " chunk=" <> int.to_string(chunk))

  let results = lukas_core.lukas(n, k, workers, chunk)
  list.each(results, fn(a) { io.println(int.to_string(a)) })
}
