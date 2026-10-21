# glibc for the Grafana Alloy binary

OpenWrt uses musl; the official `alloy-linux-amd64` (v1.5.1) is linked against
glibc and needs only `libc.so.6`, `libpthread.so.0`, `libdl.so.2` and the
loader `ld-linux-x86-64.so.2` (`readelf -d`: NEEDED; highest symbol
GLIBC_2.14). These four files are unmodified copies from the Debian 12
package below, plus `libgcc_s.so.1` (next section):

- `libc6_2.36-9+deb12u14_amd64.deb`
  sha256 `ba4f88f73dbc3ae9055f3c20f4523bfdbaf1ad13ff95e258924f77d20b4fbedf`
  (`apt-get download libc6` in `debian:bookworm`, 2026-10-21)
- glibc is LGPL-2.1+; source: https://sources.debian.org/src/glibc/2.36-9+deb12u14/

`libgcc_s.so.1` comes from `libgcc-s1_12.2.0-14+deb12u1_amd64.deb`
(sha256 `3016e62cb4b7cd8038822870601f5ed131befe942774d0f745622cc77d8a88f7`;
GPL-3 with the GCC Runtime Library Exception). glibc dlopens it at run time;
without this copy it picks OpenWrt's musl `/lib/libgcc_s.so.1` and alloy
segfaults in a crash loop (`Relink /lib/libgcc_s.so.1 … for IFUNC symbol
strlen`) — found by tests/harness/test_observability.yaml.

File checksums:

    2bd1552c47799ef67e701e81d4383061fd76059868e446e63560f0dd0d5ec14e  libgcc_s.so.1
    02bcda52c1a5dfc236f94d9e5255b4a0e26347d8a372a5223b650e31f291ce3c  ld-linux-x86-64.so.2
    6b4a45352fd0c540a9c7c718f35ce8c8e46a4e482f9d3885a910c32d1a0e1421  libc.so.6
    95d521b2c39fd0333271b6fdcdddff878ae82001a304313a837b8e728ebe3cb1  libdl.so.2
    b93a680da8a05b939b235c1533572e7a2f6d3d8808bf70209997edc64ea5fedc  libpthread.so.0

They replace the former `contrib/glibc.tar.gz` of the private
`iotgw_alloy` repo (18 MB: a whole `/lib/x86_64-linux-gnu` of unknown
origin, never vendored here, so the observability stack failed on every run).
Tested by tests/harness/test_observability.yaml (OpenWrt 23.05.4, the
production runner image and role): alloy installs, starts and reports ready.
