# $Id: Makefile.PL,v 1.6 2000/01/21 13:38:38 wsnyder Exp $

use ExtUtils::MakeMaker;
use Carp;

sub MY::postamble {
"
README: readme.texi
	-rm \$@
	makeinfo \$< --output \$@ --no-headers --no-validate

maintainer-clean: distclean
	-rm README Makefile

dist: distcheck README
";
}

WriteMakefile(
	      NAME => "Unix::Processors",
	      AUTHOR	=> 'Wilson Snyder <wsnyder@world.std.com>',
	      ABSTRACT_FROM => 'Processors.pm',
	      VERSION_FROM  => 'Processors.pm',
	      DISTNAME  => 'Unix-Processors',
	      'dist'    => {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz', 
			    DIST_DEFAULT => 'README all tardist',
			},
	      );
