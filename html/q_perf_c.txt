/* q_perf.c - This tool measures performance of q.c  See http://geeky-boy.com/q/ */
/*
# This code and its documentation is Copyright 2014 Steven Ford, sford@geeky-boy.com
# and licensed under Creative Commons "CC0": http://creativecommons.org/publicdomain/zero/1.0/
# To the extent possible under law, Steve Ford has waived all copyright and related or
# neighboring rights to this work.  This work is published from: United States.
*/

#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <string.h>
#include <errno.h>
#include <sys/time.h>
#include <stdio.h>
#include "q.h"

/* some platforms require the program to declare these external */
extern char *optarg;
extern int optind;
extern int optopt;
extern int opterr;
extern int optreset;

#define UINT unsigned int
#define V2I (unsigned long long)(void *)
#define I2V (void *)(unsigned long long)

#define CHK_QERR_E(s,e) do { if (s != e) { printf("ERROR %s[%d]: qerr=%u\n", __FILE__, __LINE__, s);  exit(1); } } while (0)
#define CHK_QERR(s) do { if (s != QERR_OK) { printf("ERROR %s[%d]: %d (%s)\n", __FILE__, __LINE__, s, q_qerr_str(s)); exit(1); } } while (0)
#define CHK_PTHREAD_ERR(s) do { if (s != 0) { printf("ERROR %s[%d]: %d (%s)\n", __FILE__, __LINE__, s, strerror(s)); exit(1); } } while (0)
#define ERR(s) do { printf("ERROR %s[%d]: %s\n", __FILE__, __LINE__, s); exit(1); } while (0)

struct tst_s {
	UINT enq_cnt;
	UINT full_cnt;
	UINT full_spans;
	UINT max_full_span;
	char padding1[CACHE_LINE_SIZE - 4*sizeof(UINT)];
	UINT deq_cnt;
	UINT empty_cnt;
	UINT empty_spans;
	UINT max_empty_span;
	char padding2[CACHE_LINE_SIZE - 4*sizeof(UINT)];
	q_t *q1;
	q_t *q2;
	UINT loops;
};
typedef struct tst_s tst_t;


/* globals for testing */
struct timeval tmp_tv;
UINT phase1_start;
UINT phase1_end;
UINT phase2_start;
UINT phase2_end;


void *enq_thread(void *in_arg)
{
	tst_t *test_data = (tst_t *)in_arg;
	q_t *q = test_data->q1;
	UINT full_span = 0;
	UINT enq_cnt = 0;
	UINT full_cnt = 0;
	UINT full_spans = 0;
	UINT max_full_span = 0;

	unsigned int msg_num = test_data->loops;
	while (msg_num > 0) {
		qerr_t qerr = q_enq(q, I2V msg_num);
		if (qerr == QERR_OK) {
			/* prepare next message contents */
			msg_num--;

			/* collect stats */
			enq_cnt++;
			if (full_span > max_full_span) {
				max_full_span = full_span; }
			full_span = 0;
		} else if (qerr == QERR_FULL) {
			/* queue empty, collect stats */
			full_cnt++;
			if (full_span == 0) {
				full_spans++; }
			full_span++;
		} else CHK_QERR(qerr);
	}  /* while */

	gettimeofday(&tmp_tv, NULL);  phase1_end = 1000000llu * (UINT)tmp_tv.tv_sec + (UINT)tmp_tv.tv_usec;

	test_data->enq_cnt = enq_cnt;
	test_data->full_cnt = full_cnt;
	test_data->full_spans = full_spans;
	test_data->max_full_span = max_full_span;

	pthread_exit(NULL);
	return NULL;  /* don't need this, but keep the compiler happy */
}  /* enq_thread */


