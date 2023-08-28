# Protoshock Crash Handler Tool

## What is it?

It's just a simple GUI that sends data to a server.
Made for the ProtoShock game

## Build and run instructions

### Requirements

1. `nim >= 2.0.0`
2. `nimble`

### Install dependencies

```sh
$ nimble install -d
```

Or, if that doesn't work:

```sh
$ nimble install wNim
```

### Build or run

This will build in release mode and strip the binary.
See `nim.cfg` for the default build flags.

```sh
$ nimble build
$ ./reporthandlergui.exe
```

Alternatively, in one go:

```sh
$ nimble run
```
