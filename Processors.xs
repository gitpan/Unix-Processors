#/* -*- Mode: C -*- */
#/* $Id: Processors.xs,v 1.13 2004/01/27 19:07:41 wsnyder Exp $ */
#/* Author: Wilson Snyder <wsnyder@wsnyder.org> */
#/* IRIX & FreeBSD port by: Daniel Gustafson <daniel@hobbit.se> */
#/*##################################################################### */
#/* */
#/* Copyright 1999-2004 by Wilson Snyder.  This program is free software; */
#/* you can redistribute it and/or modify it under the terms of either the GNU */
#/* General Public License or the Perl Artistic License. */
#/*  */
#/* This program is distributed in the hope that it will be useful, */
#/* but WITHOUT ANY WARRANTY; without even the implied warranty of */
#/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the */
#/* GNU General Public License for more details. */
#/*  */
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
# if defined(sgi)
#  define IRIX
# endif
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

#ifdef IRIX
#include <dirent.h>
#include <sys/invent.h>
#include <sys/pda.h>
#include <sys/sbd.h>
#include <sys/sysmp.h>
#include <sys/iograph.h>
#include <invent.h>
#include <sys/param.h>
#endif

#ifdef SUNOS
#include <sys/processor.h>
#endif

#ifdef __FreeBSD__
#include <stdlib.h>
#include <sys/types.h>
#include <sys/sysctl.h>
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

#ifdef __FreeBSD__
    int len = sizeof(num_cpus);
    sysctlbyname("hw.ncpu", &num_cpus, &len, NULL, NULL);
#endif

    if (num_cpus < 1)
        num_cpus=1;      /* We're running this program, after all :-) */
    return (num_cpus);
}

#ifdef IRIX
/* invent_cpuinfo_t irix_get_cpuinf(int cpuid);
 * Returns an invent_cpuinfo_t regarding the requested cpuid. */
