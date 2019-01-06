# Patching PJSIP

We have custom patch set on top of the PJSIP, stored in `patches/` managed by `quilt`.

Patched version of a library is not versioned. PJSIP is versioned in its unpatched state so we can easily update
this library from upstream SVN (unfortunately) and use GIT to spot the difference.

## Patching

```
quilt push -a
```

## Unpatching

```
quilt pop -a
```

## Refreshing

Update patch file with changes made to files already included in the patch file.

```
quilt refresh
```

## New patch

```
quilt new patches/134ipv6_dns.diff
quilt add file/to/patch
quilt refresh
```


