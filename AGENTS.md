# AGENTS.md

Notes for agents working on NetAddr-IP. Short on purpose: only the things that
are not obvious from the code, or that have already cost time.

## Build and test

```sh
build=$(mktemp -d)
dzil build --in "$build"
cd "$build"
perl Makefile.PL --xs && make && prove -b -j4 t/
make realclean
perl Makefile.PL -noxs && make && prove -b -j4 t/
```

- This is a Dist::Zilla distribution. The checkout has no `Makefile.PL`; `dzil
  build` writes one. Only tracked files ship, so `git add` a new file before
  building.
- Build into a fresh directory every time, as above. A fixed path lets a stale
  build masquerade as this one, and lets two runs share a tree.
- **Run `dzil build` again after every edit.** The build directory holds
  its own copy of each file, so `make` there tests the old code. That once
  made a compile failure look like a pass.
- Both builds must pass and must agree, down to the error text.
- `NetAddr::IP::Util::mode()` returns `CC XS` or `Pure Perl`. Check it after a
  build, because a fallback can otherwise pass as the other build.
- `make clean` deletes `lib/NetAddr/IP/Util_IS.pm`, which `Makefile.PL`
  writes, so run `perl Makefile.PL` again after it.
- Author tests need `AUTHOR_TESTING=1`, release tests `RELEASE_TESTING=1`.
  CI sets the first; `dzil release` sets the second.

## Changes

New entries go under `{{$NEXT}}`, one entry per change:

```text
    - What changed, in one line.
      Continuation lines are indented six spaces, and the entry wraps at
      78 columns.
```

- A code block or table goes inside the entry it belongs to, with no blank
  line before it, or the parser reads each line as a new change. Sub-list
  items, marked `- ` and indented ten spaces, go last in the entry.
- Wrap example output that starts with `#` in backticks. A bare `#` is read
  as a bullet marker and dropped.
- Dates are W3CDTF with an offset, `2008-10-06T13:10:00-07:00`.
- Check with `tidy_changelog --check Changes`. The release test
  `t/release-cpan-changes.t` runs the same parser.
- Be succinct and write as if the reader is 5 years old

## Tests

The `t/` files are numbered in blocks, one per package layer, in the order
those layers depend on each other. Within a block the numbering runs primitives
before dependents, each function's error cases next to it, IPv4 before IPv6
before mixed, then alphabetically. A new test takes the next free number in
its block, not the next free number in the directory.

| block | holds |
|---|---|
| 001-019 | the distribution and the build: nothing that calls a NetAddr function |
| 020-029 | `NetAddr::IP::Constants` |
| 030-049 | `NetAddr::IP::InetBase`, the text layer everything else is built on |
| 050-109 | `NetAddr::IP::Util`, arithmetic and address conversion, XS and pure Perl |
| 110-199 | `NetAddr::IP::Lite` |
| 200-259 | `NetAddr::IP`, the full object API |
| 260-269 | threads and anything that crosses layers |

`dist.ini` adds `t/00-compile.t` and `t/00-report-prereqs.t`, and `[RunExtraTests]`
adds the `author-` and `release-` files, so the numbers stay clear of them.

- Start with `use Test2::V1 -ipP;` and `use Test2::Plugin::NoWarnings;`. Name
  subtests and assertions, and compare exact values with `is`.
- New files are `t/NNN-name.t` with the next free number in the block for that
  package, formatted with `perltidy -b -bext=/`. The blocks are below, and a
  filename keeps its package prefix, so `t/134-inetbase-inet_pton.t` belongs to
  the InetBase block.
- A test for a fix must fail without the fix. Check that before calling the
  work done.
