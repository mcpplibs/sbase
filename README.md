# sbase, above openkal

[sbase](https://core.suckless.org/sbase/) — the suckless base utilities, 97 of
them — recompiled above [openkal-musl](https://github.com/mcpplibs/openkal-musl).

The sources in `upstream/` are upstream's, byte for byte. Nothing in this
repository patches them. What changes is the C library beneath them, and with it
the set of systems they run on.

```bash
mcpp build                                  # Linux
mcpp build --target x86_64-windows-gnu      # Windows
sh tests/oracle.sh target/*/*/bin           # 50 comparisons against the system's own tools
```

## What this demonstrates, and why sbase

The claim openkal makes is that a program's portability is a property of the C
library beneath it rather than of the program. A claim of that shape is tested by
taking a program that does not run somewhere, changing nothing in it, and running
it there.

sbase is a suitable subject for a reason worth stating exactly, because the
reason turns out to be the general case:

**It has no Windows support at all.** There is no port, no build for it, and
nothing in the sources contemplates one.

**It does not build on macOS as it stands.** Three of its tools include
`<sys/sysmacros.h>`, which is a header of the Linux C libraries and does not
exist there. Four use `st_mtim`, the field POSIX 2008 specifies, where that
system's C library has `st_mtimespec`.

Neither obstacle is in the kernel. Both are the C library, which is the class of
obstacle a C library can remove — and it removes them by being present rather
than by being adapted to: a program compiled above openkal-musl sees musl's
headers, so `<sys/sysmacros.h>` exists and `st_mtim` is the field name, on every
system.

That generalises, and the generalisation is the interesting result. A program
that is unavailable on another system *for kernel reasons* cannot be helped by a
C library; a program that is unavailable *for C library reasons* is usually
unavailable on Windows and available on macOS, because macOS is a POSIX system
and Windows is not. sbase is the case that fails both ways, which is why it is
the subject here.

## What is in this repository

| | |
| --- | --- |
| `upstream/` | sbase at `b30fb56`, unmodified. MIT; see `upstream/LICENSE` |
| `generated/getconf.h` | the output of a script in `upstream/scripts`, run once and committed |
| `compat/reallocarray.c` | two functions, and the reason they are here |
| `mcpp.toml` | one dependency, 97 targets |
| `tests/oracle.sh` | 50 comparisons, against the system's own tools and against the answers the standard requires |

### One dependency

```toml
[dependencies]
openkal-musl = "0.3.0"
```

No operating system is named, no implementation of openkal is named, and no
platform is named. `openkal-musl` declares the implementation it needs for the
target being built, because it is the only party that knows a program above it
carries no other runtime.

### Two build decisions, and both are about linking rather than about sources

**`getconf.h` is generated and committed.** Upstream produces it during the
build with a shell script. Its output is not specific to a system — every entry
is wrapped in `#ifdef`, so the C library's headers select — so it is produced
once and kept in `generated/`, and the build stays a compile and a link.

**One file of upstream's `libutil` is excluded.**
`upstream/libutil/reallocarray.c` holds three functions. The first is a
compatibility definition of `reallocarray` for a C library that lacks one; musl
has one. Upstream builds `libutil` into an archive, where a member is taken only
when something still needs it, and this build tool links objects — so a
definition present in both places is present twice, which is an error rather
than a preference. The other two functions in that file are not compatibility,
and they are in `compat/reallocarray.c` with the reason.

## What does not work, and why

Three of the 97 tools use an operation openkal does not have, and the absence is
deliberate rather than pending.

**`fork`.** openkal offers starting a program and not duplicating one. A
duplicate of a running image is not something every environment can produce, and
clause 3.1 of the specification declines to simulate what cannot be supplied.
`xargs`, `cron`, `find -exec`, `setsid`, `flock` and `time` fork, and they report
that the operation is not implemented.

`posix_spawn`, `system` and `popen` do work, because musl builds them on starting
a program rather than on duplicating one.

**`exec` is not what it says.** openkal-musl expresses replacing the running
image as starting the program, waiting for it, and ending with its status. A
caller cannot distinguish that through this library — the same program runs, with
the same arguments, on the same streams, and the same status reaches whoever
waits — but there are two images where a system with the operation would have
one. It is the arrangement every environment without the operation uses, and two
of the three beneath openkal are such environments. `env`, `nohup` and `chroot`
work through it.

**Sockets and signals.** openkal has neither. `tftp` and `logger` link and report
that the operation is not implemented.

## What the oracle compares

50 observations, in two kinds.

**Against the system's own tool** — `wc`, `cat`, `sort`, `cksum`. POSIX specifies
their output, so the same input gives the same bytes on all three systems and the
system's tool is a control this repository did not write.

**Against the answer the standard requires** — everything else, because a
system's own spelling of `sha256sum` is not portable and comparing against an
unportable control would mean comparing against nothing on two systems out of
three.

Both kinds assert that the answer is right, not that an answer was produced.

## Continuous integration

| system | toolchain | what runs |
| --- | --- | --- |
| Linux | gcc, llvm | all 97 build; the 50 comparisons hold |
| macOS | llvm | all 97 build; the 50 comparisons hold |
| Windows | gcc (PE) | all 97 build; the 50 comparisons hold |
| Linux → Windows | gcc, cross | all 97 build; the 50 comparisons hold under wine |

## Licence

`upstream/` and `compat/` are sbase's, MIT — see `upstream/LICENSE`. Everything
else in this repository is Apache-2.0.
