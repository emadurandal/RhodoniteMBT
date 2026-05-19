export function largeStorageBufferDeviceDescriptor(
	adapter: GPUAdapter,
): GPUDeviceDescriptor {
	const requiredLimits: Record<string, number> = {};
	const { limits } = adapter;

	if (typeof limits.maxStorageBufferBindingSize === "number") {
		requiredLimits.maxStorageBufferBindingSize =
			limits.maxStorageBufferBindingSize;
	}
	if (typeof limits.maxBufferSize === "number") {
		requiredLimits.maxBufferSize = limits.maxBufferSize;
	}

	if (Object.keys(requiredLimits).length === 0) {
		return {};
	}
	return { requiredLimits };
}

export async function requestLargeStorageBufferDevice(
	adapter: GPUAdapter,
): Promise<GPUDevice> {
	return adapter.requestDevice(largeStorageBufferDeviceDescriptor(adapter));
}