void *deq_thread(void *in_arg)
{
	tst_t *test_data = (tst_t *)in_arg;
	q_t *q = test_data->q1;
	unsigned int loops = test_data->loops;
	UINT deq_cnt = 0;
	UINT empty_cnt = 0;
	UINT empty_spans = 0;
	UINT max_empty_span = 0;
	UINT cur_span = 0;

	unsigned int msg_num = loops;
	while (msg_num > 0) {
		void *rtn_m;
		qerr_t qerr = q_deq(q, &rtn_m);
		if (qerr == QERR_OK) {
			/* prepare for next message */
			msg_num--;

			/* collect stats */
			if ((unsigned int)rtn_m == loops) {  /* first message, ignore initial spins */
				/* first message, start timing */
				gettimeofday(&tmp_tv, NULL);  phase1_start = 1000000llu * (UINT)tmp_tv.tv_sec + (UINT)tmp_tv.tv_usec;
				empty_cnt = 0;  cur_span = 0;  empty_spans = 0;
			}
			deq_cnt++;
			if (cur_span > max_empty_span) {
				max_empty_span = cur_span; }
			cur_span = 0;
		} else if (qerr == QERR_EMPTY) {
			/* queue empty, collect stats */
			empty_cnt++;
			if (cur_span == 0) {
				empty_spans++; }
			cur_span++;
		} else CHK_QERR(qerr);
	}  /* while */

	test_data->deq_cnt = deq_cnt;
	test_data->empty_cnt = empty_cnt;
	test_data->empty_spans = empty_spans;
	test_data->max_empty_span = max_empty_span;

	pthread_exit(NULL);
	return NULL;  /* don't need this, but keep the compiler happy */
}  /* deq_thread */


void *ping_thread(void *in_arg)
{
	tst_t *test_data = (tst_t *)in_arg;
	q_t *q1 = test_data->q1;
	q_t *q2 = test_data->q2;
	unsigned int loops = test_data->loops;

	unsigned int msg_num = loops;
	while (msg_num > 0) {
		void *rtn_m;
		qerr_t qerr;
		do {
			qerr = q_deq(q1, &rtn_m);
		} while (qerr == QERR_EMPTY);
		CHK_QERR(qerr);

		/* prepare next message contents */
		msg_num--;

		/* bounce the message back */
		if (msg_num > 0) {
			qerr_t qerr = q_enq(q2, I2V msg_num);  CHK_QERR(qerr);
			/* prepare for next message */
			msg_num--;
		}
	}  /* while */

	gettimeofday(&tmp_tv, NULL);  phase2_end = 1000000llu * (UINT)tmp_tv.tv_sec + (UINT)tmp_tv.tv_usec;

	pthread_exit(NULL);
	return NULL;  /* don't need this, but keep the compiler happy */
}  /* ping_thead */


void *pong_thread(void *in_arg)
{
	tst_t *test_data = (tst_t *)in_arg;
	q_t *q1 = test_data->q1;
	q_t *q2 = test_data->q2;
	unsigned int loops = test_data->loops;

	gettimeofday(&tmp_tv, NULL);  phase2_start = 1000000llu * (UINT)tmp_tv.tv_sec + (UINT)tmp_tv.tv_usec;

	unsigned int msg_num = loops;
	msg_num--;  /* pong gets second message */
	while (msg_num > 0) {
		void *rtn_m;
		qerr_t qerr;
		do {
			qerr = q_deq(q2, &rtn_m);
		} while (qerr == QERR_EMPTY);
		CHK_QERR(qerr);

		/* prepare next message contents */
		msg_num--;

		/* bounce the message back */
		if (msg_num > 0) {
			qerr_t qerr = q_enq(q1, I2V msg_num);  CHK_QERR(qerr);
			/* prepare for next message */
			msg_num--;
		}
	}  /* while */

	pthread_exit(NULL);
	return NULL;  /* don't need this, but keep the compiler happy */
}  /* pong_thead */


/* Handle options */
struct opt_s {
	int loops;  /* number of loops for streaming test */
	int depth;  /* queue depth for streaming test */
	int LOOPS;  /* number of loops for ping-pong test */
	int DEPTH;  /* queue depth for ping-pong test */
	int pings;  /* number of ping messages in flight */
};
typedef struct opt_s opt_t;

