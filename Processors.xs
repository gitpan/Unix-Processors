#/* -*- Mode: C -*- */
#/* $Id: Processors.xs,v 1.7 2001/02/13 14:33:57 wsnyder Exp $ */
#/* Author: Wilson Snyder <wsnyder@wsnyder.org> */
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
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#ifdef __sun__
#include <sys/processor.h>
#endif

/* Missing in older headers */
#ifndef P_POWEROFF
#define P_POWEROFF 5
#endif

typedef int CpuNumFromRef_t;

#ifdef __linux__
char *proc_cpuinfo_field (const char *field)
    /* Return string from a field of /proc/cpuinfo, NULL if not found */
    /* Comparison is case insensitive */
{
    FILE *fp;
    static char line[1000];
    int len = strlen(field);
    char *result = NULL;
    if (NULL!=(fp = fopen ("/proc/cpuinfo", "r"))) {
	while (!feof(fp) && result==NULL) {
	    fgets (line, 990, fp);
	    if (0==strncasecmp (field, line, len)) {
		char *loc = strchr (line, ':');
		if (loc) {
		    result = loc+2;
		    loc = strchr (result, '\n');
		    if (loc) *loc = '\0';
		}
	    }
	}
	fclose(fp);
    }
    return (result);
}

int proc_cpuinfo_clock (void)
    /* Return clock frequency */
{
    char *value;
    value = proc_cpuinfo_field ("cpu MHz");
    if (value) return (atoi(value));
    value = proc_cpuinfo_field ("clock");
    if (value) return (atoi(value));
    value = proc_cpuinfo_field ("bogomips");
    if (value) return (atoi(value));
    return (0);
}

#endif

int proc_ncpus (void)
    /* Return number of cpus */
{
    int ncpu = sysconf(_SC_NPROCESSORS_ONLN);
#ifdef __linux__
    if (ncpu < 1) {
	/* SPARC Linux has a bug where SC_NPROCESSORS is set to 0. */
	char *value;
	value = proc_cpuinfo_field("ncpus active");
	if (value) ncpu = atoi(value);
    }
#endif
    if (ncpu<1) ncpu=1;	/* We're running this program, after all :-) */
    return (ncpu);
}

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
    RETVAL = proc_ncpus();
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
#ifdef __sun__
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
#endif
#ifdef __linux__
    int value = proc_cpuinfo_clock();
    if (value) clock = value;
#endif
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
#ifdef __sun__
    processor_info_t info, *infop=&info;
    RETVAL = 0;
    if (processor_info (cpu, infop)==0) {
	RETVAL = infop->pi_clock;
    }
#endif
#ifdef __linux__
    /* Cheat... Same clock for every CPU */
    int value = proc_cpuinfo_clock();
    RETVAL = 0;
    if (value) RETVAL = value;
#endif
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
    char *value = NULL;
#ifdef __sun__
    processor_info_t info, *infop=&info;
    if (processor_info (cpu, infop)==0) {
	switch (infop->pi_state) {
	case P_ONLINE:
	    value = "online";
	    break;
	case P_OFFLINE:
	    value = "offline";
	    break;
	case P_POWEROFF:
	    value = "poweroff";
	    break;
	}
    }
#endif
#ifdef __linux__
    /* Cheat... Assume all online */
    value = "online";
#endif
    if (value) {
	ST(0) = sv_newmortal();
	sv_setpv (ST(0), value);
    } else {
	ST(0) = &PL_sv_undef;
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
    char *value = NULL;
#ifdef __sun__
    processor_info_t info, *infop=&info;
    if (processor_info (cpu, infop)==0) {
	value = infop->pi_processor_type;
    }
#endif
#ifdef __linux__
    int ncpu = proc_ncpus();
    if (cpu < ncpu) {
	value = proc_cpuinfo_field ("model name");
	if (!value) value = proc_cpuinfo_field ("machine");
    }
#endif
    if (value) {
	ST(0) = sv_newmortal();
	sv_setpv (ST(0), value);
    } else {
	ST(0) = &PL_sv_undef;
    }
}
