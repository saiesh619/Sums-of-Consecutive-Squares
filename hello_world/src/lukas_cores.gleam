import gleam/erlang/process
import gleam/io

pub fn main() {
  // Parent creates a subject to learn the worker's inbox
  let parent_inbox: process.Subject(process.Subject(String)) =
    process.new_subject()

  // Spawn worker
  let _pid =
    process.spawn(fn() {
      let worker_inbox: process.Subject(String) = process.new_subject()
      process.send(parent_inbox, worker_inbox)

      // Handle both Ok and Error(Nil)
      case process.receive(from: worker_inbox, within: 5000) {
        Ok(msg) -> io.println("Worker received: " <> msg)
        Error(Nil) -> io.println("Worker timed out waiting for a message")
      }
    })

  // Parent waits to learn the worker's inbox
  case process.receive(from: parent_inbox, within: 5000) {
    Ok(worker_inbox) -> {
      process.send(worker_inbox, "Hello, actor!")
      process.sleep(100)
    }
    Error(Nil) -> io.println("Parent timed out waiting for worker inbox")
  }
}
