#!/bin/sh

echo "q"
./q_perf | egrep summary
./q_perf | egrep summary
./q_perf | egrep summary
echo ""

echo "q1: single element per cacheline"
./q1_perf | egrep summary
./q1_perf | egrep summary
./q1_perf | egrep summary
echo ""

echo "q2: enq_cnt-deq_cnt"
./q2_perf | egrep summary
./q2_perf | egrep summary
./q2_perf | egrep summary
echo ""

echo "q3: single element per cacheline, enq_cnt-deq_cnt"
./q3_perf | egrep summary
./q3_perf | egrep summary
./q3_perf | egrep summary
echo ""

echo "q4: enq_cnt-deq_cnt, more elements per cache line (remove in_use)"
./q4_perf | egrep summary
./q4_perf | egrep summary
./q4_perf | egrep summary
echo ""

echo "q5: enq_cnt-deq_cnt, rcv batching, more elements per cache line (remove in_use)"
./q5_perf | egrep summary
./q5_perf | egrep summary
./q5_perf | egrep summary
echo ""
