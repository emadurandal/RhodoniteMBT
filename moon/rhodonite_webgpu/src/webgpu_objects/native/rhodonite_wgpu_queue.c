#include <stdint.h>

#include "moonbit.h"

typedef struct WGPUBufferImpl* WGPUBuffer;
typedef struct WGPUQueueImpl* WGPUQueue;

extern void wgpuQueueWriteBuffer(
  WGPUQueue queue,
  WGPUBuffer buffer,
  uint64_t bufferOffset,
  void const* data,
  uint64_t size
);

void rhodonite_wgpu_queue_write_buffer_bytes_range(
  WGPUQueue queue,
  WGPUBuffer buffer,
  uint64_t buffer_offset,
  moonbit_bytes_t data,
  uint64_t data_offset,
  uint64_t size
) {
  wgpuQueueWriteBuffer(queue, buffer, buffer_offset, data + data_offset, size);
}
