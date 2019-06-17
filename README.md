### Experimental

## What is this?

I am experimenting with the idea of a distributed shell history. The goal is to
be able to search your shell history across different bash processes easily.
And potentially different computers.

This uses UNIX Domain Sockets to communicate with a server written in Racket.
Each Racket thread corresponds to a shell process, and they receive shell
commands as messages. If you want to get the history for a given process, you
simply send a message to a thread and then it sends you back the history.

Unix Domain Sockets are ideal for this, as they are less likely to conflict
with other services running on the machine (you specify a path, not a port). As
well, they are more robust than FIFOs because they can handle multiple
concurrent connections easily.

At some point in the future, part of this may be rewritten in C, Pony, or
Erlang, or a combination of all three.

1. Compile `server.rkt` with `raco exe server.rkt`
2. Run `./server`
3. Run `source shelltalk.sh`
4. Execute commands
5. See the history for this shell process with `./client.py -R $$`