invent_cpuinfo_t irix_get_cpuinf(int cpuid) {
    union {
        invent_generic_t generic;
        invent_cpuinfo_t cpu;
    } hw_inv;

    int attr_len = sizeof(hw_inv);
    DIR *hw_graph;
    struct dirent *hw_entry;
    char *hw_entry_buf = (char *)malloc(MAXPATHLEN);
    char *hw_filename = (char *)malloc(MAXPATHLEN);

    if ((hw_graph = opendir("/hw/cpunum")) != NULL) {
	while ((hw_entry = readdir(hw_graph)) != NULL) {

            if ((strcmp(hw_entry->d_name, ".") != 0) && (strcmp(hw_entry->d_name, "..") != 0)) {
                strcpy(hw_filename, "/hw/cpunum/");
                strncat(hw_filename, hw_entry->d_name, 1);

                if (realpath(hw_filename, hw_entry_buf) != NULL) {
                    if (attr_get(hw_entry_buf, INFO_LBL_DETAIL_INVENT, (char *)&hw_inv, &attr_len, 0) == 0) {
                        if (hw_inv.generic.ig_invclass == INV_PROCESSOR) {
                            if (hw_inv.cpu.ic_cpuid == cpuid) {
				break;
			    }
			}
		    }
		}
            }
        }
    }

    closedir(hw_graph);
    return(hw_inv.cpu);
}
#endif

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
#ifdef IRIX
    int num_cpus = proc_ncpus();
    if ((num_cpus > 0) && (num_cpus < 3)) {
	inventory_t *sys_invent;
	if (setinvent() != -1) {
	    for (sys_invent = getinvent(); (sys_invent); sys_invent = getinvent()) {
		if ((sys_invent->inv_class == INV_PROCESSOR) && (sys_invent->inv_type == INV_CPUBOARD)) {
		    clock = sys_invent->inv_controller;
		    break;
		}
	    }
	    endinvent();
	}
    }
    else {
	invent_cpuinfo_t cpu_info;
	int i;
	for (i = 0; i < proc_ncpus(); i++) {
	    cpu_info = irix_get_cpuinf(i);
	    if (cpu_info.ic_cpuid == i)
		if (cpu_info.ic_cpu_info.cpufq > clock)
		    clock = cpu_info.ic_cpu_info.cpufq;
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
#ifdef IRIX
    int num_cpus = proc_ncpus();
    if ((num_cpus > 0) && (num_cpus < 3)) {
	inventory_t *sys_invent;
	if (setinvent() != -1) {
	    while ((sys_invent = getinvent()) != NULL) {
		if ((sys_invent->inv_class == INV_PROCESSOR) && (sys_invent->inv_type == INV_CPUBOARD)) {
		    value = sys_invent->inv_controller;
		    break;
		}
	    }
	    endinvent();
	}
    }
    else {
	invent_cpuinfo_t cpu_info;
	cpu_info = irix_get_cpuinf(cpu);
	if (cpu_info.ic_cpuid == cpu)
	    value = cpu_info.ic_cpu_info.cpufq;
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
#endif
#ifdef IRIX
    int num_cpus;
    if ((num_cpus = sysmp(MP_NPROCS)) != -1) {
	struct pda_stat proc_info[num_cpus];
	if (sysmp(MP_STAT, proc_info) != -1) {
	    if (proc_info[cpu].p_flags == PDAF_MASTER)
		value = "MASTER";
	    else if (proc_info[cpu].p_flags == PDAF_CLOCK)
		value = "CLOCK";
	    else if (proc_info[cpu].p_flags == PDAF_ENABLED)
		value = "ENABLED";
	    else if (proc_info[cpu].p_flags == PDAF_FASTCLOCK)
		value = "FASTCLOCK";
	    else if (proc_info[cpu].p_flags == PDAF_ISOLATED)
		value = "ISOLATED";
	    else if (proc_info[cpu].p_flags == PDAF_BROADCAST_OFF)
		value = "BROADCAST_OFF";
	    else if (proc_info[cpu].p_flags == PDAF_NONPREEMPTIVE)
		value = "NONPREEMPTIVE";
	    else if (proc_info[cpu].p_flags == PDAF_NOINTR)
		value = "NOINTR";
	    else if (proc_info[cpu].p_flags == PDAF_ITHREADSOK)
		value = "ITHREADSOK";
	    else if (proc_info[cpu].p_flags == PDAF_DISABLE_CPU)
		value = "DISABLE_CPU";
	    else if (proc_info[cpu].p_flags == PDAF_EXCLUDED)
		value = "EXCLUDED";
	    else
		/*
		 * No p_flags value is specified for uniprocessor
		 * systems. Return ONLINE.
		 */
		value = "ONLINE";
	}
    }
#endif
    /* Cheat... Assume all online */
    if (value == NULL)
	value = "online";
    /* Return it */
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
#ifdef MIPS
    if (cpu < proc_ncpus()) {
	if ((value = (char *)malloc(64)) != NULL) {
	    sysinfo(SI_MACHINE, value, 64);
	}
    }
#endif
#ifdef IRIX
    if (cpu < proc_ncpus()) {
	int cpu_data = 0;
	int num_cpus = proc_ncpus();
	if ((num_cpus > 0) && (num_cpus < 3)) {
	    inventory_t *sys_invent;
	    if (setinvent() != -1) {
		while ((sys_invent = getinvent()) != NULL) {
		    if ((sys_invent->inv_class == INV_PROCESSOR) && (sys_invent->inv_type == INV_CPUCHIP)) {
			cpu_data = sys_invent->inv_state;
			break;
		    }
		}
		endinvent();
	    }
	}
	else {
	    invent_cpuinfo_t cpu_info;
	    cpu_info = irix_get_cpuinf(cpu);
	    if (cpu_info.ic_cpuid == cpu)
		cpu_data = cpu_info.ic_cpu_info.cpuflavor;
	}
	if (cpu_data != 0) {
	    if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R2000A)
		strcat(value, " MIPS R2000A");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R2000)
		strcat(value, " MIPS R2000A");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R3000A)
		strcat(value, " MIPS R3000A");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R3000)
		strcat(value, " MIPS R3000");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R4000) {
		if (((cpu_data&C0_MAJREVMASK)>>C0_MAJREVSHIFT) >= C0_MAJREVMIN_R4400)
		    strcat(value, " MIPS R4400");
		else
		    strcat(value, " MIPS R4000");
	    }
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R4650)
		strcat(value, " MIPS R4650");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R4700)
		strcat(value, " MIPS R4700");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R4600)
		strcat(value, " MIPS R4600");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R5000)
		strcat(value, " MIPS R5000");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_RM5271)
		strcat(value, " MIPS RM5271");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R6000A)
		strcat(value, " MIPS R6000A");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R6000)
		strcat(value, " MIPS R6000");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_RM7000)
		strcat(value, " MIPS RM7000");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R8000)
		strcat(value, " MIPS R8000");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R10000)
		strcat(value, " MIPS R10000");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R12000)
		strcat(value, " MIPS R12000");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R14000)
		strcat(value, " MIPS R14000");
	    else
		strcat(value, " Undefined MIPS");
	    sprintf(value, "%s Chip Rev: %x.%x", value, ((cpu_data&C0_MAJREVMASK)>>C0_MAJREVSHIFT), ((cpu_data&C0_MINREVMASK)>>C0_MINREVSHIFT));
	}
    }
#endif
#ifdef __FreeBSD__
    if (cpu < proc_ncpus()) {
	if ((value = (char *)malloc(64)) != NULL) {
	    int len = 64;
	    sysctlbyname("hw.machine_arch", value, &len, NULL, NULL);
	}
    }
#endif

    if (value) {
	ST(0) = sv_newmortal();
	sv_setpv (ST(0), value);
    } else {
	ST(0) = &PL_sv_undef;
    }
}
