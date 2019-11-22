#!/usr/bin/perl
# maartifact.pl 1.0.2, Copyright (c) 2019 Ma_Sys.ma.
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
	print("Usage maartifact download/require ARTIFACT DEFINITION\n");
	print("Usage maartifact extract ARTIFACT DESTDIR [DEFINITION]\n");
	print("See README.md/manpage maartifact(1) for details.\n");
	exit(1);
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
	my $artdef = $ARGV[2];
	if(($ARGV[0] eq "extract") and !defined($ARGV[3])) {
		print("[maartifact] artifact definition missing.\n");
		exit(1);
	} else {
		$artdef = $ARGV[3];
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
		Git::Repository->run("clone", $artdef, $arfile_abs);
	} else {
		# try file download
		if(not LWP::Simple::is_success(LWP::Simple::getstore($artdef,
								$arfile_abs))) {
			print("[maartifact] download failed for $artdef.\n");
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
	} elsif(($suffix eq ".gz") or ($suffix eq ".xz") or
							($suffix eq ".bz2")) {
		# extract .tar....
		system("tar", "-C", "$destdir", "-xf", $arfile_abs);
	} else {
		print("[maartifact] Unknown suffix: $suffix\n");
		exit(1);
	}
}
