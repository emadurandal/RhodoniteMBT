// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import type { Engine } from "./app-runtime-engine.ts";

export type KeyCode = string;

export const MouseButton = {
	Left: "Left",
	Middle: "Middle",
	Right: "Right",
	Back: "Back",
	Forward: "Forward",
	Other: "Other",
} as const;

export type MouseButton =
	| (typeof MouseButton)[keyof typeof MouseButton]
	| `Other:${number}`;

export type Modifiers = {
	readonly shift: boolean;
	readonly ctrl: boolean;
	readonly alt: boolean;
	readonly meta: boolean;
};

export type InputEvent =
	| {
			readonly type: "KeyDown";
			readonly key: KeyCode;
			readonly modifiers: Modifiers;
			readonly repeat: boolean;
	  }
	| {
			readonly type: "KeyUp";
			readonly key: KeyCode;
			readonly modifiers: Modifiers;
	  }
	| { readonly type: "TextInput"; readonly text: string }
	| { readonly type: "PointerMove"; readonly x: number; readonly y: number }
	| {
			readonly type: "MouseDown";
			readonly button: MouseButton;
			readonly x: number;
			readonly y: number;
	  }
	| {
			readonly type: "MouseUp";
			readonly button: MouseButton;
			readonly x: number;
			readonly y: number;
	  }
	| { readonly type: "Wheel"; readonly deltaX: number; readonly deltaY: number }
	| { readonly type: "FocusLost" };

export class InputState {
	private readonly keysDownValue = new Set<KeyCode>();
	private readonly keysPressedValue = new Set<KeyCode>();
	private readonly keysReleasedValue = new Set<KeyCode>();
	private readonly mouseButtonsDownValue = new Set<MouseButton>();
	private readonly mouseButtonsPressedValue = new Set<MouseButton>();
	private readonly mouseButtonsReleasedValue = new Set<MouseButton>();
	private pointerXValue = 0;
	private pointerYValue = 0;
	private pointerDeltaXValue = 0;
	private pointerDeltaYValue = 0;
	private wheelDeltaXValue = 0;
	private wheelDeltaYValue = 0;
	private readonly eventsValue: InputEvent[] = [];
	private readonly queuedEvents: InputEvent[] = [];

	beginFrame(): void {
		this.keysPressedValue.clear();
		this.keysReleasedValue.clear();
		this.mouseButtonsPressedValue.clear();
		this.mouseButtonsReleasedValue.clear();
		this.pointerDeltaXValue = 0;
		this.pointerDeltaYValue = 0;
		this.wheelDeltaXValue = 0;
		this.wheelDeltaYValue = 0;
		this.eventsValue.length = 0;
		for (const event of this.queuedEvents) {
			this.applyEventToFrame(event);
		}
		this.queuedEvents.length = 0;
	}

	enqueueEvent(event: InputEvent): void {
		this.queuedEvents.push(event);
	}

	applyEvent(event: InputEvent): void {
		this.applyEventToFrame(event);
	}

	keyDown(key: KeyCode): boolean {
		return this.keysDownValue.has(key);
	}

	keyPressed(key: KeyCode): boolean {
		return this.keysPressedValue.has(key);
	}

	keyReleased(key: KeyCode): boolean {
		return this.keysReleasedValue.has(key);
	}

	mouseDown(button: MouseButton): boolean {
		return this.mouseButtonsDownValue.has(button);
	}

	mousePressed(button: MouseButton): boolean {
		return this.mouseButtonsPressedValue.has(button);
	}

	mouseReleased(button: MouseButton): boolean {
		return this.mouseButtonsReleasedValue.has(button);
	}

	pointerX(): number {
		return this.pointerXValue;
	}

	pointerY(): number {
		return this.pointerYValue;
	}

	pointerDeltaX(): number {
		return this.pointerDeltaXValue;
	}

	pointerDeltaY(): number {
		return this.pointerDeltaYValue;
	}

	wheelDeltaX(): number {
		return this.wheelDeltaXValue;
	}

	wheelDeltaY(): number {
		return this.wheelDeltaYValue;
	}

	events(): InputEvent[] {
		return [...this.eventsValue];
	}

