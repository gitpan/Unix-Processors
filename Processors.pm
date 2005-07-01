# Unix::Processors - Verilog PLI
# $Id: Processors.pm,v 1.25 2005/07/01 18:09:56 wsnyder Exp $
# Author: Wilson Snyder <wsnyder@wsnyder.org>
######################################################################
#
# Copyright 1999-2005 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
######################################################################

=head1 NAME

Unix::Processors - Interface to processor (CPU) information

=head1 SYNOPSIS

  use Unix::Processors;

  my $procs = new Unix::Processors;
  print "There are ", $procs->max_online, " CPUs at ", $procs->max_clock, "\n";
  if ($procs->max_online != $procs->max_physical) {
      print "Hyperthreading between ",$procs->max_physical," physical CPUs.\n";
  }
  (my $FORMAT =   "%2s  %-8s     %4s    \n") =~ s/\s\s+/ /g;
  printf($FORMAT, "#", "STATE", "CLOCK",  "TYPE", ); 
  foreach my $proc (@{$procs->processors}) {
      printf ($FORMAT, $proc->id, $proc->state, $proc->clock, $proc->type);
  }

=head1 DESCRIPTION

This package provides accessors to per-processor (CPU) information.
The object is obtained with the Unix::Processors::processors call.
the operating system in a OS independent manner.

=over 4

=item max_online

Return number of processors currently online.  On hyperthreaded Linux
systems, this indicates the maximum number of simultaneous threads that may
execute; see max_physical for the real physical CPU count.

=item max_physical

Return number of physical processors currently online.

=item max_clock

Return the maximum clock speed across all online processors. Not all OSes support this call.
  
=item processors

Return an array of processor references.  See the Unix::Processors::Info
manual page.  Not all OSes support this call.

=back

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.com/>.

Copyright 1999-2005 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License or the Perl Artistic License.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<Unix::Processors::Info>, L<Sys::Sysconf>

=cut

package Unix::Processors;
use Unix::Processors::Info;

$VERSION = '2.032';

require DynaLoader;
@ISA = qw(DynaLoader);

use strict;
use Carp;

######################################################################
#### Configuration Section

bootstrap Unix::Processors;

######################################################################
#### Accessors

sub new {
    # NOP for now, just need a handle for other routines
    @_ >= 1 or croak 'usage: Unix::Processors->new ({options})';
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {@_,};
    bless $self, $class;
    return $self;
}

sub processors {
    my $self = shift; ($self && ref($self)) or croak 'usage: $self->max_online()';
    my @list;
    for (my $cnt=0; $cnt<64; $cnt++) {
	my $val = $cnt;
	my $vref = \$val;  # Just a reference to a cpu number
	bless $vref, 'Unix::Processors::Info';
	if ($vref->type) {
	    push @list, $vref;
	}
    }
    return \@list;
}

######################################################################
#### Package return
1;
