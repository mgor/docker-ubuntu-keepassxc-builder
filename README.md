# docker-ubuntu-keepassxc-builder

Build latest keepassxc as a debian (ubuntu) package.

```bash
make
```

Packages are available in `packages/`.

If you need to build for a different release than the one you are currently running:

```
make RELEASE=zesty
```

Note that `mgor/ubuntu-pkg-builder` needs to have been built for the specified `RELEASE`.
