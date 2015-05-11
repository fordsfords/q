/* bsem.h - binary semaphore */
/*
# This code and its documentation is Copyright 2014 Steven Ford, sford@geeky-boy.com
# and licensed under Creative Commons "CC0": http://creativecommons.org/publicdomain/zero/1.0/
# To the extent possible under law, Steve Ford has waived all copyright and related or
# neighboring rights to this work.  This work is published from: United States.
*/

#ifndef BSEM_H
#define BSEM_H

typedef unsigned int bsemerr_t;     /* see BSEMERR_* definitions above */

struct bsem_s;                       /* forward (opaque) definition */
typedef struct bsem_s bsem_t;      /* object type of binary semaphore instance */

/* Most bsem APIs return "bsemerr_t".  These definitions must
 * be kept in sync with the "bsemerrs" string array in "bsem.c". */
#define BSEMERR_OK 0         /* Success */
#define BSEMERR_BUG1 1       /* Internal software bug - should never happen */
#define BSEMERR_BADCOUNT 2   /* No memory available */
#define BSEMERR_MALLOCERR 3  /* No memory available */
#define BSEMERR_TIMEDOUT 4   /* Wait timed out */
#define LAST_BSEMERR 6   /* Set to value of last "BSEMERR_*" definition */

bsemerr_t bsem_create(bsem_t **rtn_bsem, int init_count);
/* Create an instance of a binary semaphore.
 * rtn_bsem   : Pointer to caller's handle for semaphore instance.
 * init_count : Initial count for semaphore.  Must be 0 or 1.
 * Returns BSEMERR_OK on success, or other BSEMERR_* value on error. */


bsemerr_t bsem_delete(bsem_t *bsem);
/* delete an instance of a binary semaphore.
 * bsem   : caller's semaphore instance handle.
 * Returns BSEMERR_OK on success, or other BSEMERR_* value on error. */


char *bsemerr_str(bsemerr_t bsemerr);
/* Returns a string representation of a bsem API return err code.
 * bsemerr : value returned by most bsem APIs indicating success or faiure.
 * (See bsem.h for list of BSEMERR_* definitions.)
 * Example:
 *   bsemerr_t berr = bsem_create(*/

#endif  /* BSEM_H */
