#!/bin/sh

if [ ! -f $PWD/qa/gdnsd.supp ]; then
   echo "Run this from the root of the source tree!"
   exit 99
fi

if [ ! -f $PWD/configure ]; then
   echo "Run autoreconf -vi first!"
   exit 99
fi

set -x
set -e

TEST_CPUS=`getconf _NPROCESSORS_ONLN`
export TEST_CPUS

case "$GDNSD_TRAVIS_BUILD" in
    optimized)
        CFLAGS=-O3 ./configure
        SLOW_TESTS=1 make -j$TEST_CPUS check
    ;;
    developer)
        ./configure --enable-developer
        SLOW_TESTS=1 make -j$TEST_CPUS check
    ;;
    sonarcloud)
        CFLAGS="-O0 -g -fprofile-arcs -ftest-coverage" CPPFLAGS="-DGDNSD_NO_UNREACH_BUILTIN -DGDNSD_NO_FATAL_COVERAGE -DGDNSD_COVERTEST_EXIT" ./configure --without-hardening
        SLOW_TESTS=1 make -j$TEST_CPUS check
        gcov -a -c -p src/*.o src/plugins/*.o libgdmaps/*.o libgdnsd/*.o
        make clean
        ./configure --disable-developer --without-hardening
        build-wrapper-linux-x86-64 --out-dir bw-output make -j$TEST_CPUS
        sonar-scanner -Dsonar.cfamily.threads=$TEST_CPUS -Dsonar.projectVersion=`git describe`
    ;;
    *)
        echo "Invalid GDNSD_TRAVIS_BUILD: $GDNSD_TRAVIS_BUILD"
        exit 99
    ;;
esac
