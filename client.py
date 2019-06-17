#! /usr/bin/env python3

import socket
import argparse

from base64 import b64encode, b64decode
from contextlib import closing
from json import loads

def read_socket(sock, chunk_size=1024):
    buf = []

    while True:
        chunk = sock.recv(1024)
        buf.append(chunk)
        if b"\n" in chunk:
            break

    return b"".join(buf).decode("utf-8")

def read_log(pid):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect("/tmp/shelltalk.sock")
        s.send(("read {0}\n".format(pid)).encode("utf-8"))

        buf = read_socket(s)

        return [b64decode(l) for l in loads(buf)]

def spawn(pid):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect("/tmp/shelltalk.sock")
        s.send(("spawn {0}\n".format(pid)).encode("utf-8"))


def list_pids():
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect("/tmp/shelltalk.sock")
        s.send("list\n".encode("utf-8"))

        return loads(read_socket(s))

def write(pid, msg):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect("/tmp/shelltalk.sock")
        message = b64encode(msg.encode("utf-8"))
        s.send(("write {0} {1}\n".format(pid, message.decode("utf-8"))).encode("utf-8"))

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

parser.add_argument("-L",
                    "--list",
                    action="store_true",
                    help="List all of our shells")

args = parser.parse_args()

if args.spawn:
    spawn(*args.spawn)

if args.write:
    write(*args.write)

if args.list:
    print(list_pids())

if args.read:
    for line in read_log(*args.read):
        print(line.decode("utf-8"))
