# mkosi develop

|          Variable          |   configure  |     clean    |     sync     |    prepare   | build-script |   postinst   |   finalize   |  postoutput  |      example      |
| :------------------------- | :----------: | :----------: | :----------: | :----------: | :----------: | :----------: | :----------: | :----------: | :---------------- |
| ARCHITECTURE               |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      | x86-64            |
| ARTIFACTDIR                |              |              |              |      ✓      |      ✓      |      ✓      |      ✓      |              | /work/artifacts   |
| BUILDDIR                   |              |              |              |              |      ✓      |      ✓      |      ✓      |              |                   |
| BUILDROOT                  |              |              |              |      ✓      |      ✓      |      ✓      |      ✓      |              | /buildroot        |
| CACHED                     |              |              |      ✓      |              |              |              |              |              | 0                 |
| CHROOT_BUILDDIR            |              |              |              |              |      ✓      |              |              |              |                   |
| CHROOT_DESTDIR             |              |              |              |              |      ✓      |              |              |              | /work/dest        |
| CHROOT_OUTPUTDIR           |              |              |              |              |              |      ✓      |      ✓      |              | /work/out         |
| CHROOT_SCRIPT              |              |              |              |      ✓      |      ✓      |      ✓      |      ✓      |              | /work/postinst    |
| CHROOT_SRCDIR              |              |              |              |      ✓      |      ✓      |      ✓      |      ✓      |              | /work/src         |
| DESTDIR                    |              |              |              |              |      ✓      |              |              |              | /work/dest        |
| DISTRIBUTION               |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      | debian            |
| DISTRIBUTION_ARCHITECTURE  |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      | amd64             |
| IMAGE_ID                   |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |                   |
| IMAGE_VERSION              |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |                   |
| MKOSI_CONFIG               |              |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      | /work/config.json |
| MKOSI_GID                  |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      | 0                 |
| MKOSI_UID                  |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      | 0                 |
| OUTPUTDIR                  |              |      ✓      |              |              |              |      ✓      |      ✓      |      ✓      | /work/out         |
| PACKAGEDIR                 |              |              |              |      ✓      |      ✓      |      ✓      |      ✓      |              | /work/packages    |
| PROFILES                   |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |              |                   |
| QEMU_ARCHITECTURE          |      ✓      |              |              |              |              |              |              |              |                   |
| RELEASE                    |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      | trixie            |
| SOURCE_DATE_EPOCH          |              |      ✓      |              |      ✓      |      ✓      |      ✓      |      ✓      |              |                   |
| SRCDIR                     |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      |      ✓      | /work/src         |
| WITH_DOCS                  |              |              |              |      ✓      |      ✓      |              |              |              | 1                 |
| WITH_NETWORK               |              |              |              |      ✓      |      ✓      |      ✓      |      ✓      |              | 1                 |
| WITH_TESTS                 |              |              |              |      ✓      |      ✓      |              |              |              | 1                 |