- Bail out with `bail_out`, since Test2::V1 does not define `BAIL_OUT`. That
  spelling dies on an undefined sub, and only once the guard fires (GH#145).
- To test this module's own `inet_ntop` and `inet_pton` on a host with
  Socket6, hide Socket6 with an `@INC` hook in a `BEGIN` block before loading
  InetBase, as `t/040` does. Never redefine one of Socket's constants with
  Test2::Mock instead: on perl 5.14 the redefinition warns, and NoWarnings
  fails the test.
- A hook loaded through `PERL5OPT` comes too late for a module named with
  `-M` on the command line, which perl loads first. Put the `use` in a script.
- Under perl 5.14, Carp 1.20 ends a croak message at "line N" with no full
  stop, where later Carp and `die` add one. Match the full stop as optional.

## Code

- ASCII only. Four spaces, no tabs, LF, a final newline, no trailing
  whitespace. Follow .editorconfig.
- **Use documentation addresses only.** RFC 5737 for IPv4, so 192.0.2.0/24,
  198.51.100.0/24 or 203.0.113.0/24, and RFC 3849 for IPv6, so 2001:db8::/32.
  Loopback is fine where the example is about loopback. This holds in tests,
  in POD and in Changes, because an address written in an example becomes
  documentation, and never in an example that calls a real host.
- Write `[0-9]` rather than `\d`, so non-ASCII digits are rejected.
- Comments must state what the code does, not it's history or narrative.
- Comments must provide some insight that is not obvious from the code itself.
- Comments must not reference issue or ticket numbers, git blame is serves
  that purpose.
- Uncuddle `else` and `elsif`: the closing brace ends the line, and `else` or
  `elsif` starts the next at the same indentation. POD verbatim examples and
  commented-out code are left as they are.
- **Check regexes after any mechanical formatting pass.** A comma-spacing pass
  once turned `{1,3}` into `{1, 3}`, which is literal text, and two parsers
  broke silently.
- In `xs/Util.xs`, `PERL_NO_GET_CONTEXT` is defined, so a helper calling the
  Perl API takes `pTHX_` and is called with `aTHX_`. Keep no mutable state at
  file scope, or the XS is not thread safe.
- The perl floor is 5.014 in every phase. CI fails if a phase or the shipped
  `Makefile.PL` drifts from the runtime floor.

## Commits

- Subject starts `Fix GH#NNN:` when the commit fixes an issue.
- No commit hashes in a message, and no `cherry-pick -x`. Rewrites make them
  stale.
- Put a fix in the commit it belongs to by amending, not on top.
- `Fixes #NNN` in a pull request body. Propose a fix as an issue with the
  patch and the commands that verify it.
- ASCII, no em dashes, and no `--` standing in for one. Do not start a
  sentence with a code identifier.

### Message style

These rules apply to commit messages only.

- **PRIORITY** Lead with the decision or outcome and the behavior change or problem solved, not the process. Use active voice.
- **PRIORITY** Never start a sentence with a code identifier or symbol.
- Prefer bullet points over paragraphs; use center-embedding exceedingly rarely.
- Introduce any concept the reader may not know before discussing it, since AI tends to reference code or internal terms without saying what they are.
- Avoid stock AI phrasing, filler, inflated claims, vague qualifiers (e.g., "various", "several", "quite"), or hedging unless uncertainty is essential to the change.
- For code changes, strongly encourage providing a table with columns `input`, `output before`, `output now` showing input/output examples when appropriate.

## Release

- A breaking change goes to the packagers. This is the list to work from: the
  repology project page, which carries every repository shipping NetAddr-IP
  and a maintainer address for each.

  <https://repology.org/project/perl%3Anetaddr-ip/versions>

- On release, remind the user to notify them. Give the addresses that read as a
  person, and skip the rest: mailing lists, `packaging@`-style role accounts,
  distribution aliases such as `perl@gentoo.org` or
  `ubuntu-devel-discuss@lists.ubuntu.com`, and `fallback-*@repology`. Say how
  many were skipped, so nothing goes missing without comment.
- An address with no dot in its domain is still one to use. `djzort@cpan` and
  `miker@cpan` are PAUSE ids, and they are the two a CPAN breaking change
  reaches first.

## Licence

MIT. Add only code you wrote or have permission to add, and keep contributor
credits in `Changes`.

## Open questions

- 4.079 is the last stable release and the compatibility baseline. Developer
  releases, with an underscore in the version, are not indexed by CPAN.
