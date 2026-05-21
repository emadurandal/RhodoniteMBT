// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { vi } from "vitest";

export type FakeBuffer = GPUBuffer & {
	readonly id: number;
	readonly descriptor: GPUBufferDescriptor;
	destroyed: boolean;
};

export type FakeTexture = GPUTexture & {
	readonly descriptor: GPUTextureDescriptor;
	readonly view: GPUTextureView;
	destroyed: boolean;
};

export type FakeWrite = {
	readonly buffer: FakeBuffer;
	readonly offset: number;
	readonly bytes: Uint8Array;
};

export type FakeRenderPassCall = {
	readonly name: string;
	readonly args: readonly unknown[];
};

export class FakeQueue {
	readonly writes: FakeWrite[] = [];
	readonly submissions: GPUCommandBuffer[][] = [];

	writeBuffer(
		buffer: GPUBuffer,
		bufferOffset: GPUSize64,
		data: AllowSharedBufferSource | ArrayBufferView,
		dataOffset = 0,
		size?: GPUSize64,
	): void {
		const bytes =
			data instanceof ArrayBuffer
				? new Uint8Array(data)
				: new Uint8Array(data.buffer, data.byteOffset, data.byteLength);
		const copy = bytes.slice(
			dataOffset,
			size === undefined ? undefined : dataOffset + size,
		);
		this.writes.push({
			buffer: buffer as FakeBuffer,
			offset: Number(bufferOffset),
			bytes: copy,
		});
	}

	submit(commandBuffers: Iterable<GPUCommandBuffer>): void {
		this.submissions.push(Array.from(commandBuffers));
	}
}

export class FakeRenderPass {
	readonly calls: FakeRenderPassCall[] = [];

	setPipeline(pipeline: GPURenderPipeline): void {
		this.record("setPipeline", pipeline);
	}

	setBindGroup(index: number, bindGroup: GPUBindGroup): void {
		this.record("setBindGroup", index, bindGroup);
	}

	setIndexBuffer(
		buffer: GPUBuffer,
		indexFormat: GPUIndexFormat,
		offset?: GPUSize64,
		size?: GPUSize64,
	): void {
		this.record("setIndexBuffer", buffer, indexFormat, offset, size);
	}

	setVertexBuffer(
		slot: GPUIndex32,
		buffer: GPUBuffer | null,
		offset?: GPUSize64,
		size?: GPUSize64,
	): void {
		this.record("setVertexBuffer", slot, buffer, offset, size);
	}

	drawIndexed(
		indexCount: GPUSize32,
		instanceCount?: GPUSize32,
		firstIndex?: GPUSize32,
		baseVertex?: GPUSignedOffset32,
		firstInstance?: GPUSize32,
	): void {
		this.record(
			"drawIndexed",
			indexCount,
			instanceCount,
			firstIndex,
			baseVertex,
			firstInstance,
		);
	}

	end(): void {
		this.record("end");
	}

	private record(name: string, ...args: unknown[]): void {
		this.calls.push({ name, args });
	}
}

export class FakeCommandEncoder {
	readonly pass = new FakeRenderPass();
	renderPassDescriptor: GPURenderPassDescriptor | null = null;

	beginRenderPass(descriptor: GPURenderPassDescriptor): GPURenderPassEncoder {
		this.renderPassDescriptor = descriptor;
		return this.pass as unknown as GPURenderPassEncoder;
	}

	finish(): GPUCommandBuffer {
		return { encoder: this } as unknown as GPUCommandBuffer;
	}
}

export class FakeDevice {
	readonly buffers: FakeBuffer[] = [];
	readonly textures: FakeTexture[] = [];
	readonly bindGroups: GPUBindGroup[] = [];
	readonly encoders: FakeCommandEncoder[] = [];
	readonly queue = new FakeQueue();
	private nextBufferId = 1;

	createShaderModule(descriptor: GPUShaderModuleDescriptor): GPUShaderModule {
		return { descriptor } as unknown as GPUShaderModule;
	}

	createRenderPipeline(
		descriptor: GPURenderPipelineDescriptor,
	): GPURenderPipeline {
		return {
			descriptor,
			getBindGroupLayout: (index: number) => ({ index }),
		} as unknown as GPURenderPipeline;
	}

	createTexture(descriptor: GPUTextureDescriptor): GPUTexture {
		const texture = {
			descriptor,
			view: { texture: descriptor } as unknown as GPUTextureView,
			destroyed: false,
			createView() {
				return this.view;
			},
			destroy() {
				this.destroyed = true;
			},
		} as FakeTexture;
		this.textures.push(texture);
		return texture;
	}

	createBuffer(descriptor: GPUBufferDescriptor): GPUBuffer {
		const buffer = {
			id: this.nextBufferId,
			descriptor,
			destroyed: false,
			destroy() {
				this.destroyed = true;
			},
		} as FakeBuffer;
		this.nextBufferId += 1;
		this.buffers.push(buffer);
		return buffer;
	}

	createBindGroup(descriptor: GPUBindGroupDescriptor): GPUBindGroup {
		const bindGroup = { descriptor } as unknown as GPUBindGroup;
		this.bindGroups.push(bindGroup);
		return bindGroup;
	}

	createCommandEncoder(): GPUCommandEncoder {
		const encoder = new FakeCommandEncoder();
		this.encoders.push(encoder);
		return encoder as unknown as GPUCommandEncoder;
	}
}

export function installFakeWebGpuConstants(): void {
	vi.stubGlobal("GPUBufferUsage", {
		VERTEX: 1,
		COPY_DST: 2,
		INDEX: 4,
		STORAGE: 8,
	});
	vi.stubGlobal("GPUTextureUsage", {
		RENDER_ATTACHMENT: 1,
	});
}
