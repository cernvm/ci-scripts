#!/bin/bash
# Do Coverity code check and commit checker results.
# Run from /foot/bar if you want sources /foo/bar/whatever to be displayed as /whatever

set -e
set -x

[ -f "$COV_ANALYSIS"          ]    || exit 1
[ -f "$COV_COMMIT"            ]    || exit 2
[ "x$COV_STREAM" != x         ]    || exit 3
[ "x$COV_SERVER" != x         ]    || exit 4
[ "x$COV_SERVER_PORT" != x    ]    || exit 5
[ "x$COV_SERVER_USER" != x    ]    || exit 6

if [ "x$1" = "x" ]; then
    echo ERROR: temp dir not given.
    exit 7
fi
TMPDIR=$1
TMPP=$TMPDIR/parallel_c/

if ! [ -d "$TMPDIR" ]; then
    echo ERROR: temp dir $TMPDIR not a directory.
    exit 8
fi

function log() {
    echo "$@"
    echo `date +"%F %T"`: "$@" >> $TMPP/log.txt
}

log "STREAM: $COV_STREAM"

if [ "x$2" = "x--worker" ]; then

    iproc=$3
    OUT=$TMPP/${iproc}.out
    shift
    shift
    shift
    # win stack is 1M; use 256K=262144 bytes as limit
    OPTS="--enable-single-virtual --enable-constraint-fpp"
    OPTS="$OPTS --checker-option CONSTANT_EXPRESSION_RESULT:report_bit_and_with_zero:true --checker-option CONSTANT_EXPRESSION_RESULT:report_constant_logical_operands:true"

    OUTDIR="--outputdir $TMPP/$iproc"
    if [ $iproc = 1 ]; then
        OUTDIR=""
    fi
    echo "Started nice $COV_ANALYSIS --disable-default --dir $TMPDIR  $@ $OPTS $OUTDIR" > $OUT
    nice $COV_ANALYSIS --disable-default --dir $TMPDIR  "$@" $OPTS $OUTDIR >> $OUT 2>&1
    cat $OUT
    rm -f $OUT

else

    mkdir -p $TMPP
    rm -f $TMPP/*.out
    rm -f $TMPP/log.txt
    CHK=(`$COV_ANALYSIS --list-checkers | grep -v 'Available ' | grep -v symbian | grep -v -E '^COM\.' | grep -v -E '^MISRA_COV_ANALYSISST ' | grep -v -E '^USER_POINTER '  | grep -v -E '^INTEGER_OVERFLOW ' | grep -v -E '^STACK_USE ' | sed 's, (.*$,,'`)

    log "${#CHK[*]} AVAILABLE CHECKERS: ${CHK[*]}"

    let RAM=`free -g | grep ^Mem | sed 's,^[^[:digit:]]*\([[:digit:]]\+\).*$,\1,'`/2
    let CPUS=`grep ^processor  /proc/cpuinfo |wc -l`
    if [ $RAM -lt $CPUS ]; then
        let $CPUS=$RAM
    fi
    let CPUS=$CPUS/2
    log "Running with $CPUS parallel processes."

    let iproc=0
    for chk in ${CHK[*]}; do
        PROCCHK[$iproc]="${PROCCHK[$iproc]} --enable $chk"
        let iproc=$iproc+1
        if [ $iproc -ge $CPUS ]; then
            iproc=0
        fi
    done

    EXTRADIRS=""
    let iproc=0
    while [ $iproc -lt $CPUS ]; do
        EXTRAOPTS=""
        CHKS=${PROCCHK[$iproc]}
        let iproc=$iproc+1
        if [ $iproc -eq 1 ]; then
            EXTRAOPTS="--enable-callgraph-metrics --enable-parse-warnings"
        elif [ $iproc -gt 1 ]; then
            EXTRADIRS="$EXTRADIRS --extra-output $TMPP/$iproc"
        fi
        log "starting process $iproc/$CPUS: $0 $TMPDIR --worker $iproc $CHKS $EXTRAOPTS"
        $0 $TMPDIR --worker $iproc $CHKS $EXTRAOPTS >> $TMPP/log.txt &
        sleep 1
        while [ `ls $TMPP/*.out 2> /dev/null | wc -l` -ge $CPUS ]; do
            sleep 10
        done
    done

    while ls $TMPP/*.out > /dev/null 2>&1; do
        sleep 10
    done

    log "all checkers done"
    log "Running $COV_COMMIT --user admin --password XYZ --stream $COV_STREAM --strip-path $PWD/  --dir $TMPDIR $EXTRADIRS"
    $COV_COMMIT --host $COV_SERVER --port $COV_SERVER_PORT --user $COV_SERVER_USER --stream $COV_STREAM --strip-path $PWD/  --dir $TMPDIR $EXTRADIRS >> $TMPP/log.txt 2>&1
    log Done.
fi
