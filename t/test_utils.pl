# $Id: test_utils.pl 42 2007-02-01 19:59:39Z wsnyder $
# DESCRIPTION: Perl ExtUtils: Common routines required by package tests
#
# Copyright 2001-2007 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License or the Perl Artistic License.

use vars qw($PERL);
use IO::File;

$PERL = "$^X -Iblib/arch -Iblib/lib";

mkdir 'test_dir',0777;

if (!$ENV{HARNESS_ACTIVE}) {
    use lib '.';
    use lib '..';
    use lib "blib/lib";
    use lib "blib/arch";
}

1;
