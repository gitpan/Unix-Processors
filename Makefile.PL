# $Id: Makefile.PL,v 1.1 1999/11/15 20:38:18 wsnyder Exp $

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
	      VERSION   => '1.1',
	      DISTNAME  => 'Unix-Processors',
	      'dist'    => {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz', 
			    DIST_DEFAULT => 'README all tardist',
			},
	      );
