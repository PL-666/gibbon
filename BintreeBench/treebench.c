// A regular, pointer-based C implementation.

// This uses heap-allocation for the trees, just like the other
// benchmarks.

#include <stdio.h>
#include <stdlib.h>
#ifdef PARALLEL
#include <cilk/cilk.h>
#endif
#include <time.h>

// Manual layout:
// one byte for each tag, 64 bit integers
typedef long long Num;

enum __attribute__((__packed__)) Type { Leaf, Node };

// struct Tree;

typedef struct __attribute__((__packed__)) Tree {
    enum Type tag;
    union {
      struct { long long elem; };
      struct { struct Tree* l;
               struct Tree* r; };
    };
} Tree;

// Memory management
//--------------------------------------------------------------------------------

void deleteTree(Tree* t) {
  if (t->tag == Node) {
    deleteTree(t->l);
    deleteTree(t->r);
  }
  free(t);
}

#ifdef BUMPALLOC
#warning "Using bump allocator."
char* heap_ptr = 0;
// For simplicity just use a single large slab:
#define INITALLOC heap_ptr = malloc(500 * 1000 * 1000);
#define ALLOC(n) (heap_ptr += n)
// HACK, delete by rewinding:
#define DELTREE(p) { heap_ptr = (char*)p; }
#else
#define INITALLOC {}
#define ALLOC malloc
#define DELTREE deleteTree
#endif

//--------------------------------------------------------------------------------


// Helper function
Tree* fillTree(int n, Num root) {
  Tree* tr = (Tree*)ALLOC(sizeof(Tree));  
  if (n == 0) {
    tr->tag = Leaf;
    tr->elem = root;
  } else {    
    tr->tag = Node;
    tr->l = fillTree(n-1, root);; 
    tr->r = fillTree(n-1, root + (1<<(n-1)));
  }
  return tr;  
}

Tree* buildTree(int n) {
  return fillTree(n, 1);
}

void printTree(Tree* t) {
  if (t->tag == Leaf) {
    printf("%lld", t->elem);
    return;
  } else {
    printf("(");
    printTree(t->l);
    printf(",");
    printTree(t->r);
    printf(")");
    return;
  }
}

// Out-of-place add1 to leaves.
Tree* add1Tree(Tree* t) {
  Tree* tout = (Tree*)ALLOC(sizeof(Tree));
  tout->tag = t->tag;
  if (t->tag == Leaf) {
    tout->elem = t->elem + 1;
  } else {
    tout->l = add1Tree(t->l);
    tout->r = add1Tree(t->r);
  }
  return tout;
}

#ifdef PARALLEL
Tree* add1TreePar(Tree* t, int n) {
  if (n == 0) return add1Tree(t);
  
  Tree* tout = (Tree*)ALLOC(sizeof(Tree));
  tout->tag = t->tag;
  if (t->tag == Leaf) {
    tout->elem = t->elem + 1;
  } else {
    tout->l = cilk_spawn add1TreePar(t->l, n-1);
    tout->r = add1TreePar(t->r, n-1);
  }
  cilk_sync;
  return tout;
}
#endif

int compare_doubles (const void *a, const void *b)
{
  const double *da = (const double *) a;
  const double *db = (const double *) b;
  return (*da > *db) - (*da < *db);
}

double avg(const double* arr, int n) {
  double sum = 0.0;
  for(int i=0; i<n; i++) sum += arr[i];
  return sum / (double)n;
}

double difftimespecs(struct timespec* t0, struct timespec* t1) {
  return (double)(t1->tv_sec - t0->tv_sec)
    + ((double)(t1->tv_nsec - t0->tv_nsec) / 1000000000.0);
}

static clockid_t which_clock = CLOCK_MONOTONIC_RAW;

int main(int argc, char** argv) {
  int depth, iters;
  if (argc > 2) {
    depth = atoi(argv[1]);
    iters = atoi(argv[2]);
  } else {
    fprintf(stderr,"Expected two arguments, <depth> <iters>\n");
    fprintf(stderr,"Iters can be negative to time each iteration rather than all together\n");
    abort();
  }
  
  printf("sizeof(Tree) = %d\n", sizeof(Tree));
  printf("sizeof(enum Type) = %d\n", sizeof(enum Type));
  printf("Building tree, depth %d.  Benchmarking %d iters.\n", depth, iters);

  INITALLOC;
  struct timespec begin, end;
  clock_gettime(which_clock, &begin);
  Tree* tr = buildTree(depth);
  clock_gettime(which_clock, &end);
  double time_spent = difftimespecs(&begin, &end);
  printf("Done building input tree, took %lf seconds\n\n", time_spent);
  if (depth <= 5) {
    printf("Input tree:\n");
    printTree(tr); printf("\n");
  }
  printf("Running traversals (ms): ");

  long allocated_bytes =0;
  if ( iters < 0 ) {
    iters = -iters;
    double trials[iters];
    for(int i=0; i<iters; i++) {
      clock_gettime(which_clock, &begin);
#ifdef PARALLEL
      Tree* t2 = add1TreePar(tr, 5);
#else      
      Tree* t2 = add1Tree(tr);
#endif      
      clock_gettime(which_clock, &end);
      time_spent = difftimespecs(&begin, &end);
      if(iters < 100) {
        printf(" %lld", (long long)(time_spent * 1000));
        fflush(stdout);
      }
      trials[i] = time_spent;
      if (depth <= 5 && i == iters-1) {
        printf("\nOutput tree:\n");
        printTree(t2); printf("\n");
      }
      DELTREE(t2);
    }
    qsort(trials, iters, sizeof(double), compare_doubles);
    printf("\nSorted: ");
    for(int i=0; i<iters; i++)
      printf(" %d",  (int)(trials[i] * 1000));
    printf("\nMINTIME: %lf\n",    trials[0]);
    printf("MEDIANTIME: %lf\n", trials[iters / 2]);
    printf("MAXTIME: %lf\n", trials[iters - 1]);
    printf("AVGTIME: %lf\n", avg(trials,iters));
    // printTree(t2); printf("\n");
  }
  else
  {
    printf("Timing %d iters as a batch\n", iters);
#ifdef BUMPALLOC
      char* starting_heap_pointer = heap_ptr;
#endif
    clock_gettime(which_clock, &begin);
    for(int i=0; i<iters; i++) {
#ifdef PARALLEL
      Tree* t2 = add1TreePar(tr, 5);
#else      
      Tree* t2 = add1Tree(tr);
#endif
#ifdef BUMPALLOC
      allocated_bytes = (long)(heap_ptr - starting_heap_pointer);
#endif
      DELTREE(t2);
    }
    clock_gettime(which_clock, &end);
#ifdef BUMPALLOC
    printf("Bytes allocated during whole batch:\n");
    printf("BYTESALLOC: %ld\n", allocated_bytes);
#endif
    time_spent = difftimespecs(&begin, &end);
    printf("BATCHTIME: %lf\n", time_spent);
  }
  DELTREE(tr);
  return 0;
}

