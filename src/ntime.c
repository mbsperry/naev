/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file ntime.c
 *
 * @brief Handles the NAEV time.
 *
 * 1 SCU =  5e3 STP = 50e6 STU
 * 1 STP = 10e3 STU
 * 1 STU = 1 second
 *
 * Generally displayed as:
 *  <SCU>:<STP>.<STU> UST
 * The number of STU digits can be variable, for example:
 *
 *  630:3726.1 UST
 *  630:3726.12 UST
 *  630:3726.124 UST
 *  630:3726.1248 UST
 *  630:3726.12489 UST
 *
 * Are all valid.
 *
 * Acronyms:
 *    - UST : Universal Synchronized Time
 *    - STU : Smallest named time unit. Equal to the Earth second. 
 *    - STP : Most commonly used time unit. STPs are the new hours. 1 STP = 10,000 STU (about 2.8 Earth hours).
 *    - SCU : Used for long-term time periods. 1 SCU = 5000 STP (about 579 Earth days).
 */


#include "ntime.h"

#include "naev.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "hook.h"
#include "economy.h"


#define NT_SCU_STP   (5000)      /* STP in an SCU */
#define NT_STP_STU   (10000)     /* STU in an STP */
#define NT_STU_DIV   (1000)      /* Divider for extracting STU. */
#define NT_STU_DT    (30)        /* Update rate, how many STU are in a real second. */
#define NT_SCU_STU   ((ntime_t)NT_SCU_STP*(ntime_t)NT_STP_STU) /* STU in an SCU */
#define NT_STP_DIV   ((ntime_t)NT_STP_STU*(ntime_t)NT_STU_DIV) /* Divider for extracting STP. */
#define NT_SCU_DIV   ((ntime_t)NT_SCU_STU*(ntime_t)NT_STU_DIV) /* Divider for extracting STP. */


/**
 * @brief Used for storing time increments to not trigger hooks during Lua
 *        calls and such.
 */
typedef struct NTimeUpdate_s {
   struct NTimeUpdate_s *next; /**< Next in the linked list. */
   ntime_t inc; /**< Time increment assosciated. */
} NTimeUpdate_t;
static NTimeUpdate_t *ntime_inclist = NULL; /**< Time increment list. */


static ntime_t naev_time = 0; /**< Contains the current time in mSTU. */
static double naev_remainder = 0.; /**< Remainder when updating, to try to keep in perfect sync. */


/**
 * @brief Updatse the time based on realtime.
 */
void ntime_update( double dt )
{
   double dtt, tu;

   /* Calculate the effective time. */
   dtt = naev_remainder + dt*NT_STU_DT;

   /* Time to update. */
   tu             = floor( dtt * (double)NT_STU_DIV );
   naev_time     += (ntime_t) tu;
   naev_remainder = dtt - tu; /* Leave remainder. */
}


/**
 * @brief Creates a time structure.
 */
ntime_t ntime_create( int scu, int stp, int stu )
{
   ntime_t tscu, tstp, tstu;
   tscu = scu;
   tstp = stp;
   tstu = stu;
   return tscu*NT_SCU_DIV + tstp*NT_STP_DIV + tstu*NT_STU_DIV;
}


/**
 * @brief Gets the current time.
 *
 *    @return The current time in mSTU.
 */
ntime_t ntime_get (void)
{
   return naev_time;
}


/**
 * @brief Gets the SCU of a time.
 */
int ntime_getSCU( ntime_t t )
{
   return (t / NT_SCU_DIV);
}


/**
 * @brief Gets the STP of a time.
 */
int ntime_getSTP( ntime_t t )
{
   return (t / NT_STP_DIV) % NT_SCU_STP;
}


/**
 * @brief Gets the STU of a time.
 */
int ntime_getSTU( ntime_t t )
{
   return (t / NT_STU_DIV) % NT_STP_STU;
}


/**
 * @brief Gets the time in a pretty human readable format.
 *
 *    @param t Time to print (in STU), if 0 it'll use the current time.
 *    @param d Number of digits to use.
 *    @return The time in a human readable format (must free).
 */
char* ntime_pretty( ntime_t t, int d )
{
   char str[64];
   ntime_prettyBuf( str, sizeof(str), t, d );
   return strdup(str);
}


/**
 * @brief Gets the time in a pretty human readable format filling a preset buffer.
 *
 *    @param[out] str Buffer to use.
 *    @param max Maximum length of the buffer (recommended 64).
 *    @param t Time to print (in STU), if 0 it'll use the current time.
 *    @param d Number of digits to use.
 *    @return The time in a human readable format (must free).
 */
void ntime_prettyBuf( char *str, int max, ntime_t t, int d )
{
   ntime_t nt;
   int scu, stp, stu;

   if (t==0)
      nt = naev_time;
   else
      nt = t;

   /* UST (Universal Synchronized Time) - unit is STU (Synchronized Time Unit) */
   scu = ntime_getSCU( nt );
   stp = ntime_getSTP( nt );
   stu = ntime_getSTU( nt );
   if ((scu==0) && (stp==0)) /* only STU */
      snprintf( str, max, "%04d STU", stu );
   else if ((scu==0) || (d==0))
      snprintf( str, max, "%04d.%0*d STP", stp, d, stu );
   else /* UST format */
      snprintf( str, max, "UST %d:%04d.%0*d", scu, stp, d, stu );
}


/**
 * @brief Sets the time absolutely, does NOT generate an event, used at init.
 *
 *    @param t Absolute time to set to in STU.
 */
void ntime_set( ntime_t t )
{
   naev_time      = t;
   naev_remainder = 0.;
}


/**
 * @brief Sets the time relatively.
 *
 *    @param t Time modifier in STU.
 */
void ntime_inc( ntime_t t )
{
   naev_time += t;
   hooks_run("time");
   economy_update( t );
}


/**
 * @brief Sets the time relatively.
 *
 * This does NOT call hooks and such, they must be run with ntime_refresh
 *  manually later.
 *
 *    @param t Time modifier in STU.
 */
void ntime_incLagged( ntime_t t )
{
   NTimeUpdate_t *ntu, *iter;

   /* Create the time increment. */
   ntu = malloc(sizeof(NTimeUpdate_t));
   ntu->next = NULL;
   ntu->inc = t;

   /* Only member. */
   if (ntime_inclist == NULL)
      ntime_inclist = ntu;

   else {
      /* Find end of list. */
      for (iter = ntime_inclist; iter->next != NULL; iter = iter->next);
      /* Append to end. */
      iter->next = ntu;
   }
}


/**
 * @brief Checks to see if ntime has any hooks pending to run.
 */
void ntime_refresh (void)
{
   NTimeUpdate_t *ntu;

   /* We have to run all the increments one by one to ensure all hooks get
    * run and that no collisions occur. */
   while (ntime_inclist != NULL) {
      ntu = ntime_inclist;

      /* Run hook stuff and actually update time. */
      naev_time += ntu->inc;
      hooks_run("time");
      economy_update( ntu->inc );

      /* Remove the increment. */
      ntime_inclist = ntu->next;

      /* Free the increment. */
      free(ntu);
   }
}