	private applyEventToFrame(event: InputEvent): void {
		switch (event.type) {
			case "KeyDown":
				if (!event.repeat && !this.keysDownValue.has(event.key)) {
					this.keysPressedValue.add(event.key);
				}
				this.keysDownValue.add(event.key);
				break;
			case "KeyUp":
				if (this.keysDownValue.has(event.key)) {
					this.keysReleasedValue.add(event.key);
				}
				this.keysDownValue.delete(event.key);
				break;
			case "TextInput":
				break;
			case "PointerMove":
				this.applyPointerMove(event.x, event.y);
				break;
			case "MouseDown":
				this.applyPointerMove(event.x, event.y);
				if (!this.mouseButtonsDownValue.has(event.button)) {
					this.mouseButtonsPressedValue.add(event.button);
				}
				this.mouseButtonsDownValue.add(event.button);
				break;
			case "MouseUp":
				this.applyPointerMove(event.x, event.y);
				if (this.mouseButtonsDownValue.has(event.button)) {
					this.mouseButtonsReleasedValue.add(event.button);
				}
				this.mouseButtonsDownValue.delete(event.button);
				break;
			case "Wheel":
				this.wheelDeltaXValue += event.deltaX;
				this.wheelDeltaYValue += event.deltaY;
				break;
			case "FocusLost":
				this.keysDownValue.clear();
				this.mouseButtonsDownValue.clear();
				break;
		}
		this.eventsValue.push(event);
	}

	private applyPointerMove(x: number, y: number): void {
		this.pointerDeltaXValue += x - this.pointerXValue;
		this.pointerDeltaYValue += y - this.pointerYValue;
		this.pointerXValue = x;
		this.pointerYValue = y;
	}
}

export type BrowserInputBinding = {
	dispose: () => void;
};

export type BrowserFrameLoop = {
	request: () => void;
	stop: () => void;
};

function keyboardModifiers(event: KeyboardEvent): Modifiers {
	return {
		shift: event.shiftKey,
		ctrl: event.ctrlKey,
		alt: event.altKey,
		meta: event.metaKey,
	};
}

function pointerPosition(
	canvas: HTMLCanvasElement,
	event: PointerEvent | WheelEvent,
): { x: number; y: number } {
	const rect = canvas.getBoundingClientRect();
	const scaleX = canvas.width / rect.width;
	const scaleY = canvas.height / rect.height;
	return {
		x: (event.clientX - rect.left) * scaleX,
		y: (event.clientY - rect.top) * scaleY,
	};
}

function pointerButton(button: number): MouseButton {
	switch (button) {
		case 0:
			return MouseButton.Left;
		case 1:
			return MouseButton.Middle;
		case 2:
			return MouseButton.Right;
		case 3:
			return MouseButton.Back;
		case 4:
			return MouseButton.Forward;
		default:
			return `Other:${button}`;
	}
}

export type BrowserInputCallbacks = {
	readonly keyDown?: (
		key: KeyCode,
		modifiers: Modifiers,
		repeat: boolean,
	) => void;
	readonly keyUp?: (key: KeyCode, modifiers: Modifiers) => void;
	readonly pointerMove?: (x: number, y: number) => void;
	readonly mouseDown?: (button: number, x: number, y: number) => void;
	readonly mouseUp?: (button: number, x: number, y: number) => void;
	readonly wheel?: (deltaX: number, deltaY: number) => void;
	readonly focusLost?: () => void;
};

export function startBrowserFrameLoop(
	onFrame: (deltaSeconds: number) => void,
): BrowserFrameLoop {
	let stopped = false;
	let previousTimestamp: number | null = null;
	let requestId = 0;
	const loop = (timestamp: number): void => {
		if (stopped) {
			return;
		}
		const deltaSeconds =
			previousTimestamp === null ? 0 : (timestamp - previousTimestamp) / 1000;
		previousTimestamp = timestamp;
		onFrame(deltaSeconds);
		if (!stopped) {
			requestId = requestAnimationFrame(loop);
		}
	};
	requestId = requestAnimationFrame(loop);
	return {
		request: (): void => {},
		stop: (): void => {
			stopped = true;
			if (requestId !== 0) {
				cancelAnimationFrame(requestId);
				requestId = 0;
			}
		},
	};
}

export function startBrowserOnDemandFrameLoop(
	onFrame: (deltaSeconds: number) => void,
	shouldContinue: () => boolean,
): BrowserFrameLoop {
	let stopped = false;
	let scheduled = false;
	let previousTimestamp: number | null = null;
	let requestId = 0;
	const request = (): void => {
		if (stopped || scheduled) {
			return;
		}
		scheduled = true;
		requestId = requestAnimationFrame(loop);
	};
	const loop = (timestamp: number): void => {
		if (stopped) {
			return;
		}
		scheduled = false;
		const deltaSeconds =
			previousTimestamp === null ? 0 : (timestamp - previousTimestamp) / 1000;
		previousTimestamp = timestamp;
		onFrame(deltaSeconds);
		if (!stopped && shouldContinue()) {
			request();
		} else {
			previousTimestamp = null;
		}
	};
	return {
		request,
		stop: (): void => {
			stopped = true;
			if (scheduled && requestId !== 0) {
				cancelAnimationFrame(requestId);
			}
			scheduled = false;
			requestId = 0;
		},
	};
}

