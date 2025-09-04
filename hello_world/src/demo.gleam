import gleam/int
import gleam/io
import gleam/list
import lukas_core

pub fn main() {
  // Example 1: should print just "3"

  // Example 2: should print just "1"
  let r2 = lukas_core.lukas(1_000_000, 24, 4, 1)
  list.each(r2, fn(a) { io.println(int.to_string(a)) })
}
