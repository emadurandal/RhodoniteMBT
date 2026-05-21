// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, it } from "vitest";
import { World } from "../../../../rhodonite_core/src/ecs/ts/index.ts";
import {
	MaterialHandle,
	MeshHandle,
	RenderableDesc,
	RenderableFlags,
	UnlitMaterialDesc,
	addRenderable,
	registerRenderableComponent,
	renderableComponentBytes,
	renderableComponentStride,
	renderableFlagsDefault,
	renderableFlagsNone,
	renderableFlagsVisible,
	setRenderable,
} from "./index.ts";

function renderableBytes(
	mesh: number,
	material: number,
	flags = renderableFlagsDefault(),
): Uint8Array {
	return renderableComponentBytes(
		RenderableDesc.new(new MeshHandle(mesh), new MaterialHandle(material), flags),
	);
}

describe("Renderer TypeScript renderable API", () => {
	it("packs renderable component rows in the ECS CPU layout", () => {
		const bytes = renderableBytes(
			0x01020304,
			0x05060708,
			new RenderableFlags(0x0a0b0c0d),
		);

		expect(bytes.byteLength).toBe(renderableComponentStride());
		expect(Array.from(bytes)).toEqual([
			0x04, 0x03, 0x02, 0x01, 0x08, 0x07, 0x06, 0x05, 0x0d, 0x0c, 0x0b, 0x0a,
			0, 0, 0, 0,
		]);
	});

	it("keeps renderable flags unsigned and composable", () => {
		const visible = renderableFlagsVisible();
		const allBits = new RenderableFlags(-1);

		expect(renderableFlagsNone().bits()).toBe(0);
		expect(visible.bits()).toBe(1);
		expect(renderableFlagsDefault().contains(visible)).toBe(true);
		expect(renderableFlagsNone().contains(visible)).toBe(false);
		expect(allBits.bits()).toBe(0xffffffff);
		expect(allBits.contains(visible)).toBe(true);
	});

	it("exposes mesh, material, and material descriptor accessors", () => {
		const mesh = new MeshHandle(7);
		const material = new MaterialHandle(9);
		const desc = RenderableDesc.new(mesh, material);
		const unlit = UnlitMaterialDesc.new(0.25, 0.5, 0.75, undefined, -1);

		expect(desc.mesh()).toBe(mesh);
		expect(desc.material()).toBe(material);
		expect(desc.flags().contains(renderableFlagsVisible())).toBe(true);
		expect(unlit.baseColorR()).toBeCloseTo(0.25);
		expect(unlit.baseColorG()).toBeCloseTo(0.5);
		expect(unlit.baseColorB()).toBeCloseTo(0.75);
		expect(unlit.alpha()).toBe(1);
		expect(unlit.flags()).toBe(0xffffffff);
	});

	it("registers a renderable CPU component and writes add/set rows", () => {
		const world = World.new();
		const renderable = registerRenderableComponent(world);
		const entity = world.createEntity();

		expect(world.componentCpuStride(renderable.id())).toBe(
			renderableComponentStride(),
		);
		expect(world.componentInfo(renderable.id())?.name()).toBe(
			"RhodoniteRenderable",
		);

		expect(
			addRenderable(
				world,
				entity,
				renderable,
				RenderableDesc.new(new MeshHandle(1), new MaterialHandle(2)),
			),
		).toBe(true);
		expect(renderable.entities()).toEqual([entity]);
		expect(world.componentBytesCopy(entity, renderable.id())).toEqual(
			renderableBytes(1, 2),
		);

		expect(
			setRenderable(
				world,
				entity,
				renderable,
				RenderableDesc.new(
					new MeshHandle(3),
					new MaterialHandle(4),
					renderableFlagsNone(),
				),
			),
		).toBe(true);
		expect(renderable.entities()).toEqual([entity]);
		expect(world.componentBytesCopy(entity, renderable.id())).toEqual(
			renderableBytes(3, 4, renderableFlagsNone()),
		);
	});
});
