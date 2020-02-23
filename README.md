---
x-masysma-name: maartifact
section: 11
title: Ma_Sys.ma Artifact Script
author: ["Linux-Fan, Ma_Sys.ma (Ma_Sys.ma@web.de)"]
keywords: ["mdvlci", "maartifact.pl"]
date: 2019/11/14 20:46:34
lang: en-US
x-masysma-repository: https://www.github.com/m7a/co-maartifact
x-masysma-website: https://masysma.lima-city.de/11/maartifact.xhtml
x-masysma-owned: 1
x-masysma-copyright: |
  Copyright (c) 2019, 2020 Ma_Sys.ma.
  For further info send an e-mail to Ma_Sys.ma@web.de.
---
Name
====

`maartifact` -- download and extract archive files.

Synopsis
========

	maartifact download ARTIFACT DEFINITION
	maartifact require  ARTIFACT DEFINITION
	maartifact extract  ARTIFACT DESTDIR [DEFINITION]

Description
===========

The absolute minimum of an artifact management system.
This script is intended to automatically download and extract various forms
of sources, mainly debian packages and compressed tarfiles.

Options
=======

## Commands

download
:   Download the given artifact even if it might already be present.
require
:   Download the given artifact if it is not present.
extract
:   Download the given artifact if it is not present and extract its contents
    to `DESTDIR` afterwards.

## Parameters

------------  ---------------------------------------------------
`ARTIFACT`    Identifier for this artifact, e.g. `ial_in_....deb`
`DESTDIR`     Directory to extract the artifact's contents to.
`DEFINITION`  String identifying this artifact (see next section)
------------  ---------------------------------------------------

## Definitions

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

Examples
========

	./maartifact.pl extract rxvt_unicode.deb sub rxvt-unicode

This downloads the `rxvt-unicode` package and extracts it to a directory `sub`.

Files
=====

All downloads are stored under `../x-artifacts` relative to the script's
directory.

Dependencies
============

External Programs
:   (GNU) `tar`, `7z`, `aptitude`, `git`
Perl Modules (Debian package names)
:   `libfile-copy-recursive-perl`, `libwww-perl`, `libgit-repository-perl`
