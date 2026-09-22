# perl-NetAddr-IP Maintenance Plan

Repository: https://github.com/cpan-authors/perl-NetAddr-IP

## Project Overview

Maintenance of NetAddr::IP — manages IPv4 and IPv6 addresses and subnets.
157 test files, ~2857 tests, Test2::V1 framework, Dist::Zilla build system.

## Current Release

**4.080_01** — Trial release (2026-09-21, `v4.080_01` tag)
- 42 Changes entries covering GH#1-GH#68
- BREAKING: re(), re6(), new(undef)
- DEPRECATION: :rfc3021 tag
- Perl 5.14+ required
- All tests pass on Linux (5.14-5.42) and macOS (26 arm64, 15 arm64, 15 Intel, 26 Intel)

## Code Style Rules

- Single quotes, aligned `=`, `m//`, `qr//` only with `like()`
- `[0-9]` not `\d`, `for` not `foreach`, no `$_` topic
- Uncuddle `} else {`, 4-space indentation, named loop variables
- No new test files — extend existing ones
- Use `ref_ok()` not `is(ref ..., 'ARRAY', ...)`
- Use `isa_ok($thing, $class)` two-arg form with `-ipP` import
- RFC 5737 test addresses: 192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24
- RFC 3849 test addresses: 2001:db8::/32

## Issues Closed in 4.080_01

| Issue | Title | Commit |
|-------|-------|--------|
| GH#1  | Fix :nofqdn import tag | `4782ffd` |
| GH#37 | coalesce counts usable hosts instead of addresses | `32b0cfc` |
| GH#38 | coalesce on subclass silently returns empty list ref | `892fbc8` |
| GH#40 | coalesce does not validate masklen or number | `c0b2c16` |
| GH#42 | coalesce has effectively no test coverage | `6548222` |
| GH#56 | Fix licence metadata | `c8dcc56` |

## Work After 4.080_01 Tag

| Commit | Description | In Release? |
|--------|-------------|-------------|
| `3296ec9` | Update Changes file | No (HEAD only) |

## Open Issues

### GH#33: Lite/Util tests hard-code glibc inet_ntop output
- Issue reported on macOS 10.5/10.8 (2008/2013)
- CI passes on modern macOS with Socket6 installed
- Issue is obsolete — closing recommended

### GH#44: numeric() float precision for IPv6
- POD-only fix needed in `lib/NetAddr/IP/Lite.pm` and `lib/NetAddr/IP.pm`
- Not yet implemented

## Key Files

- `lib/NetAddr/IP.pm` — coalesce (line 1219), re/re6 (lines 1372/1446), nofqdn (line 383)
- `lib/NetAddr/IP/Lite.pm` — new6FFFF (line 763), neg/abs overloads (line ~237)
- `t/132-v4-coalesce.t` — coalesce tests (primary test file)
- `t/133-v4-compact.t` — compactref tests
- `.github/workflows/build-and-test.yml` — CI configuration
- `Changes` — changelog
