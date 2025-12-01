## Plan: Update FreeSurfer from v6.0 to v7 or v8

Based on the research, upgrading FreeSurfer will require installation method changes. The current tar.gz extraction approach will still work for v7, but using Debian packages (`.deb`) is now preferred and handles dependencies automatically. FreeSurfer v8 strongly recommends package installation and requires significantly more RAM (32GB vs 16GB).

### Steps

1. **Choose target version** - FreeSurfer v7.4.1 recommended over v8 due to lower RAM requirements (16GB vs 32GB) unless container deployment can guarantee 32GB+ memory.

2. **Update FreeSurfer installation block in [`Dockerfile`](Dockerfile:47-56)** - Replace `wget` tar.gz extraction with `.deb` package installation using `apt-get install`, update FTP URL to HTTPS download URL, and verify dependencies are automatically handled.

3. **Update license handling** - For v7, keep copying freesurfer_license.txt to `${FREESURFER_HOME}/license.txt` (no change needed); for v8, optionally switch to `FS_LICENSE` environment variable pointing to `/root/license.txt` for cleaner multi-version support.

4. **Verify environment variables remain unchanged** - All existing `FREESURFER_HOME`, `FSFAST_HOME`, `MINC_BIN_DIR`, `MNI_DIR`, `PERL5LIB`, and `PATH` settings are compatible across v6, v7, and v8.

### Further Considerations

1. **Version selection** - Choose v7.4.1 for compatibility with current 16GB RAM containers, or v8.1.0 if 32GB+ RAM is available and faster processing (1.8-2.5hrs vs 10+hrs for recon-all) is desired?

2. **Fallback for v8 memory constraints** - If upgrading to v8 with limited RAM, add `ENV FS_V8_XOPTS=0` to revert to older, less memory-intensive recon-all behavior?

3. **Testing downstream dependencies** - Verify that existing pipeline scripts in Fariba_full_pipeline and validation workflows are compatible with the chosen FreeSurfer version after upgrade?