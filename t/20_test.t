#!/usr/bin/perl -w
# $Id: 20_test.t 42 2007-02-01 19:59:39Z wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 1999-2007 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Test;

BEGIN { plan tests => 8 }
BEGIN { require "t/test_utils.pl"; }

use Unix::Processors;
ok(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# 2: Constructor
my $procs = new Unix::Processors();
ok ($procs);

# 3: Max online
my $online = $procs->max_online;
print "Cpus online: $online\n";
ok($online);

# 4: Max physical
my $phys = $procs->max_physical;
print "Physical cpus: $phys\n";
ok($phys);

# 5: Max speed
my $clock = $procs->max_clock;
print "Cpu frequency: $clock\n";
ok($online);

# 6: Procs state
my $proclist = $procs->processors;
ok($proclist);

# 7: Procs owner
my $ok=1;
foreach my $proc (@{$procs->processors}) {
    $ok = 0 if (!$proc->state || !$proc->type);
    printf +("Id %s  State %s  Clock %s  Type %s\n",
	     $proc->id, $proc->state, $proc->clock, $proc->type);
}
ok($ok);

# 8: Destructor
undef $procs;
ok(1);

