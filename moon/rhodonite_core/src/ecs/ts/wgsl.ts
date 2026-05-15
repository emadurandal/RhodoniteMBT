import type { GpuWriteView, World } from "./world.ts";

const GLOBAL_TRANSFORM_FORMAT_F16 = 1;
export const GLOBAL_TRANSFORM_REF_BYTE_SIZE = 8;

type GlobalTransformWordCapacitySource =
	| number
	| Pick<World, "globalTransformBlobWordCapacity">;

function globalTransformWordCapacity(
	source: GlobalTransformWordCapacitySource,
): number {
	return typeof source === "number"
		? source
		: source.globalTransformBlobWordCapacity();
}

export function globalTransformWordsBinding(
	group = 0,
	binding = 0,
	varName = "transform_words",
): string {
	return `@group(${group}) @binding(${binding}) var<storage, read> ${varName}: array<u32>;\n`;
}

export function globalTransformWordsBindingDefault(): string {
	return globalTransformWordsBinding();
}

export function globalTransformRefVertexAttribute(
	shaderLocation = 1,
	offset = 0,
): GPUVertexAttribute {
	return {
		format: "uint32x2",
		offset,
		shaderLocation,
	};
}

export function globalTransformRefInstanceVertexBufferLayout(
	arrayStride: GPUSize64,
	options: {
		readonly shaderLocation?: number;
		readonly offset?: GPUSize64;
		readonly extraAttributes?: readonly GPUVertexAttribute[];
	} = {},
): GPUVertexBufferLayout {
	return {
		arrayStride,
		stepMode: "instance",
		attributes: [
			globalTransformRefVertexAttribute(
				options.shaderLocation,
				options.offset,
			),
			...(options.extraAttributes ?? []),
		],
	};
}

export function globalTransformWordsBindGroup(
	device: GPUDevice,
	pipeline: GPURenderPipeline,
	buffer: GPUBuffer,
	options: {
		readonly groupIndex?: number;
		readonly binding?: number;
	} = {},
): GPUBindGroup {
	return device.createBindGroup({
		layout: pipeline.getBindGroupLayout(options.groupIndex ?? 0),
		entries: [
			{
				binding: options.binding ?? 0,
				resource: { buffer },
			},
		],
	});
}

export function globalTransformWordsBufferByteSize(
	source: GlobalTransformWordCapacitySource,
): GPUSize64 {
	return Math.max(globalTransformWordCapacity(source) * 4, 4);
}

export function createGlobalTransformWordsBuffer(
	device: GPUDevice,
	source: GlobalTransformWordCapacitySource,
): GPUBuffer {
	return device.createBuffer({
		size: globalTransformWordsBufferByteSize(source),
		usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST,
	});
}

export function uploadGlobalTransformWrites(
	queue: GPUQueue,
	buffer: GPUBuffer,
	writes: readonly GpuWriteView[],
): void {
	for (const write of writes) {
		const bytes = write.bytes();
		const view = bytes.asUint8Array();
		if (view !== null) {
			queue.writeBuffer(buffer, write.byteOffset(), view, 0, view.byteLength);
		} else {
			queue.writeBuffer(buffer, write.byteOffset(), bytes.toUint8ArrayCopy());
		}
	}
}

export function drainAndUploadGlobalTransformWrites(
  queue: GPUQueue,
  buffer: GPUBuffer,
  world: Pick<World, "drainGlobalTransformBlobWriteViews">,
): void {
	uploadGlobalTransformWrites(
		queue,
		buffer,
		world.drainGlobalTransformBlobWriteViews(),
	);
}

export function uploadGlobalTransformBytes(
	queue: GPUQueue,
	buffer: GPUBuffer,
	bytes: Uint8Array,
	byteOffset = 0,
): void {
	queue.writeBuffer(buffer, byteOffset, bytes);
}

type CameraWordCapacitySource =
	| number
	| Pick<World, "cameraBlobWordCapacity">;

