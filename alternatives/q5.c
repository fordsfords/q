/* q.c - lock-free, non-blocking message queue */

/* This work is dedicated to the public domain under CC0 1.0 Universal:
 * http://creativecommons.org/publicdomain/zero/1.0/
 * 
 * To the extent possible under law, Steven Ford has waived all copyright
 * and related or neighboring rights to this work. In other words, you can 
 * use this code for any purpose without any restrictions.
 * This work is published from: United States.
 * Project home: https://github.com/fordsfords/q
 */

/* Although the code contained herein was written from scratch by Steve Ford in 2014,
 * the algorithm was influenced by John D. Valois' 1994 paper:
 *     "Implementing Lock-Free Queues"
 * http://people.cs.pitt.edu/~jacklange/teaching/cs2510-f12/papers/implementing_lock_free.pdf
 *     Valois, J.: Implementing lock-free queues. In: Proceedings of the Seventh
 *     International Conference on Parallel and Distributed Computing Systems. (1994) 64–69
 *
 * See q.h file for details on the API functions.
 */

#include <stdlib.h>
#include <string.h>
#include <pthread.h>

/* If built with "-DSELFTEST" then include extras for unit testing. */
#ifdef SELFTEST
#  include "q_selftest.h"
#endif

#include "q.h"

#define Q_FENCE 0x7d831f20   /* used for testing (random number generated at random.org) */

/* This list of strings must be kept in sync with the
 * corresponding "QERR_*" constant definitions in "q.h".
 * It is used by the q_qerr_str() function. */
static char *qerrs[] = {
	"QERR_OK",
	"QERR_BUG1",
	"QERR_BUG2",
	"QERR_BADSIZE",
	"QERR_MALLOCERR",
	"QERR_FULL",
	"QERR_EMPTY",
	"BAD_QERR", NULL};
#define BAD_QERR (sizeof(qerrs)/sizeof(qerrs[0]) - 2)


struct q_msg_s {
	void *d;
};
typedef struct q_msg_s q_msg_t;

/* q.h contains an empty forward definition of "q_s", and defines "q_t" */
struct q_s {
	unsigned int enq_cnt;      /* count of successful messages enqueued (tail pointer) */
	unsigned int sav_deq_cnt;
	char enq_pad[CACHE_LINE_SIZE - (2*sizeof(unsigned int))];  /* align next var on cache line */

	q_msg_t * batched_msgs;    /* Array of "q_size" void pointers */
	unsigned int deq_cnt;      /* count of successful messages dequeued (head pointer) */
	unsigned int sav_enq_cnt;
	unsigned int batch_size;   /* Number of batched messages */
	unsigned int batch_i;      /* Next batched message to deliver */
	char deq_pad[CACHE_LINE_SIZE - ( sizeof(void *) + 4*sizeof(unsigned int) )];

	q_msg_t * msgs;  /* Array of "q_size" void pointers */
	unsigned int size_mask;    /* Number of void pointers in "msgs" minus 1 */
	/* make total size a multiple of cache line size, to prevent interference with whatever comes after */
	char final_pad[CACHE_LINE_SIZE - (sizeof(unsigned int) + sizeof(void **))];
};  /* struct q_s */


/* Internal function: return 1 if power of 2 */
static int is_power_2(unsigned int n)
{
	/* Thanks to Alex Allain at http://www.cprogramming.com/tutorial/powtwosol.html for this cute algo. */
	return ((n-1) & n) == 0;
}  /* is_power_2 */


/* See q.h for doc */
char *q_qerr_str(qerr_t qerr)
{
	if (qerr >= BAD_QERR) { return qerrs[BAD_QERR]; }  /* bad qerr */

	return qerrs[qerr];
}  /* q_qerr_str */


