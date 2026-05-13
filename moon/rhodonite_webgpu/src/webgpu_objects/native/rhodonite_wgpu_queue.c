#include <stdint.h>

#include "moonbit.h"

typedef struct WGPUBufferImpl* WGPUBuffer;
typedef struct WGPUQueueImpl* WGPUQueue;

typedef struct RhodoniteArrayViewU8 {
  int32_t start;
  int32_t end;
  moonbit_bytes_t bytes;
} RhodoniteArrayViewU8;

extern void wgpuQueueWriteBuffer(
  WGPUQueue queue,
  WGPUBuffer buffer,
  uint64_t bufferOffset,
  void const* data,
  uint64_t size
);

void rhodonite_wgpu_queue_write_buffer_array_view(
  WGPUQueue queue,
  WGPUBuffer buffer,
  uint64_t buffer_offset,
  RhodoniteArrayViewU8 data
) {
  uint64_t start = (uint64_t)data.start;
  uint64_t size = (uint64_t)(data.end - data.start);
  wgpuQueueWriteBuffer(queue, buffer, buffer_offset, data.bytes + start, size);
}

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
