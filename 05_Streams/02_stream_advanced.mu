#include <musa_runtime.h>
#include <stdio.h>
#include <iostream>

#define CHECK_CUDA_ERROR(val) check((val), #val, __FILE__, __LINE__)
template <typename T>
void check(T err, const char* const func, const char* const file, const int line) {
    if (err != musaSuccess) {
        fprintf(stderr, "CUDA error at %s:%d code=%d(%s) \"%s\" \n", file, line, static_cast<unsigned int>(err), musaGetErrorString(err), func);
        exit(EXIT_FAILURE);
    }
}

__global__ void kernel1(float *data, int n) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < n) {
        data[idx] *= 2.0f;
    }
}

__global__ void kernel2(float *data, int n) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < n) {
        data[idx] += 1.0f;
    }
}

void MUSART_CB myStreamCallback(musaStream_t stream, musaError_t status, void *userData) {
    printf("Stream callback: Operation completed\n");
}

int main(void) {
    const int N = 1000000;
    size_t size = N * sizeof(float);
    float *h_data, *d_data;
    musaStream_t stream1, stream2;
    musaEvent_t event;
    std::cout << event << std::endl;

    // Allocate host and device memory
    CHECK_CUDA_ERROR(musaMallocHost(&h_data, size));  // Pinned memory for faster transfers
    CHECK_CUDA_ERROR(musaMalloc(&d_data, size));

    // Initialize data
    for (int i = 0; i < N; ++i) {
        h_data[i] = static_cast<float>(i);
    }

    // Create streams with different priorities
    int leastPriority, greatestPriority;
    CHECK_CUDA_ERROR(musaDeviceGetStreamPriorityRange(&leastPriority, &greatestPriority));
    CHECK_CUDA_ERROR(musaStreamCreateWithPriority(&stream1, musaStreamNonBlocking, leastPriority));
    CHECK_CUDA_ERROR(musaStreamCreateWithPriority(&stream2, musaStreamNonBlocking, greatestPriority));

    // Create event
    CHECK_CUDA_ERROR(musaEventCreate(&event));

    // Asynchronous memory copy and kernel execution in stream1
    CHECK_CUDA_ERROR(musaMemcpyAsync(d_data, h_data, size, musaMemcpyHostToDevice, stream1));
    kernel1<<<(N + 255) / 256, 256, 0, stream1>>>(d_data, N);

    // Record event in stream1
    CHECK_CUDA_ERROR(musaEventRecord(event, stream1));

    // Make stream2 wait for event
    CHECK_CUDA_ERROR(musaStreamWaitEvent(stream2, event, 0));

    // Execute kernel in stream2
    kernel2<<<(N + 255) / 256, 256, 0, stream2>>>(d_data, N);

    // Add callback to stream2
    CHECK_CUDA_ERROR(musaStreamAddCallback(stream2, myStreamCallback, NULL, 0));

    // Asynchronous memory copy back to host
    CHECK_CUDA_ERROR(musaMemcpyAsync(h_data, d_data, size, musaMemcpyDeviceToHost, stream2));

    // Synchronize streams
    CHECK_CUDA_ERROR(musaStreamSynchronize(stream1));
    CHECK_CUDA_ERROR(musaStreamSynchronize(stream2));

    // Verify result
    for (int i = 0; i < N; ++i) {
        float expected = (static_cast<float>(i) * 2.0f) + 1.0f;
        if (fabs(h_data[i] - expected) > 1e-5) {
            fprintf(stderr, "Result verification failed at element %d!\n", i);
            exit(EXIT_FAILURE);
        }
    }

    printf("Test PASSED\n");

    // Clean up
    CHECK_CUDA_ERROR(musaFreeHost(h_data));
    CHECK_CUDA_ERROR(musaFree(d_data));
    CHECK_CUDA_ERROR(musaStreamDestroy(stream1));
    CHECK_CUDA_ERROR(musaStreamDestroy(stream2));
    CHECK_CUDA_ERROR(musaEventDestroy(event));

    return 0;
}