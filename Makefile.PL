# $Id: Makefile.PL,v 1.12 2004/01/27 19:07:41 wsnyder Exp $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package
#
# Copyright 1998-2004 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use ExtUtils::MakeMaker;
use Carp;

sub MY::postamble {
"
README: readme.texi
	-rm -f \$@
	makeinfo \$< --output \$@ --no-headers --no-validate

## Maintainer use:
tag:
	cvs tag -F \$(DISTNAME)_\$(VERSION_SYM) .

maintainer-dist: dist tag
	cp \$(DISTVNAME).tar.gz \$(HOME)/src/kits
	mv \$(DISTVNAME).tar.gz \$(HOME)/backpack

maintainer-clean: distclean
	-rm README Makefile

dist: distcheck README
";
}

# Check for AIX libraries and headers required to support this package
# System calls: perfstat_cpu_total, 
#              /usr/include/libperfstat.h
#              /usr/lib/libperfstat.a

my $ARCH = `uname`;
chomp($ARCH);

my $libs;
my $defs;
my $incs;

if ($ARCH eq "AIX") {
    print "\nChecking for required AIX components...\n";
    my $has_perfstat;
    if (-f "/usr/include/libperfstat.h") {
	print "  - libperfstat.a appears to be installed\n";
	$libs = "-lperfstat";
	$defs = "-DHAS_PERFSTAT";
	$has_perfstat = 1;
    } else {
	print "  - libperfstat.a is not installed\n";
    }
    print "\n";
}

WriteMakefile(
	      NAME => "Unix::Processors",
	      AUTHOR	=> 'Wilson Snyder <wsnyder@wsnyder.org>',
	      ABSTRACT_FROM => 'Processors.pm',
	      VERSION_FROM  => 'Processors.pm',
	      DISTNAME  => 'Unix-Processors',
	      LIBS      => $libs,
	      DEFINE    => $defs,
	      'dist'    => {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz', 
			    DIST_DEFAULT => 'README all tardist',
			},
	      );
