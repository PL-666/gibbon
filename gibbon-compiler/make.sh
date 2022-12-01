#!/bin/sh

# debug_flags="-D_GIBBON_GCSTATS -D_GIBBON_VERBOSITY=3 -D_GIBBON_DEBUG -DNURSERY_SIZE=1024000 -O0"
# rust_rts="$GIBBONDIR/gibbon-rts/target/debug"

# debug_flags="-D_GIBBON_VERBOSITY=1 -DNURSERY_SIZE=4096000 -O3 -fno-omit-frame-pointer"
debug_flags="-D_GIBBON_VERBOSITY=1 -DNURSERY_SIZE=4096000 -O3"
rust_rts="$GIBBONDIR/gibbon-rts/target/release"

gcc -std=gnu11  -fcilkplus -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 $debug_flags  -flto -I $GIBBONDIR/gibbon-compiler/cbits  -L$GIBBONDIR/gibbon-rts/target/debug -Wl,-rpath=$GIBBONDIR/gibbon-rts/target/debug -c $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.c -o $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o  -lm -lgibbon_rts && gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 -g $debug_flags  -flto     $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o -I$GIBBONDIR/gibbon-compiler/cbits  -L$GIBBONDIR/gibbon-rts/target/debug    -Wl,-rpath=$GIBBONDIR/gibbon-rts/target/debug $GIBBONDIR/gibbon-compiler/examples/gc/bench_new_rts.c    -o $GIBBONDIR/gibbon-compiler/examples/gc/bench_new_rts.exe -lm -lgibbon_rts

# gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 $debug_flags  -flto -I $GIBBONDIR/gibbon-compiler/cbits  -L$GIBBONDIR/gibbon-rts/target/debug -Wl,-rpath=$GIBBONDIR/gibbon-rts/target/debug -c $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.c -o $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o  -lm -lgibbon_rts && gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 -g  -flto  $debug_flags   $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o -I$GIBBONDIR/gibbon-compiler/cbits  -L$GIBBONDIR/gibbon-rts/target/debug    -Wl,-rpath=$GIBBONDIR/gibbon-rts/target/debug $GIBBONDIR/gibbon-compiler/examples/gc/test_tree_update.c    -o $GIBBONDIR/gibbon-compiler/examples/gc/test_tree_update.exe -lm -lgibbon_rts


# gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 $debug_flags  -flto -I $GIBBONDIR/gibbon-compiler/cbits  -L$GIBBONDIR/gibbon-rts/target/debug -Wl,-rpath=$GIBBONDIR/gibbon-rts/target/debug -c $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.c -o $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o  -lm -lgibbon_rts && gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 -g  -flto  $debug_flags   $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o -I$GIBBONDIR/gibbon-compiler/cbits  -L$GIBBONDIR/gibbon-rts/target/debug    -Wl,-rpath=$GIBBONDIR/gibbon-rts/target/debug $GIBBONDIR/gibbon-compiler/examples/gc/tree_update2.c    -o $GIBBONDIR/gibbon-compiler/examples/gc/tree_update2.exe -lm -lgibbon_rts


# gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 $debug_flags  -flto -I $GIBBONDIR/gibbon-compiler/cbits  -L$GIBBONDIR/gibbon-rts/target/debug -Wl,-rpath=$GIBBONDIR/gibbon-rts/target/debug -c $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.c -o $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o  -lm -lgibbon_rts && gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 -g  -flto  $debug_flags   $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o -I$GIBBONDIR/gibbon-compiler/cbits  -L$GIBBONDIR/gibbon-rts/target/debug    -Wl,-rpath=$GIBBONDIR/gibbon-rts/target/debug $GIBBONDIR/gibbon-compiler/examples/gc/tree_update3.c    -o $GIBBONDIR/gibbon-compiler/examples/gc/tree_update3.exe -lm -lgibbon_rts

# gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 $debug_flags  -flto -I $GIBBONDIR/gibbon-compiler/cbits  -L$GIBBONDIR/gibbon-rts/target/debug -Wl,-rpath=$GIBBONDIR/gibbon-rts/target/debug -c $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.c -o $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o  -lm -lgibbon_rts && gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 -g  -flto  $debug_flags   $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o -I$GIBBONDIR/gibbon-compiler/cbits  -L$GIBBONDIR/gibbon-rts/target/debug    -Wl,-rpath=$GIBBONDIR/gibbon-rts/target/debug $GIBBONDIR/gibbon-compiler/examples/gc/tree_update4.c    -o $GIBBONDIR/gibbon-compiler/examples/gc/tree_update4.exe -lm -lgibbon_rts

# gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 $debug_flags  -flto -I $GIBBONDIR/gibbon-compiler/cbits  -L$GIBBONDIR/gibbon-rts/target/debug -Wl,-rpath=$GIBBONDIR/gibbon-rts/target/debug -c $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.c -o $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o  -lm -lgibbon_rts && gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 -g  -flto  $debug_flags   $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o -I$GIBBONDIR/gibbon-compiler/cbits  -L$GIBBONDIR/gibbon-rts/target/debug    -Wl,-rpath=$GIBBONDIR/gibbon-rts/target/debug $GIBBONDIR/gibbon-compiler/examples/gc/tree_update5.c    -o $GIBBONDIR/gibbon-compiler/examples/gc/tree_update5.exe -lm -lgibbon_rts

# gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 $debug_flags  -flto -I $GIBBONDIR/gibbon-compiler/cbits  -L$rust_rts -Wl,-rpath=$rust_rts -c $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.c -o $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o  -lm -lgibbon_rts && gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 -g  -flto  $debug_flags   $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o -I$GIBBONDIR/gibbon-compiler/cbits  -L$rust_rts    -Wl,-rpath=$rust_rts $GIBBONDIR/gibbon-compiler/examples/gc/tree_update6.c    -o $GIBBONDIR/gibbon-compiler/examples/gc/tree_update6.exe -lm -lgibbon_rts


# gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 $debug_flags  -flto -I $GIBBONDIR/gibbon-compiler/cbits  -L$rust_rts -Wl,-rpath=$rust_rts -c $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.c -o $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o  -lm -lgibbon_rts && gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 -g  -flto  $debug_flags   $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o -I$GIBBONDIR/gibbon-compiler/cbits  -L$rust_rts    -Wl,-rpath=$rust_rts $GIBBONDIR/gibbon-compiler/examples/gc/tree_update7.c    -o $GIBBONDIR/gibbon-compiler/examples/gc/tree_update7.exe -lm -lgibbon_rts


# gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 $debug_flags  -flto -I $GIBBONDIR/gibbon-compiler/cbits  -L$rust_rts -Wl,-rpath,$rust_rts -c $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.c -o $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o  -lm -lgibbon_rts && gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 -g  -flto  $debug_flags   $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o -I$GIBBONDIR/gibbon-compiler/cbits  -L$rust_rts    -Wl,-rpath,$rust_rts $GIBBONDIR/gibbon-compiler/examples/gc/tree_update8.c    -o $GIBBONDIR/gibbon-compiler/examples/gc/tree_update8.exe -lm -lgibbon_rts

gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 $debug_flags  -flto -I $GIBBONDIR/gibbon-compiler/cbits  -L$rust_rts -Wl,-rpath,$rust_rts -c $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.c -o $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o  -lm -lgibbon_rts && gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 -g  -flto  $debug_flags   $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o -I$GIBBONDIR/gibbon-compiler/cbits  -L$rust_rts    -Wl,-rpath,$rust_rts $GIBBONDIR/gibbon-compiler/examples/gc/tree_update9.c    -o $GIBBONDIR/gibbon-compiler/examples/gc/tree_update9.exe -lm -lgibbon_rts

gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 $debug_flags  -flto -I $GIBBONDIR/gibbon-compiler/cbits  -L$rust_rts -Wl,-rpath,$rust_rts -c $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.c -o $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o  -lm -lgibbon_rts && gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 -g  -flto  $debug_flags   $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o -I$GIBBONDIR/gibbon-compiler/cbits  -L$rust_rts    -Wl,-rpath,$rust_rts $GIBBONDIR/gibbon-compiler/examples/gc/tree_update10.c    -o $GIBBONDIR/gibbon-compiler/examples/gc/tree_update10.exe -lm -lgibbon_rts

################################################################################

gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 $debug_flags  -flto -I $GIBBONDIR/gibbon-compiler/cbits  -L$rust_rts -Wl,-rpath,$rust_rts -c $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.c -o $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o  -lm -lgibbon_rts && gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 -g  -flto  $debug_flags   $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o -I$GIBBONDIR/gibbon-compiler/cbits  -L$rust_rts    -Wl,-rpath,$rust_rts $GIBBONDIR/gibbon-compiler/examples/gc/reverse.c    -o $GIBBONDIR/gibbon-compiler/examples/gc/reverse.exe -lm -lgibbon_rts


################################################################################

gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 $debug_flags  -flto -I $GIBBONDIR/gibbon-compiler/cbits  -L$rust_rts -Wl,-rpath,$rust_rts -c $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.c -o $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o  -lm -lgibbon_rts && gcc -std=gnu11  -fcilkplus  -Wno-unused-variable -Wno-unused-label -Wall -Wextra -Wpedantic  -O3 -g  -flto  $debug_flags   $GIBBONDIR/gibbon-compiler/cbits/gibbon_rts.o -I$GIBBONDIR/gibbon-compiler/cbits  -L$rust_rts    -Wl,-rpath,$rust_rts $GIBBONDIR/gibbon-compiler/examples/parallel/Benchrunner.c    -o $GIBBONDIR/gibbon-compiler/examples/parallel/Benchrunner.exe -lm -lgibbon_rts
