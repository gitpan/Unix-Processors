# $Id: Makefile.PL,v 1.9 2002/08/30 14:30:32 wsnyder Exp $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package

use ExtUtils::MakeMaker;
use Carp;

sub MY::postamble {
"
README: readme.texi
	-rm \$@
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

WriteMakefile(
	      NAME => "Unix::Processors",
	      AUTHOR	=> 'Wilson Snyder <wsnyder@wsnyder.org>',
	      ABSTRACT_FROM => 'Processors.pm',
	      VERSION_FROM  => 'Processors.pm',
	      DISTNAME  => 'Unix-Processors',
	      'dist'    => {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz', 
			    DIST_DEFAULT => 'README all tardist',
			},
	      );
