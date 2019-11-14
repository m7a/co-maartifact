---
section: -1
title: Ma_Sys.ma Artifact Script
author: ["Linux-Fan, Ma_Sys.ma (Ma_Sys.ma@web.de)"]
keywords: ["mdvlci", "maartifact", "maartifact.pl"]
date: 2019/11/14 20:46:34
lang: en-US
x-masysma-name: maartifact
x-masysma-repository: https://www.github.com/m7a/co-maartifact
x-masysma-copyright: |
  Copyright (c) 2019 Ma_Sys.ma.
  For further info send an e-mail to Ma_Sys.ma@web.de.
---
**WARNING: This is highly experimental.**

The absolute minimum of an artifact management system.
This script is intended to automatically download and extract various forms
of sources, mainly debian packages and compressed tarfiles. All downloads
are stored under `../x-artifacts/managed` relative to the script's directory.

	USAGE maartifact extract ARTIFACT DESTDIR [DEFINITION]

	ARTIFACT   Identifier for this artifact, e.g. ial_in_....deb
	DESTDIR    Directory to extract the artifact's contents to.
	DEFINITION String identifying this artifact

The following definitions are possible

packagename
:   If `ARTIFACT` ends on `.deb`, try to download it from this Debian
    package. Note that this syntax invokes `aptitude download` which means that
    command must be available on the system and that the outcome depends on
    whether the user is running stable, testing or unstable.
GIT
:   Clone Git repository. For this to work, the artifact name needs to end on
    `.git`.
URL
:   Download artifact from URL (default)

Example

	./maartifact.pl extract rxvt_unicode.deb sub rxvt-unicode

This downloads the `rxvt-unicode` package and extracts it to a directory `sub`.

Dependencies: External Programs
:   `tar`, `7z`, `aptitude`, `git`
Dependencies: Perl Modules (Debian package names)
:   `libfile-copy-recursive-perl`, `libwww-perl`, `libgit-repository-perl`
