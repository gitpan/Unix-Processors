# Unix::Processors - Verilog PLI
# $Id: Processors.pm,v 1.11 2003/05/05 13:29:23 wsnyder Exp $
# Author: Wilson Snyder <wsnyder@wsnyder.org>
######################################################################
#
# This program is Copyright 2000 by Wilson Snyder.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of either the GNU General Public License or the
# Perl Artistic License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# If you do not have a copy of the GNU General Public License write to
# the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, 
# MA 02139, USA.
######################################################################

=head1 NAME

Unix::Processors - Interface to processor (CPU) information

=head1 SYNOPSIS

  use Unix::Processors;

  my $procs = new Unix::Processors;
  print "There are ", $procs->max_online, " CPUs at ", $procs->max_clock, "\n";
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
  Return number of processors currently online.

=item max_clock
  Return the maximum clock speed across all online processors.
  
=item processors
  Return a array or processor references.  See the Unix::Processors::Info
  manual page.  Not all OSes support this call.

=back

=head1 SEE ALSO

C<Unix::Processors::Info>, C<Sys::Sysconf>,

=head1 DISTRIBUTION

The latest version is available from CPAN.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut

package Unix::Processors;
use Unix::Processors::Info;

$VERSION = '2.012';

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
