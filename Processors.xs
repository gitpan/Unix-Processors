#/* -*- Mode: C -*- */
#/* $Id: Processors.xs,v 1.9 2003/01/02 14:53:55 wsnyder Exp $ */
#/* Author: Wilson Snyder <wsnyder@wsnyder.org> */
#/*##################################################################### */
#/* */
#/* This program is Copyright 2002 by Wilson Snyder. */
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

#if defined(_AIX)
# define AIX
#endif

#if defined(hpux) || defined(__hpux)
# define HPUX
#endif

#if defined(__osf__) && (defined(__alpha) || defined(__alpha__))
# define OSF_ALPHA
#endif

#if defined(__mips)
# define MIPS
#endif

#if defined(sun) || defined(__sun__)
# define SUNOS
#endif

#ifdef AIX
# ifdef HAS_PMAPI
#  include <pmapi.h>
# endif
# ifdef HAS_PERFSTAT
#  include <libperfstat.h>
# endif
#endif

#ifdef HPUX
#include <sys/param.h>
#include <sys/pstat.h>
struct pst_dynamic psd;
#endif

#ifdef OSF_ALPHA
#include <sys/sysinfo.h>
#include <machine/hal_sysinfo.h>
#endif

#ifdef MIPS
#include <sys/systeminfo.h>
#endif

#ifdef SUNOS
#include <sys/processor.h>
#endif

/* Missing in older headers */
#ifndef P_POWEROFF
#define P_POWEROFF 5
#endif

typedef int CpuNumFromRef_t;

#/**************************************************************/

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
    int num_cpus = 0;

    /* Determine how many processors are online and available */
#ifdef HPUX
    if (pstat_getdynamic(&psd, sizeof(psd), (size_t)1, 0) != -1)
        num_cpus = psd.psd_proc_cnt;
#endif

#ifdef OSF_ALPHA
    getsysinfo(GSI_CPUS_IN_BOX,&num_cpus,sizeof(num_cpus),0,0)
#endif

#ifdef MIPS
    char buf[16];
    if (sysinfo(_MIPS_SI_NUM_PROCESSORS, buf, 10) != -1)
        num_cpus = atoi(buf);
#endif

    /* Generic linux defaults */
#if defined(SUNOS) || defined(AIX) || defined (__linux__)
    if (num_cpus < 1)
	num_cpus = sysconf(_SC_NPROCESSORS_ONLN);
# ifdef __linux__
    if (num_cpus < 1) {
	/* SPARC Linux has a bug where SC_NPROCESSORS is set to 0. */
	char *value;
	value = proc_cpuinfo_field("ncpus active");
	if (value) num_cpus = atoi(value);
    }
# endif
#endif

    if (num_cpus < 1)
        num_cpus=1;      /* We're running this program, after all :-) */
    return (num_cpus);
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
#ifdef AIX
# if defined(HAS_PERFSTAT)
    perfstat_cpu_total_t data;
    if (perfstat_cpu_total (0, &data, sizeof(data), 1)) {
      clock = data.processorHZ / 1000000;
    }
# elif defined(HAS_PMAPI)
    /* pm_cycles uses an approximation to arrive at cycle time
     * so we round up to the nearest Mhz */
    clock = (int)((pm_cycles() + 500000) / 1000000);
# endif
#endif
#ifdef HPUX
    /* all processors have the same clock on HP - just report the first one */
    struct pst_processor psp;
    if (pstat_getprocessor(&psp, sizeof(psp), 1, 0)) {    
      clock = psp.psp_iticksperclktick / 10000;
    }
#endif
#ifdef SUNOS
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

SV *
clock (cpu)
CpuNumFromRef_t cpu
PROTOTYPE: $
CODE:
{
    int value = 0;
#ifdef AIX
    int num_cpus = proc_ncpus();
    if (cpu < num_cpus) {
# if defined(HAS_PERFSTAT)
      perfstat_cpu_total_t data;
      if (perfstat_cpu_total (0, &data, sizeof(data), 1)) {
	value = data.processorHZ / 1000000;
      }
# elif defined(HAS_PMAPI)
      /* pm_cycles uses an approximation to arrive at cycle time
       * so we round up to the nearest Mhz */
      clock = (int)((pm_cycles() + 500000) / 1000000);
# endif
    }
#endif
#ifdef HPUX
    int num_cpus = proc_ncpus();
    if (cpu < num_cpus) {
      /* all processors have the same clock on HP - just report the first one */
      struct pst_processor psp;
      if (pstat_getprocessor(&psp, sizeof(psp), 1, 0)) {    
	value = psp.psp_iticksperclktick / 10000;
      }
    }
#endif
#ifdef SUNOS
    processor_info_t info, *infop=&info;
    if (processor_info (cpu, infop)==0) {
      value = infop->pi_clock;
    }
#endif
#ifdef __linux__
    /* Cheat... Same clock for every CPU */
    value = proc_cpuinfo_clock();
#endif
    if (value) {
	ST(0) = sv_newmortal();
	sv_setiv (ST(0), value);
    } else {
	ST(0) = &PL_sv_undef;
    }
}

#/**********************************************************************/
#/* class->state() */

SV *
state (cpu)
CpuNumFromRef_t cpu
PROTOTYPE: $
CODE:
{
    char *value = NULL;
#ifdef SUNOS
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
#else
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
#ifdef AIX
# if defined(HAS_PERFSTAT)
    int num_cpus = proc_ncpus();
    if (cpu < num_cpus) {
      perfstat_cpu_total_t data;
      if (perfstat_cpu_total (0, &data, sizeof(data), 1)) {
	value = data.description;
      }
    }
# endif
#endif
#ifdef HPUX
    int num_cpus = proc_ncpus();
    if (cpu < num_cpus) {
	switch(sysconf(_SC_CPU_VERSION)) {
	case CPU_PA_RISC1_0:
		value = "HP PA-RISC 1.0";
		break;
	case CPU_PA_RISC1_1:
		value = "HP PA-RISC 1.1";
		break;
	case CPU_PA_RISC1_2:
		value = "HP PA-RISC 1.2";
		break;
	case CPU_PA_RISC2_0:
		value = "HP PA-RISC 2.0";
		break;
	}
    }
#endif
#ifdef SUNOS
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
