// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { defaultMaxFixedStepsPerFrame } from "./app-runtime-phases.ts";
import type { InputState } from "./app-runtime-input.ts";

export class FrameState {
	readonly deltaSeconds: number;
	readonly frameIndex: number;
	readonly elapsedSeconds: number;
	readonly surfaceId: SurfaceId | undefined;
	readonly surface: SurfaceState;
	readonly surfaceChanged: boolean;
	readonly input: InputState | undefined;

	constructor(
		deltaSeconds: number,
		frameIndex: number,
		elapsedSeconds: number,
		surface: SurfaceState = SurfaceState.active(800, 600, "", 0),
		surfaceChanged = false,
		surfaceId: SurfaceId | undefined = undefined,
		input: InputState | undefined = undefined,
	) {
		this.deltaSeconds = deltaSeconds;
		this.frameIndex = frameIndex;
		this.elapsedSeconds = elapsedSeconds;
		this.surfaceId = surfaceId;
		this.surface = surface;
		this.surfaceChanged = surfaceChanged;
		this.input = input;
	}

	static zero(): FrameState {
		return new FrameState(0, 0, 0);
	}

	withSurface(surface: SurfaceState, surfaceChanged: boolean): FrameState {
		return new FrameState(
			this.deltaSeconds,
			this.frameIndex,
			this.elapsedSeconds,
			surface,
			surfaceChanged,
			this.surfaceId,
			this.input,
		);
	}

	withSurfaceView(
		surfaceId: SurfaceId,
		surface: SurfaceState,
		surfaceChanged: boolean,
		input: InputState,
	): FrameState {
		return new FrameState(
			this.deltaSeconds,
			this.frameIndex,
			this.elapsedSeconds,
			surface,
			surfaceChanged,
			surfaceId,
			input,
		);
	}
}

export type SurfaceId = number;

export class SurfaceState {
	readonly width: number;
	readonly height: number;
	readonly format: string;
	readonly active: boolean;
	readonly generation: number;

	private constructor(
		width: number,
		height: number,
		format: string,
		active: boolean,
		generation: number,
	) {
		this.width = width;
		this.height = height;
		this.format = format;
		this.active = active;
		this.generation = generation;
	}

	static active(
		width: number,
		height: number,
		format: string,
		generation: number,
	): SurfaceState {
		return new SurfaceState(width, height, format, true, generation);
	}

	static suspended(generation: number): SurfaceState {
		return new SurfaceState(0, 0, "", false, generation);
	}

	static fromDrawableSize(
		width: number,
		height: number,
		format: string,
		generation: number,
	): SurfaceState {
		return width > 0 && height > 0
			? SurfaceState.active(width, height, format, generation)
			: SurfaceState.suspended(generation);
	}

	equals(other: SurfaceState): boolean {
		return (
			this.active === other.active &&
			this.width === other.width &&
			this.height === other.height &&
			this.format === other.format &&
			this.generation === other.generation
		);
	}
}

export class GpuSurface {
	readonly canvas: HTMLCanvasElement;
	readonly context: GPUCanvasContext;
	readonly format: GPUTextureFormat;
	private stateValue: SurfaceState;

	constructor(
		canvas: HTMLCanvasElement,
		device: GPUDevice,
		format: GPUTextureFormat = navigator.gpu.getPreferredCanvasFormat(),
	) {
		const context = canvas.getContext("webgpu");
		if (context === null) {
			throw new Error("WebGPU canvas context is not available.");
		}
		context.configure({ device, format, alphaMode: "opaque" });
		this.canvas = canvas;
		this.context = context;
		this.format = format;
		this.stateValue = SurfaceState.fromDrawableSize(
			canvas.width,
			canvas.height,
			format,
			0,
		);
	}

	state(): SurfaceState {
		return this.stateValue;
	}

	syncFromCanvas(): boolean {
		const { width, height } = this.canvas;
		const current = this.stateValue;
		const unchanged = SurfaceState.fromDrawableSize(
			width,
			height,
			this.format,
			current.generation,
		);
		if (current.equals(unchanged)) {
			return false;
		}
		this.stateValue = SurfaceState.fromDrawableSize(
			width,
			height,
			this.format,
			current.generation + 1,
		);
		return true;
	}

	acquireView(): GPUTextureView {
		return this.context.getCurrentTexture().createView();
	}
}

export class TimeState {
	private renderFrameIndexValue = 0;
	private renderElapsedSecondsValue = 0;
	private fixedFrameIndexValue = 0;
	private fixedElapsedSecondsValue = 0;
	private fixedAccumulatorSecondsValue = 0;
	private readonly fixedDeltaSeconds: number;
	private readonly maxFixedStepsPerFrameValue: number;

	constructor(
		fixedDeltaSeconds = 1 / 60,
		maxFixedStepsPerFrame = defaultMaxFixedStepsPerFrame(),
	) {
		if (fixedDeltaSeconds <= 0) {
			throw new Error("TimeState: fixed delta must be positive.");
		}
		if (maxFixedStepsPerFrame <= 0) {
			throw new Error("TimeState: max fixed steps must be positive.");
		}
		this.fixedDeltaSeconds = fixedDeltaSeconds;
		this.maxFixedStepsPerFrameValue = maxFixedStepsPerFrame;
	}

	nextRenderFrame(deltaSeconds: number): FrameState {
		this.renderFrameIndexValue += 1;
		this.renderElapsedSecondsValue += deltaSeconds;
		return new FrameState(
			deltaSeconds,
			this.renderFrameIndexValue,
			this.renderElapsedSecondsValue,
		);
	}

	pushFixedElapsed(elapsedSeconds: number): void {
		this.fixedAccumulatorSecondsValue += elapsedSeconds;
	}

	canStepFixed(): boolean {
		return this.fixedAccumulatorSecondsValue >= this.fixedDeltaSeconds;
	}

	maxFixedStepsPerFrame(): number {
		return this.maxFixedStepsPerFrameValue;
	}

	nextFixedFrame(): FrameState {
		this.fixedAccumulatorSecondsValue -= this.fixedDeltaSeconds;
		this.fixedFrameIndexValue += 1;
		this.fixedElapsedSecondsValue += this.fixedDeltaSeconds;
		return new FrameState(
			this.fixedDeltaSeconds,
			this.fixedFrameIndexValue,
			this.fixedElapsedSecondsValue,
		);
	}

	private discardFixedAccumulator(): void {
		this.fixedAccumulatorSecondsValue = 0;
	}

	drainReadyFixedFrames(run: (frame: FrameState) => void): number {
		let count = 0;
		const maxSteps = this.maxFixedStepsPerFrame();
		while (count < maxSteps && this.canStepFixed()) {
			run(this.nextFixedFrame());
			count += 1;
		}
		if (this.canStepFixed()) {
			this.discardFixedAccumulator();
		}
		return count;
	}
}