void opts_set_def(opt_t *opts)
{
	opts->loops = 500000000;
	opts->depth = 4096;
	opts->LOOPS = 50000000;
	opts->DEPTH = 2;
	opts->pings = 1;
}  /* opts_set_def */

char usage_str[] = "Usage: q_perf [-l loops] [-d depth] [-L LOOPS] [-D DEPTH] [-p pings]\n"
	"Where:\n"
	"    -l loops - number of times to loop the streaming test [%ld]\n"
	"    -d depth - queue depth to use for streaming test [%ld] (must be power of 2)\n"
	"    -L LOOPS - number of times to loop the ping-pong test [%ld]\n"
	"    -D DEPTH - queue depth to use for ping-pong test [%ld] (must be power of 2)\n"
	"    -p pings - number of ping messages in flight [%ld] (must be < DEPTH)\n";

void usage(opt_t *opts, char *m)
{
	opts_set_def(opts);  /* (re)set options to defaults so that we print the right values in the help */

	if (m == NULL || m[0] == '\0') {
		fprintf(stderr, usage_str, opts->loops, opts->depth, opts->LOOPS, opts->DEPTH, opts->pings);
		exit(0);
	} else {
		fprintf(stderr, "%s\n", m);
		fprintf(stderr, usage_str, opts->loops, opts->depth, opts->LOOPS, opts->DEPTH, opts->pings);
		exit(1);
	}
}  /* usage */

void get_options(opt_t *opts, int argc, char **argv)
{
	opts_set_def(opts);  /* set options to defaults */

	int o;  char *p;
	while ((o = getopt(argc, argv, "l:d:L:D:p:")) > 0) {
		switch (o) {
		case 'l':
			p = NULL;  errno = 0;
			opts->loops = strtol(optarg, &p, 10);
			if (errno != 0 || p == optarg || p == NULL || *p != '\0')
				usage(opts, "Invalid numeric value for -l option");
			break;
		case 'd':
			p = NULL;  errno = 0;
			opts->depth = strtol(optarg, &p, 10);
			if (errno != 0 || p == optarg || p == NULL || *p != '\0')
				usage(opts, "Invalid numeric value for -d option");
			break;
		case 'L':
			p = NULL;  errno = 0;
			opts->LOOPS = strtol(optarg, &p, 10);
			if (errno != 0 || p == optarg || p == NULL || *p != '\0')
				usage(opts, "Invalid numeric value for -L option");
			break;
		case 'D':
			p = NULL;  errno = 0;
			opts->DEPTH = strtol(optarg, &p, 10);
			if (errno != 0 || p == optarg || p == NULL || *p != '\0')
				usage(opts, "Invalid numeric value for -D option");
			break;
		case 'p':
			p = NULL;  errno = 0;
			opts->pings = strtol(optarg, &p, 10);
			if (errno != 0 || p == optarg || p == NULL || *p != '\0')
				usage(opts, "Invalid numeric value for -p option");
			break;
		default:
			usage(opts, NULL);
		}  /* switch o */
	}  /* while getopt */

	if (opts->pings >= opts->DEPTH) { usage(opts, "ERROR pings (-p) >= DEPTH (-D)\n"); }
}  /* get_options */


