#$Id: test.pl,v 1.7 2005/04/01 15:02:05 wsnyder Exp $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#
# Copyright 1999-2005 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Unix::Processors;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# 2: Constructor
print (($procs = new Unix::Processors()
	) ? "ok 2\n" : "not ok 2\n");

# 3: Max online
my $online = $procs->max_online;
print "Cpus online: $online\n";
print (($online) ? "ok 3\n" : "not ok 3\n");

# 4: Max physical
my $phys = $procs->max_physical;
print "Physical cpus: $phys\n";
print (($phys) ? "ok 4\n" : "not ok 4\n");

# 5: Max speed
my $clock = $procs->max_clock;
print "Cpu frequency: $clock\n";
print (($online) ? "ok 5\n" : "not ok 5\n");

# 6: Procs state
my $proclist = $procs->processors;
print (($proclist) ? "ok 6\n" : "not ok 6\n");

# 7: Procs owner
my $ok=1;
foreach my $proc (@{$procs->processors}) {
    $ok = 0 if (!$proc->state || !$proc->type);
    printf ("Id %s  State %s  Clock %s  Type %s\n",
	    $proc->id, $proc->state, $proc->clock, $proc->type);
}
print (($ok) ? "ok 7\n" : "not ok 7\n");

# 8: Destructor
undef $procs;
print "ok 8\n";
