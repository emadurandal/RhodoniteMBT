export const VISUAL_SNAPSHOT_WIDTH = 800;
export const VISUAL_SNAPSHOT_HEIGHT = 600;

export type WebGpuReadbackTarget = {
	readonly texture: GPUTexture;
	readonly view: GPUTextureView;
	readonly depthTexture: GPUTexture;
	readonly depthView: GPUTextureView;
};

export function rgba8CopyBytesPerRow(width: number): number {
	const unpadded = width * 4;
	const align = 256;
	return Math.ceil(unpadded / align) * align;
}

export function createRgba8ReadbackTarget(
	device: GPUDevice,
	width = VISUAL_SNAPSHOT_WIDTH,
	height = VISUAL_SNAPSHOT_HEIGHT,
): WebGpuReadbackTarget {
	const texture = device.createTexture({
		size: [width, height],
		format: "rgba8unorm",
		usage: GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.COPY_SRC,
	});
	const depthTexture = device.createTexture({
		size: [width, height],
		format: "depth24plus",
		usage: GPUTextureUsage.RENDER_ATTACHMENT,
	});
	return {
		texture,
		view: texture.createView(),
		depthTexture,
		depthView: depthTexture.createView(),
	};
}

export async function readRgba8Texture(
	device: GPUDevice,
	queue: GPUQueue,
	texture: GPUTexture,
	width = VISUAL_SNAPSHOT_WIDTH,
	height = VISUAL_SNAPSHOT_HEIGHT,
): Promise<Uint8Array> {
	const bytesPerRow = rgba8CopyBytesPerRow(width);
	const readback = device.createBuffer({
		size: bytesPerRow * height,
		usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ,
	});
	const encoder = device.createCommandEncoder();
	encoder.copyTextureToBuffer(
		{ texture },
		{ buffer: readback, bytesPerRow, rowsPerImage: height },
		{ width, height, depthOrArrayLayers: 1 },
	);
	queue.submit([encoder.finish()]);
	await readback.mapAsync(GPUMapMode.READ);
	try {
		const raw = new Uint8Array(readback.getMappedRange());
		const pixels = new Uint8Array(width * height * 4);
		for (let y = 0; y < height; y += 1) {
			pixels.set(
				raw.subarray(y * bytesPerRow, y * bytesPerRow + width * 4),
				y * width * 4,
			);
		}
		return pixels;
	} finally {
		readback.unmap();
		readback.destroy();
	}
}

export function destroyReadbackTarget(target: WebGpuReadbackTarget): void {
	target.depthTexture.destroy();
	target.texture.destroy();
}