int main(int argc, char **argv)
{
	opt_t opts;
	qerr_t qerr;

	get_options(&opts, argc, argv);

	tst_t test_data;  /* shared with test threads */
	memset(&test_data, 0, sizeof(test_data));

	qerr = q_create(&test_data.q1, opts.depth);  CHK_QERR(qerr);
	test_data.loops = opts.loops;
	int perr;

	pthread_attr_t deq_attr;  pthread_attr_init(&deq_attr);  pthread_attr_setdetachstate(&deq_attr, PTHREAD_CREATE_JOINABLE);
	pthread_t deq_t_handle;
	perr = pthread_create(&deq_t_handle, &deq_attr, deq_thread, &test_data);  CHK_PTHREAD_ERR(perr);
	pthread_attr_destroy(&deq_attr);

	pthread_attr_t enq_attr;  pthread_attr_init(&enq_attr);  pthread_attr_setdetachstate(&enq_attr, PTHREAD_CREATE_JOINABLE);
	pthread_t enq_t_handle;
	perr = pthread_create(&enq_t_handle, &enq_attr, enq_thread, &test_data);  CHK_PTHREAD_ERR(perr);
	pthread_attr_destroy(&enq_attr);

	/* wait for threads to complete. */
	perr = pthread_join(deq_t_handle, NULL);  CHK_PTHREAD_ERR(perr);  /* wait for deq first */
	perr = pthread_join(enq_t_handle, NULL);  CHK_PTHREAD_ERR(perr);

	qerr = q_delete(test_data.q1);  CHK_QERR(qerr);

	printf("FYI loops=%u, full_cnt=%u, empty_cnt=%u\n", test_data.loops, test_data.full_cnt, test_data.empty_cnt);
	printf("FYI     full_spans=%u, empty_spans=%u\n", test_data.full_spans, test_data.empty_spans);
	printf("FYI     max_full_span=%u, max_empty_span=%u\n", test_data.max_full_span, test_data.max_empty_span);
	double duration = (double)(phase1_end - phase1_start);
	double usec_per = duration / (double)test_data.loops;
	double stream_ns_per = usec_per*1000.0;
	printf("FYI     duration=%f sec (%f ns/msg)\n", duration/1000000.0, stream_ns_per);
	fflush(stdout);


	/* Phase 2: ping-pong test */

	memset(&test_data, 0, sizeof(test_data));

	qerr = q_create(&test_data.q1, opts.DEPTH);  CHK_QERR(qerr);
	qerr = q_create(&test_data.q2, opts.DEPTH);  CHK_QERR(qerr);
	test_data.loops = opts.LOOPS;

	/* put one or more messages in the queue to be bounced back and forth */
	int i;
	for (i = 0; i < opts.pings; i++) {
		qerr = q_enq(test_data.q1, I2V test_data.loops);  CHK_QERR(qerr);
	}

	pthread_attr_t ping_attr;  pthread_attr_init(&ping_attr);  pthread_attr_setdetachstate(&ping_attr, PTHREAD_CREATE_JOINABLE);
	pthread_t ping_t_handle;
	perr = pthread_create(&ping_t_handle, &ping_attr, ping_thread, &test_data);  CHK_PTHREAD_ERR(perr);
	pthread_attr_destroy(&ping_attr);

	pthread_attr_t pong_attr;  pthread_attr_init(&pong_attr);  pthread_attr_setdetachstate(&pong_attr, PTHREAD_CREATE_JOINABLE);
	pthread_t pong_t_handle;
	perr = pthread_create(&pong_t_handle, &pong_attr, pong_thread, &test_data);  CHK_PTHREAD_ERR(perr);
	pthread_attr_destroy(&pong_attr);

	/* wait for threads to complete. */
	perr = pthread_join(pong_t_handle, NULL);  CHK_PTHREAD_ERR(perr);  /* wait for pong first */
	perr = pthread_join(ping_t_handle, NULL);  CHK_PTHREAD_ERR(perr);

	duration = phase2_end - phase2_start;
	usec_per = duration / (double)test_data.loops;
	double pp_ns_per = usec_per*1000.0;
	printf("FYI ping/pong: msgs=%u, duration=%f sec (%f ns/msg one-way)\n", test_data.loops, duration/1000000.0, pp_ns_per);

	printf("FYI summary: stream: %f   pp: %f\n", stream_ns_per, pp_ns_per);
	fflush(stdout);

	qerr = q_delete(test_data.q1);  CHK_QERR(qerr);
	qerr = q_delete(test_data.q2);  CHK_QERR(qerr);
}  /* main */
