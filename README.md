# q
Fast, lock-free, non-blocking queue

The q package is a C module which implements a fast, lock-free, non-blocking queue.

<!-- mdtoc-start -->
&bull; [q](#q)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Introduction](#introduction)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Quick Start](#quick-start)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [C API](#c-api)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Release Notes](#release-notes)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [License](#license)  
<!-- TOC created by '../mdtoc/mdtoc.pl README.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->

## Introduction

The q module implements a fast, lock-free, non-blocking queue.  Its characteristics are:

* Fixed size (size specified at queue creation time).
* Non-blocking (enqueuing to a full queue returns immediately with error; dequeuing from an empty queue returns immediately with error).
* Single Producer, Single Consumer (SPSC).
* No dynamic memory allocates or frees during enqueue and dequeue operations.  Messages are stored as void pointers; _null pointers are not allowed_.
* High performance.  On my Macbook Air, streaming data through a queue averages 11 ns per message (queue size=32), while ping-pong latency is 69 ns (one-way).
On a Linux server, the ping-pong latency was closer to 150 ns (one-way).
* Tested on Mac OSX 10.9 (Mavericks) and Linux 2.6 and 3.5 kernels.  At present, I only recommend the 64-bit x86 processor family, due to the fact that I take advantage of its programmer-friendly memory model.  In the future I hope to generalize it to be efficient on other processor types.

You can find q at:

* User documentation (this README): https://github.com/fordsfords/q/tree/gh-pages
* Semi-literate internal documentation: http://fordsfords.github.io/q/html/

## Quick Start

These instructions assume that you are running on Unix.  I have tried it on Linux, Solaris, FreeBSD, HP-UX, AIX, and Cygwin (on Windows 7).
Download the "q_0.2.tar" file.

1. Get the [github project](https://github.com/fordsfords/q/tree/gh-pages).

2. Build and test the package:

        ./bld.sh
        ./tst.sh

3. Run the performance tool:

        ./q_perf

## C API

Taken from q.h:

```
qerr_t q_create(q_t **rtn_q, unsigned int q_size);
/* Create an instance of a queue.
 * rtn_q  : Pointer to caller's queue instance handle.
 * q_size : Number of queue elements to allocate.  Must be > 1 and a power
 *          of 2.  Due to the nature of the algorithm used, a maximum of
 *          q_size - 1 elements can actually be stored in the queue.
 * Returns QERR_OK on success, or other QERR_* value on error. */

qerr_t q_delete(q_t *q);
/* Delete an instance of a queue.
 * q : Queue instance handle.
 * Returns QERR_OK on success, or other QERR_* value on error. */

qerr_t q_enq( q_t *q, void *m);
/* Add a message to the queue.
 * q : Queue instance handle.
 * m : Message to enqueue.
 * Returns QERR_OK on success, QERR_FULL if queue full, or other QERR_* value on error. */

qerr_t q_deq(q_t *q, void **rtn_m);
/* Remove a message from the queue.
 * q     : Queue instance handle.
 * rtn_m : Pointer to caller's message handle.
 * Returns QERR_OK on success, QERR_EMPTY if queue empty, or other QERR_* value on error. */

int q_is_empty(q_t *q);
/* Returns 1 if queue is empty (contains no messages), 0 otherwise.
 * q : Queue instance handle. */

int q_is_full(q_t *q);
/* Returns 1 if queue is full (contains q_size-1 message), 0 otherwise.
 * q : Queue instance handle. */

char *q_qerr_str(qerr_t qerr);
/* Returns a string representation of a queue API return error code.
 * qerr : value returned by most q APIs indicating success or faiure.
 * (See q.h for list of QERR_* definitions.) */
```

## Release Notes

* 0.1 (19-May-2014)

    Initial pre-release.

* 0.2 (1-Jun-2014)

    API CHANGE: changed terminology "status' to "error".  Specifically, changed:

    * "qstat_t" to "qerr_t"
    * "QSTAT_..." to "QERR_..."
    * "q_qstat_str" to "q_qerr_str"

    Added "in_use" flag as part of each message slot.  This allows null messages to be enqueued and dequeued.

    Added directory "alternates" containing variations on the queue algorithm.
Minor corrections in q_selftest.c.

* 0.3 (11-May-2015)

    Moved to Github.

* 0.4 (19-Jul-2016)

    Added extern "C" {} to simplify usage by C++.  Thanks to [Deep
    Grant](https://github.com/deepgrant) for the patch!

## License

I want there to be NO barriers to using this code, so I am releasing it to the public domain.  But "public domain" does not have an internationally agreed upon definition, so I use CC0:

This work is dedicated to the public domain under CC0 1.0 Universal:
http://creativecommons.org/publicdomain/zero/1.0/

To the extent possible under law, Steven Ford has waived all copyright
and related or neighboring rights to this work. In other words, you can 
use this code for any purpose without any restrictions.
This work is published from: United States.
Project home: https://github.com/fordsfords/q
