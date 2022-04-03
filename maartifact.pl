#!/usr/bin/perl
# maartifact.pl 1.0.3, Copyright (c) 2019, 2020, 2022 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de

#------------------------------------------------------------------[ General ]--
use strict;
use warnings FATAL => 'all';
use autodie;

use File::Basename qw(dirname fileparse);
use Cwd            qw(abs_path cwd);
require File::Temp;
require File::Copy;
require File::Copy::Recursive; # libfile-copy-recursive-perl
require LWP::Simple;           # libwww-perl
require Git::Repository;       # libgit-repository-perl

my $root   = abs_path(dirname($0)."/..");
my $arroot = $root."/x-artifacts";

if((scalar @ARGV < 3) or $ARGV[0] eq "--help") {
	print <<~EOF;
	Usage maartifact download/require ARTIFACT [-b BRANCH] DEFINITION
	Usage maartifact extract ARTIFACT DESTDIR [-b BRANCH] [DEFINITION]\n

	See README.md/manpage maartifact(1) for details.
	EOF
}

my $arfile = $ARGV[1];
my ($name, $_path, $suffix) = fileparse($arfile, '\.[^\.]*');
my $arfile_abs = "$arroot/$arfile";

#-----------------------------------------------------------------[ Download ]--
if(
	(($ARGV[0] eq "extract") or ($ARGV[0] eq "download") or
						($ARGV[0] eq "require")) and
	((not -f $arfile_abs and not -d $arfile_abs) or
						($ARGV[0] eq "download"))
) {
	print("[maartifact] download artifact $arfile\n");

	my $artdef;
	my $branch;
	if($ARGV[2] eq "-b") {
		$artdef = $ARGV[4];
		$branch = $ARGV[3];
		if($branch !~ /^([a-z0-9_-]+|\.)+$/) {
			print("[maartifact] misformatted branch name.\n");
		}
	} else {
		$artdef = $ARGV[2];
		$branch = "master";
	}

	if($ARGV[0] eq "extract") {
		if(defined($ARGV[3])) {
			$artdef = $ARGV[3];
		} else {
			print("[maartifact] artifact definition missing.\n");
			exit(1);
		}
	}

	mkdir($arroot) if(not -d $arroot);
	if(($suffix eq ".deb") and ($artdef =~ m/^[a-z0-9-]+$/)) {
		# regular package name
		# TODO z SHOULD ALSO WORK W/O aptitude download as to enable this function on Windows and indepdendent of the currently running Debian release. OTOH the current variant has the advantage of taking an existing local debian mirror into consideration!
		my $dldir = File::Temp->newdir();
		my $prevwd = cwd();
		chdir($dldir);
		system("aptitude", "download", $artdef);
		chdir($prevwd);
		my @allf = glob("'$dldir/*.deb'");
		if((scalar @allf) ne 1) {
			print("[maartifact] glob non-unique: $dldir\n");
			exit(1);
		}
		File::Copy::move($allf[0], $arfile_abs);
		print("[maartifact] aptitude download successful.\n");
	} elsif($suffix eq ".git") {
		# try git download
		Git::Repository->run("clone", "--recursive", $artdef,
								$arfile_abs);
		my $git = Git::Repository->new(work_tree => $arfile_abs);
		$git->run("checkout", $branch);
		$git->run("submodule", "init");
		$git->run("submodule", "update", "--recursive");
	} else {
		# try file download
		if(not LWP::Simple::is_success(LWP::Simple::getstore($artdef,
								$arfile_abs))) {
			print("[maartifact] download failed for $artdef ".
						"(from $arfile_abs).\n");
			exit(1);
		}
	}
}

#------------------------------------------------------------------[ Extract ]--
if($ARGV[0] eq "extract") {
	my $destdir = $ARGV[2];
	mkdir($destdir) if(not -d $destdir);
	if($suffix eq ".git") {
		# copy git repo
		File::Copy::Recursive::dircopy($arfile_abs, $destdir);
	} elsif($suffix eq ".deb") {
		# extract deb
		# https://stackoverflow.com/questions/48362213
		my $dldir = File::Temp->newdir();
		system("7z", "e", "-o$dldir", "-ir!data.tar", $arfile_abs);
		# unfortunately, 7z does not preserve permissions, thus
		# the final extraction needs to be done by tar
		# system("7z", "x", "-o$destdir", "$dldir/data.tar");
		system("tar", "-C", "$destdir", "-xf", "$dldir/data.tar");
		unlink("$dldir/data.tar");
	} elsif($name =~ m/^.*\.tar$/) {
		# extract .tar....
		# note that this is not as portable as might seem:
		# OpenBSD tar does not automatically recognize compressed
		# input files and wants a decompressor specification for
		# extraction. As of now, this problem is ignored.
		system("tar", "-C", "$destdir", "-xf", $arfile_abs);
	} elsif(($suffix eq ".zip") or ($suffix eq ".gz") or 
				($suffix eq ".xz") or ($suffix eq ".bz2")) {
		# extract single-file archive or ZIP
		system("7z", "x", "-y", "-o$destdir", $arfile_abs);
	} else {
		print("[maartifact] Unknown suffix: $suffix\n");
		exit(1);
	}
}