function cameraWordCapacity(source: CameraWordCapacitySource): number {
	return typeof source === "number" ? source : source.cameraBlobWordCapacity();
}

export function cameraWordsBinding(
	group = 1,
	binding = 0,
	varName = "camera_words",
): string {
	return `@group(${group}) @binding(${binding}) var<storage, read> ${varName}: array<u32>;\n`;
}

export function cameraWordsBindingDefault(): string {
	return cameraWordsBinding();
}

export function cameraWordsBindGroup(
	device: GPUDevice,
	pipeline: GPURenderPipeline,
	buffer: GPUBuffer,
	options: {
		readonly groupIndex?: number;
		readonly binding?: number;
	} = {},
): GPUBindGroup {
	return device.createBindGroup({
		layout: pipeline.getBindGroupLayout(options.groupIndex ?? 1),
		entries: [
			{
				binding: options.binding ?? 0,
				resource: { buffer },
			},
		],
	});
}

export function cameraWordsBufferByteSize(
	source: CameraWordCapacitySource,
): GPUSize64 {
	return Math.max(cameraWordCapacity(source) * 4, 4);
}

export function createCameraWordsBuffer(
	device: GPUDevice,
	source: CameraWordCapacitySource,
): GPUBuffer {
	return device.createBuffer({
		size: cameraWordsBufferByteSize(source),
		usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST,
	});
}

export function uploadCameraWrites(
	queue: GPUQueue,
	buffer: GPUBuffer,
	writes: readonly GpuWriteView[],
): void {
	uploadGlobalTransformWrites(queue, buffer, writes);
}

export function drainAndUploadCameraWrites(
	queue: GPUQueue,
	buffer: GPUBuffer,
	world: Pick<World, "drainCameraBlobWriteViews">,
): void {
	uploadCameraWrites(queue, buffer, world.drainCameraBlobWriteViews());
}

export function cameraHelpers(cameraWordsVar = "camera_words"): string {
	return `
struct RnCamera {
  view_proj: mat4x4<f32>,
  view: mat4x4<f32>,
  proj: mat4x4<f32>,
  inv_view_proj: mat4x4<f32>,
  world_pos_near: vec4<f32>,
  params: vec4<f32>,
}

fn rn_load_camera_mat4(word_offset: u32) -> mat4x4<f32> {
  return mat4x4<f32>(
    vec4<f32>(
      bitcast<f32>(${cameraWordsVar}[word_offset + 0u]),
      bitcast<f32>(${cameraWordsVar}[word_offset + 1u]),
      bitcast<f32>(${cameraWordsVar}[word_offset + 2u]),
      bitcast<f32>(${cameraWordsVar}[word_offset + 3u]),
    ),
    vec4<f32>(
      bitcast<f32>(${cameraWordsVar}[word_offset + 4u]),
      bitcast<f32>(${cameraWordsVar}[word_offset + 5u]),
      bitcast<f32>(${cameraWordsVar}[word_offset + 6u]),
      bitcast<f32>(${cameraWordsVar}[word_offset + 7u]),
    ),
    vec4<f32>(
      bitcast<f32>(${cameraWordsVar}[word_offset + 8u]),
      bitcast<f32>(${cameraWordsVar}[word_offset + 9u]),
      bitcast<f32>(${cameraWordsVar}[word_offset + 10u]),
      bitcast<f32>(${cameraWordsVar}[word_offset + 11u]),
    ),
    vec4<f32>(
      bitcast<f32>(${cameraWordsVar}[word_offset + 12u]),
      bitcast<f32>(${cameraWordsVar}[word_offset + 13u]),
      bitcast<f32>(${cameraWordsVar}[word_offset + 14u]),
      bitcast<f32>(${cameraWordsVar}[word_offset + 15u]),
    ),
  );
}

fn rn_load_camera(word_offset: u32) -> RnCamera {
  var camera: RnCamera;
  camera.view_proj = rn_load_camera_mat4(word_offset + 0u);
  camera.view = rn_load_camera_mat4(word_offset + 16u);
  camera.proj = rn_load_camera_mat4(word_offset + 32u);
  camera.inv_view_proj = rn_load_camera_mat4(word_offset + 48u);
  camera.world_pos_near = vec4<f32>(
    bitcast<f32>(${cameraWordsVar}[word_offset + 64u]),
    bitcast<f32>(${cameraWordsVar}[word_offset + 65u]),
    bitcast<f32>(${cameraWordsVar}[word_offset + 66u]),
    bitcast<f32>(${cameraWordsVar}[word_offset + 67u]),
  );
  camera.params = vec4<f32>(
    bitcast<f32>(${cameraWordsVar}[word_offset + 68u]),
    bitcast<f32>(${cameraWordsVar}[word_offset + 69u]),
    bitcast<f32>(${cameraWordsVar}[word_offset + 70u]),
    bitcast<f32>(${cameraWordsVar}[word_offset + 71u]),
  );
  return camera;
}
`;
}

