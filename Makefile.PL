# $Id: Makefile.PL,v 1.4 1999/12/02 14:34:09 wsnyder Exp $

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
	      VERSION   => '1.4',
	      DISTNAME  => 'Unix-Processors',
	      'dist'    => {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz', 
			    DIST_DEFAULT => 'README all tardist',
			},
	      );