/* See q.h for doc */
qerr_t q_create(q_t **rtn_q, unsigned int q_size)
{
	/* Sanity check the status definitions and strings */
	if (LAST_QERR != BAD_QERR - 1) { return QERR_BUG1; }  /* the QERR_* are out of sync with qerrs[] */
	if (sizeof(q_t) % CACHE_LINE_SIZE != 0) { return QERR_BUG2; }  /* q_t not multiple of cache line size */

	/* Sanity check input size */
	if (q_size <= 1 || ! is_power_2(q_size)) { return QERR_BADSIZE; }

	/* Create queue object instance */
	q_t *q = NULL;
	int perr = posix_memalign((void **)&q, CACHE_LINE_SIZE, sizeof(*q));
	if (perr != 0 || q == NULL) { return QERR_MALLOCERR; }

	/* Allocate message storage array (one extra unused element for fence) */
	q->msgs = NULL;
	perr = posix_memalign((void **)&q->msgs, CACHE_LINE_SIZE, (q_size + 1) * sizeof(q->msgs[0]) );
	if (perr != 0 || q->msgs == NULL) { free(q);  return QERR_MALLOCERR; }

	q->msgs[q_size].d = (void *)Q_FENCE;  /* used by q_delete to insure no overflow */

	q->batched_msgs = NULL;
	perr = posix_memalign((void **)&q->batched_msgs, CACHE_LINE_SIZE, q_size * sizeof(q->msgs[0]) );
	if (perr != 0 || q->batched_msgs == NULL) { free(q->msgs);  free(q);  return QERR_MALLOCERR; }

	q->enq_cnt = 0;  /* Init the queue counters */
	q->deq_cnt = 0;
	q->sav_enq_cnt = 0;  /* Init the queue counters */
	q->sav_deq_cnt = 0;
	q->batch_size = 0;

	q->size_mask = q_size - 1;  /* bit mask to "and" enq_cnt and deq_cnt to get tail and head */

	/* Success */
	*rtn_q = q;
	return QERR_OK;
}  /* q_create */


/* See q.h for doc */
qerr_t q_delete(q_t *q)
{
	/* Quick sanity check to make sure the queue didn't overflow */
	if (q->msgs[q->size_mask + 1].d != (void *)Q_FENCE) { return QERR_BUG1; }
	q->msgs[q->size_mask + 1].d = NULL;  /* remove fence to maybe detect double-delete */

	free((void *)q->batched_msgs);
	free((void *)q->msgs);
	free(q);

	return QERR_OK;
}  /* q_delete */


/* See q.h for doc */
qerr_t q_enq(q_t *q, void *m)
{
	unsigned int tail = (unsigned)(q->enq_cnt & q->size_mask);
	if (((q->enq_cnt - q->sav_deq_cnt) & q->size_mask) == q->size_mask) {
		q->sav_deq_cnt = (volatile unsigned int)(q->deq_cnt);  /* re-sample to see if some dequeues have happened since last sample */
		if (((q->enq_cnt - q->sav_deq_cnt) & q->size_mask) == q->size_mask) { return QERR_FULL; }
	}

	*((void * volatile *)&q->msgs[tail].d) = (void * volatile)m;
/*	q->msgs[tail].in_use = 1;*/
	q->enq_cnt++;
	return QERR_OK;
}  /* q_enq */


static inline qerr_t deq_from_batch(q_t *q, void **rtn_m)
{
	*(void volatile **)rtn_m = (void volatile *)q->batched_msgs[q->batch_i].d;
	q->batch_i ++;
	if (q->batch_i == q->batch_size) {
		q->batch_size = 0;
	}
	return QERR_OK;
}  /* deq_from_batch */

/* See q.h for doc */
qerr_t q_deq(q_t *q, void **rtn_m)
{
	if (q->batch_size > 0) {
		return deq_from_batch(q, rtn_m);
	}

	/* Nothing in the batch queue, check the real queue. */
	int q_depth = (q->sav_enq_cnt - q->deq_cnt) & q->size_mask;
	if (q_depth == 0) {
		q->sav_enq_cnt = (volatile unsigned int)(q->enq_cnt);  /* re-sample to see if some enqueues have happened since last sample */
		q_depth = (q->sav_enq_cnt - q->deq_cnt) & q->size_mask;
		if (q_depth == 0) { return QERR_EMPTY; }
	}
	unsigned int head = (unsigned)(q->deq_cnt & q->size_mask);

	/* Data in real queue.  See if it's worth moving to the batch queue */
	if (q_depth > q->size_mask - head) {
		/* elements are split across the end of the array; only look at the elements from head to end of array. */
		q_depth = q->size_mask - head + 1;
	}
	if (q_depth > 2) {
		/* load up the batch queue and dequeue from it. */
		memcpy(&q->batched_msgs[0], &q->msgs[head], q_depth*sizeof(q->batched_msgs[0]));
		q->batch_size = q_depth;
		q->batch_i = 0;
		q->deq_cnt += q_depth;

		return deq_from_batch(q, rtn_m);
	}

	/* Not enough to batch; dequeu direct from real queue */
	*(void volatile **)rtn_m = (void volatile *)q->msgs[head].d;
	q->deq_cnt++;
	return QERR_OK;
}  /* q_deq */


/* See q.h for doc */
int q_is_empty(q_t *q)
{
	return q->sav_enq_cnt == q->deq_cnt;
}  /* q_is_empty */


/* See q.h for doc */
int q_is_full(q_t *q)
{
	return ((q->enq_cnt - q->deq_cnt) & q->size_mask) == q->size_mask;
}  /* q_is_full */


/* If built with "-DSELFTEST" then include main() for unit testing. */
#ifdef SELFTEST
#include "q_selftest.c"
#endif
