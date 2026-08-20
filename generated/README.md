# generated

One header, produced by a script in the vendored sources and kept here rather
than run during the build.

```
upstream/scripts/getconf.sh > generated/getconf.h
```

The output is not specific to a system or an architecture: every entry is
wrapped in `#ifdef`, so the C library's own headers decide at compile time which
of the names exist. The script is therefore run once and its output committed,
which keeps the build a compile and a link and nothing else — the same reason
`musl-generated` exists in `openkal-musl`.

Regenerating it is the command above. If upstream adds a name to the script,
this file is what has to be produced again.
