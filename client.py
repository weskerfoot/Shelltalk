#! /usr/bin/env python3

import socket
import argparse

from contextlib import closing
from json import loads

def read_log(pid):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect("/tmp/shelltalk.sock")
        s.send(("read {0}\n".format(pid)).encode("utf-8"))

        buf = []

        while True:
            chunk = s.recv(1024)
            buf.append(chunk)
            if b"\n" in chunk:
                break

    return loads(b"".join(buf).decode("utf-8"))

def spawn(pid):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect("/tmp/shelltalk.sock")
        s.send(("spawn {0}\n".format(pid)).encode("utf-8"))

def write(pid, msg):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect("/tmp/shelltalk.sock")
        s.send(("write {0} {1}\n".format(pid, msg)).encode("utf-8"))

parser = argparse.ArgumentParser()

parser.add_argument("-S",
                    "--spawn",
                    nargs=1,
                    help="Would you like to use me?")

parser.add_argument("-W",
                    "--write",
                    nargs=2,
                    help="Would you like to log some things?")

parser.add_argument("-R",
                    "--read",
                    nargs=1,
                    help="Would you like to read some logs?")

args = parser.parse_args()

if args.spawn:
    print(spawn(*args.spawn))

if args.write:
    print(write(*args.write))

if args.read:
    print(read_log(*args.read))