export function cameraHelpersDefault(): string {
	return cameraHelpers();
}

export function globalTransformHelpers(
	transformWordsVar = "transform_words",
): string {
	return `
struct RnGlobalTransformRows {
  row0: vec4<f32>,
  row1: vec4<f32>,
  row2: vec4<f32>,
}

fn rn_load_global_transform(transform_ref: vec2<u32>) -> RnGlobalTransformRows {
  let format = transform_ref.x;
  let word_offset = transform_ref.y;
  var rows: RnGlobalTransformRows;
  if (format == ${GLOBAL_TRANSFORM_FORMAT_F16}u) {
    let r0xy = unpack2x16float(${transformWordsVar}[word_offset + 0u]);
    let r0zw = unpack2x16float(${transformWordsVar}[word_offset + 1u]);
    let r1xy = unpack2x16float(${transformWordsVar}[word_offset + 2u]);
    let r1zw = unpack2x16float(${transformWordsVar}[word_offset + 3u]);
    let r2xy = unpack2x16float(${transformWordsVar}[word_offset + 4u]);
    let r2zw = unpack2x16float(${transformWordsVar}[word_offset + 5u]);
    rows.row0 = vec4<f32>(r0xy.x, r0xy.y, r0zw.x, r0zw.y);
    rows.row1 = vec4<f32>(r1xy.x, r1xy.y, r1zw.x, r1zw.y);
    rows.row2 = vec4<f32>(r2xy.x, r2xy.y, r2zw.x, r2zw.y);
  } else {
    rows.row0 = vec4<f32>(
      bitcast<f32>(${transformWordsVar}[word_offset + 0u]),
      bitcast<f32>(${transformWordsVar}[word_offset + 1u]),
      bitcast<f32>(${transformWordsVar}[word_offset + 2u]),
      bitcast<f32>(${transformWordsVar}[word_offset + 3u]),
    );
    rows.row1 = vec4<f32>(
      bitcast<f32>(${transformWordsVar}[word_offset + 4u]),
      bitcast<f32>(${transformWordsVar}[word_offset + 5u]),
      bitcast<f32>(${transformWordsVar}[word_offset + 6u]),
      bitcast<f32>(${transformWordsVar}[word_offset + 7u]),
    );
    rows.row2 = vec4<f32>(
      bitcast<f32>(${transformWordsVar}[word_offset + 8u]),
      bitcast<f32>(${transformWordsVar}[word_offset + 9u]),
      bitcast<f32>(${transformWordsVar}[word_offset + 10u]),
      bitcast<f32>(${transformWordsVar}[word_offset + 11u]),
    );
  }
  return rows;
}

fn rn_transform_point(rows: RnGlobalTransformRows, local_pos: vec3<f32>) -> vec4<f32> {
  let local_h = vec4<f32>(local_pos, 1.0);
  return vec4<f32>(
    dot(rows.row0, local_h),
    dot(rows.row1, local_h),
    dot(rows.row2, local_h),
    1.0,
  );
}
`;
}

export function globalTransformHelpersDefault(): string {
	return globalTransformHelpers();
}
