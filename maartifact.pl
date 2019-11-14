#!/usr/bin/perl
# maartifact.pl 1.0.0, Copyright (c) 2019 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de

use strict;
use warnings FATAL => 'all';
use autodie;

use File::Basename qw(dirname fileparse);
use Cwd            qw(abs_path cwd);
require File::Temp;
require File::Copy;
require File::Copy::Recursive; # libfile-copy-recursive-perl
require LWP::Simple; # libwww-perl
require Git::Repository; # libgit-repository-perl

my $root = abs_path(dirname($0)."/..");
my $arroot = $root."/x-artifacts/managed";

if(scalar @ARGV < 3) {
	print("USAGE maartifact extract ARTIFACT DESTIR [DEFINITION]\n");
	print("See source code for details.");
	exit(1);
}

if($ARGV[0] eq "extract") {
	my $arfile = $ARGV[1];
	my ($name, $_path, $suffix) = fileparse($arfile, '\.[^\.]*');
	my $arfile_abs = "$arroot/$arfile";
	# -- download --
	if(not -f $arfile_abs and not -d $arfile_abs) {
		print("[maartifact] trying to download artifact $arfile\n");
		if(!defined($ARGV[3])) {
			print("[maartifact] Artifact definition missing.\n");
			exit(1);
		}
		my $artdef = $ARGV[3];
		mkdir($arroot) if(not -d $arroot);
		if(($suffix eq ".deb") and ($artdef =~ m/^[a-z0-9-]+$/)) {
			# regular package name
			my $dldir = File::Temp->newdir();
			my $prevwd = cwd();
			chdir($dldir);
			system("aptitude", "download", $artdef);
			chdir($prevwd);
			my @allf = glob("'$dldir/*.deb'");
			if((scalar @allf) ne 1) {
				print("[maartifact] Glob non-unique: $dldir\n");
				exit(1);
			}
			File::Copy::move($allf[0], $arfile_abs);
			print("[maartifact] aptitude download successful.\n");
		} elsif($suffix eq ".git") {
			# try git download
			Git::Repository->run("clone", $artdef, $arfile_abs);
		# For now, we try to do this with plain file downloads...
		#} elsif(($suffix eq ".deb") and
		#			($artdef =~ m/^[a-z0-9-]+=.+$/)) {
		#	# archive.debian.org
		#	print("[maartifact] ... N_IMPL\n");
		#	exit(1);
		} else {
			# try file download
			if(not LWP::Simple::is_success(LWP::Simple::getstore(
						$artdef, $arfile_abs))) {
				print("[maartifact] Artifact file download ".
						"failed for $artdef.\n");
				exit(1);
			}
		}
	}
	# -- extract --
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
} else {
	print("[maartifact] ".
			"Currently only `extract` parameter is supported.\n");
	exit(1);
}