export function installBrowserInputCallbacks(
	canvas: HTMLCanvasElement,
	callbacks: BrowserInputCallbacks,
	options: { keyboardTarget?: Window | HTMLElement } = {},
): BrowserInputBinding {
	const keyboardTarget = options.keyboardTarget ?? window;
	const onKeyDown: EventListener = (event): void => {
		const keyboardEvent = event as KeyboardEvent;
		callbacks.keyDown?.(
			keyboardEvent.code,
			keyboardModifiers(keyboardEvent),
			keyboardEvent.repeat,
		);
	};
	const onKeyUp: EventListener = (event): void => {
		const keyboardEvent = event as KeyboardEvent;
		callbacks.keyUp?.(keyboardEvent.code, keyboardModifiers(keyboardEvent));
	};
	const onPointerMove = (event: PointerEvent): void => {
		const { x, y } = pointerPosition(canvas, event);
		callbacks.pointerMove?.(x, y);
	};
	const onPointerDown = (event: PointerEvent): void => {
		event.preventDefault();
		canvas.setPointerCapture(event.pointerId);
		const { x, y } = pointerPosition(canvas, event);
		callbacks.mouseDown?.(event.button, x, y);
	};
	const onPointerUp = (event: PointerEvent): void => {
		const { x, y } = pointerPosition(canvas, event);
		callbacks.mouseUp?.(event.button, x, y);
	};
	const onWheel = (event: WheelEvent): void => {
		event.preventDefault();
		callbacks.wheel?.(event.deltaX, event.deltaY);
	};
	const onBlur = (): void => {
		callbacks.focusLost?.();
	};
	keyboardTarget.addEventListener("keydown", onKeyDown);
	keyboardTarget.addEventListener("keyup", onKeyUp);
	canvas.addEventListener("pointermove", onPointerMove);
	canvas.addEventListener("pointerdown", onPointerDown);
	canvas.addEventListener("pointerup", onPointerUp);
	canvas.addEventListener("wheel", onWheel, { passive: false });
	window.addEventListener("blur", onBlur);
	return {
		dispose: (): void => {
			keyboardTarget.removeEventListener("keydown", onKeyDown);
			keyboardTarget.removeEventListener("keyup", onKeyUp);
			canvas.removeEventListener("pointermove", onPointerMove);
			canvas.removeEventListener("pointerdown", onPointerDown);
			canvas.removeEventListener("pointerup", onPointerUp);
			canvas.removeEventListener("wheel", onWheel);
			window.removeEventListener("blur", onBlur);
		},
	};
}

export function installBrowserInputState(
	input: InputState,
	canvas: HTMLCanvasElement,
	options: { keyboardTarget?: Window | HTMLElement; onInput?: () => void } = {},
): BrowserInputBinding {
	return installBrowserInputCallbacks(
		canvas,
		{
			keyDown: (key, modifiers, repeat) => {
				input.enqueueEvent({ type: "KeyDown", key, modifiers, repeat });
				options.onInput?.();
			},
			keyUp: (key, modifiers) => {
				input.enqueueEvent({ type: "KeyUp", key, modifiers });
				options.onInput?.();
			},
			pointerMove: (x, y) => {
				input.enqueueEvent({ type: "PointerMove", x, y });
				options.onInput?.();
			},
			mouseDown: (button, x, y) => {
				input.enqueueEvent({
					type: "MouseDown",
					button: pointerButton(button),
					x,
					y,
				});
				options.onInput?.();
			},
			mouseUp: (button, x, y) => {
				input.enqueueEvent({
					type: "MouseUp",
					button: pointerButton(button),
					x,
					y,
				});
				options.onInput?.();
			},
			wheel: (deltaX, deltaY) => {
				input.enqueueEvent({ type: "Wheel", deltaX, deltaY });
				options.onInput?.();
			},
			focusLost: () => {
				input.enqueueEvent({ type: "FocusLost" });
				options.onInput?.();
			},
		},
		options,
	);
}

export function installBrowserInput(
	engine: Engine,
	options: { keyboardTarget?: Window | HTMLElement } = {},
): BrowserInputBinding {
	return installBrowserInputState(engine.input, engine.canvas, {
		...options,
		onInput: () => engine.requestRender("input"),
	});
}
