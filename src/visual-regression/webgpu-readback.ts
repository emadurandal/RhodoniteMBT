// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

export async function readPresentedCanvasRgba8(
	canvas: HTMLCanvasElement,
	queue?: GPUQueue,
): Promise<Uint8Array> {
	await queue?.onSubmittedWorkDone();
	await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));
	await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));
	const bitmap = await createImageBitmap(canvas);
	try {
		const readback = document.createElement("canvas");
		readback.width = canvas.width;
		readback.height = canvas.height;
		const ctx = readback.getContext("2d", { willReadFrequently: true });
		if (ctx === null) {
			throw new Error("2D canvas context is not available for readback.");
		}
		ctx.drawImage(bitmap, 0, 0);
		const image = ctx.getImageData(0, 0, canvas.width, canvas.height);
		return new Uint8Array(image.data.buffer.slice(0));
	} finally {
		bitmap.close();
	}
}
