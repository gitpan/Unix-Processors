#/* -*- Mode: C -*- */
#/* $Id: Processors.xs,v 1.1 1999/11/15 20:38:18 wsnyder Exp $ */
#/* Author: Wilson Snyder <wsnyder@world.std.com> */
#/*##################################################################### */
#/* */
#/* This program is Copyright 1998 by Wilson Snyder. */
#/* This program is free software; you can redistribute it and/or */
#/* modify it under the terms of the GNU General Public License */
#/* as published by the Free Software Foundation; either version 2 */
#/* of the License, or (at your option) any later version. */
#/*  */
#/* This program is distributed in the hope that it will be useful, */
#/* but WITHOUT ANY WARRANTY; without even the implied warranty of */
#/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the */
#/* GNU General Public License for more details. */
#/*  */
#/* If you do not have a copy of the GNU General Public License write to */
#/* the Free Software Foundation, Inc., 675 Mass Ave, Cambridge,  */
#/* MA 02139, USA. */
#/*##################################################################### */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <unistd.h>
#include <sys/types.h>
#include <sys/processor.h>

typedef int CpuNumFromRef_t;

MODULE = Unix::Processors  PACKAGE = Unix::Processors

#/**********************************************************************/
#/* class->max_online() */
#/* Self is a argument, but we don't need it */
#/* We use sysconf, as that is more portable */
#/* Other packages also provide sysconf, but saves downloading them... */

long
max_online(self)
SV *self;
CODE:
{
    RETVAL = sysconf(_SC_NPROCESSORS_ONLN);
}
OUTPUT: RETVAL

#/**********************************************************************/
#/* class->max_clock() */
#/* Self is a argument, but we don't need it */

int
max_clock(self)
SV *self;
CODE:
{
    int clock = 0;
    int cpu;
    int last_cpu = 0;
    processor_info_t info, *infop=&info;
    for (cpu=0; cpu < last_cpu+16; cpu++) {
	if (processor_info (cpu, infop)==0
	    && infop->pi_state == P_ONLINE) {
	    if (clock < infop->pi_clock) {
		clock = infop->pi_clock;
	    }
	    last_cpu = cpu;
	}
    }
    RETVAL = clock;
}
OUTPUT: RETVAL

#/**********************************************************************/
#/**********************************************************************/
#/**********************************************************************/
#/**********************************************************************/
#/**********************************************************************/

MODULE = Unix::Processors  PACKAGE = Unix::Processors::Info

#/**********************************************************************/
#/* class->id() */

int
id (cpu)
CpuNumFromRef_t cpu
PROTOTYPE: $
CODE:
{
    RETVAL = cpu;
}
OUTPUT: RETVAL

#/**********************************************************************/
#/* class->clock() */

int
clock (cpu)
CpuNumFromRef_t cpu
PROTOTYPE: $
CODE:
{
    processor_info_t info, *infop=&info;
    RETVAL = 0;
    if (processor_info (cpu, infop)==0) {
	RETVAL = infop->pi_clock;
    }
}
OUTPUT: RETVAL

#/**********************************************************************/
#/* class->state() */

SV *
state (cpu)
CpuNumFromRef_t cpu
PROTOTYPE: $
CODE:
{
    processor_info_t info, *infop=&info;
    ST(0) = &PL_sv_undef;
    if (processor_info (cpu, infop)==0) {
	switch (infop->pi_state) {
	case P_ONLINE:
	    ST(0) = sv_newmortal();
	    sv_setpv (ST(0), "online");
	    break;
	case P_OFFLINE:
	    ST(0) = sv_newmortal();
	    sv_setpv (ST(0), "offline");
	    break;
	case P_POWEROFF:
	    ST(0) = sv_newmortal();
	    sv_setpv (ST(0), "poweroff");
	    break;
	}
    }
}

#/**********************************************************************/
#/* class->type() */

SV *
type (cpu)
CpuNumFromRef_t cpu
PROTOTYPE: $
CODE:
{
    processor_info_t info, *infop=&info;
    ST(0) = &PL_sv_undef;
    if (processor_info (cpu, infop)==0) {
	ST(0) = sv_newmortal();
	sv_setpv (ST(0), infop->pi_processor_type);
    }
}
