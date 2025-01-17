#include <musa_runtime.h>
#include <stdio.h>

#define NUM_THREADS 1000
#define NUM_BLOCKS 1000

// Kernel without atomics (incorrect)
__global__ void incrementCounterNonAtomic(int* counter) {
    // not locked
    int old = *counter;
    int new_value = old + 1;
    // not unlocked
    *counter = new_value;
}

// Kernel with atomics (correct)
__global__ void incrementCounterAtomic(int* counter) {
    int a = atomicAdd(counter, 1);
}

int main() {
    int h_counterNonAtomic = 0;
    int h_counterAtomic = 0;
    int *d_counterNonAtomic, *d_counterAtomic;

    // Allocate device memory
    musaMalloc((void**)&d_counterNonAtomic, sizeof(int));
    musaMalloc((void**)&d_counterAtomic, sizeof(int));

    // Copy initial counter values to device
    musaMemcpy(d_counterNonAtomic, &h_counterNonAtomic, sizeof(int), musaMemcpyHostToDevice);
    musaMemcpy(d_counterAtomic, &h_counterAtomic, sizeof(int), musaMemcpyHostToDevice);

    // Launch kernels
    incrementCounterNonAtomic<<<NUM_BLOCKS, NUM_THREADS>>>(d_counterNonAtomic);
    incrementCounterAtomic<<<NUM_BLOCKS, NUM_THREADS>>>(d_counterAtomic);

    // Copy results back to host
    musaMemcpy(&h_counterNonAtomic, d_counterNonAtomic, sizeof(int), musaMemcpyDeviceToHost);
    musaMemcpy(&h_counterAtomic, d_counterAtomic, sizeof(int), musaMemcpyDeviceToHost);

    // Print results
    printf("Non-atomic counter value: %d\n", h_counterNonAtomic);
    printf("Atomic counter value: %d\n", h_counterAtomic);

    // Free device memory
    musaFree(d_counterNonAtomic);
    musaFree(d_counterAtomic);

    return 0;
}