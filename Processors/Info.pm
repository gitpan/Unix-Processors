# Unix::Processor - Verilog PLI
# $Id: Info.pm,v 1.6 2001/02/13 14:36:56 wsnyder Exp $
# Author: Wilson Snyder <wsnyder@wsnyder.org>
######################################################################
#
# This program is Copyright 2000 by Wilson Snyder.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of either the GNU General Public License or the
# Perl Artistic License, with the exception that it cannot be placed
# on a CD-ROM or similar media for commercial distribution without the
# prior approval of the author.
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

Unix::Processors::Info - Interface to processor (CPU) information

=head1 SYNOPSIS

  use Unix::Processors;

  ...
  $aproc = $proc->processors[0];
      print ($aproc->id, $aproc->state, $aproc->clock);
  }

=head1 DESCRIPTION

  This package provides access to per-processor (CPU) information from
the operating system in a OS independent manner.

=over 4

=item id
  Return the cpu number of this processor.

=item clock
  Return the clock frequency in MHz.
  
=item state
  Return the cpu state as "online", "offline", or "poweroff".

=item type
  Return the cpu type.

=back

=head1 SEE ALSO

C<Unix::Processors>,

=head1 DISTRIBUTION

The latest version is available from CPAN.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut

package Unix::Processors::Info;

require DynaLoader;
@ISA = qw(DynaLoader);

use strict;
use vars qw($VERSION);

######################################################################
#### Configuration Section

$VERSION = '1.8';

######################################################################
#### Code

#It's all in C

######################################################################
#### Package return
1;
