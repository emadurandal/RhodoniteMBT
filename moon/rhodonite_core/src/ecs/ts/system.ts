// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import type {
	MoonCommandBuffer,
	MoonPhaseKey,
	MoonSystem,
	MoonSystemContext,
	MoonSystemRunner,
} from "@moon/rhodonite_core/ecs/js_bridge";
import {
	command_buffer_add_component,
	command_buffer_add_component_bytes,
	command_buffer_create_entity,
	command_buffer_destroy_entity,
	command_buffer_is_empty,
	command_buffer_len,
	command_buffer_remove_component,
	command_buffer_set_component_bytes,
	phase_key_name,
	phase_key_new,
	system_conflicts_with,
	system_context_delta_seconds,
	system_context_frame_index,
	system_context_new,
	system_new,
	system_new_with_structural_write,
	system_phase,
	system_reads,
	system_runner_add_system,
	system_runner_has_parallel_access_conflicts,
	system_runner_len,
	system_runner_new,
	system_runner_run_phase,
	system_structural_write,
	system_writes,
	system_name,
	transform_propagation_system,
} from "@moon/rhodonite_core/ecs/js_bridge";
import { ComponentTypeId, EntityId } from "./types.ts";
import { bytesInput, moonBool } from "./views.ts";
import { World } from "./world.ts";

export class PhaseKey {
	readonly inner: MoonPhaseKey;

	constructor(inner: MoonPhaseKey) {
		this.inner = inner;
	}

	static new(name: string): PhaseKey {
		return new PhaseKey(phase_key_new(name));
	}

	name(): string {
		return phase_key_name(this.inner);
	}
}

export class SystemContext {
	readonly inner: MoonSystemContext;

	constructor(inner: MoonSystemContext) {
		this.inner = inner;
	}

	static new(deltaSeconds: number, frameIndex: number): SystemContext {
		return new SystemContext(system_context_new(deltaSeconds, frameIndex));
	}

	deltaSeconds(): number {
		return system_context_delta_seconds(this.inner);
	}

	frameIndex(): number {
		return system_context_frame_index(this.inner);
	}
}

export class CommandBuffer {
	readonly inner: MoonCommandBuffer;

	constructor(inner: MoonCommandBuffer) {
		this.inner = inner;
	}

	len(): number {
		return command_buffer_len(this.inner);
	}

	isEmpty(): boolean {
		return moonBool(command_buffer_is_empty(this.inner));
	}

	createEntity(): EntityId {
		return new EntityId(command_buffer_create_entity(this.inner));
	}

	destroyEntity(entity: EntityId): void {
		command_buffer_destroy_entity(this.inner, entity.inner);
	}

	addComponent(entity: EntityId, component: ComponentTypeId): void {
		command_buffer_add_component(this.inner, entity.inner, component.inner);
	}

	addComponentBytes(
		entity: EntityId,
		component: ComponentTypeId,
		bytes: Uint8Array | ArrayLike<number>,
	): void {
		command_buffer_add_component_bytes(
			this.inner,
			entity.inner,
			component.inner,
			bytesInput(bytes),
		);
	}

	setComponentBytes(
		entity: EntityId,
		component: ComponentTypeId,
		bytes: Uint8Array | ArrayLike<number>,
	): void {
		command_buffer_set_component_bytes(
			this.inner,
			entity.inner,
			component.inner,
			bytesInput(bytes),
		);
	}

	removeComponent(entity: EntityId, component: ComponentTypeId): void {
		command_buffer_remove_component(this.inner, entity.inner, component.inner);
	}
}

export type SystemCallback = (
	world: World,
	ctx: SystemContext,
	commands: CommandBuffer,
) => void;

export class System {
	readonly inner: MoonSystem;

	constructor(inner: MoonSystem) {
		this.inner = inner;
	}

	static new(
		name: string,
		phase: PhaseKey,
		reads: ComponentTypeId[],
		writes: ComponentTypeId[],
		run: SystemCallback,
	): System {
		return new System(
			system_new(
				name,
				phase.inner,
				reads.map((component) => component.inner),
				writes.map((component) => component.inner),
				(world, ctx, commands) =>
					run(new World(world), new SystemContext(ctx), new CommandBuffer(commands)),
			),
		);
	}

	static newWithStructuralWrite(
		name: string,
		phase: PhaseKey,
		reads: ComponentTypeId[],
		writes: ComponentTypeId[],
		run: SystemCallback,
	): System {
		return new System(
			system_new_with_structural_write(
				name,
				phase.inner,
				reads.map((component) => component.inner),
				writes.map((component) => component.inner),
				(world, ctx, commands) =>
					run(new World(world), new SystemContext(ctx), new CommandBuffer(commands)),
			),
		);
	}

	name(): string {
		return system_name(this.inner);
	}

	phase(): PhaseKey {
		return new PhaseKey(system_phase(this.inner));
	}

	reads(): ComponentTypeId[] {
		return system_reads(this.inner).map(
			(component) => new ComponentTypeId(component),
		);
	}

	writes(): ComponentTypeId[] {
		return system_writes(this.inner).map(
			(component) => new ComponentTypeId(component),
		);
	}

	structuralWrite(): boolean {
		return moonBool(system_structural_write(this.inner));
	}

	conflictsWith(other: System): boolean {
		return moonBool(system_conflicts_with(this.inner, other.inner));
	}
}

export class SystemRunner {
	readonly inner: MoonSystemRunner;

	constructor(inner: MoonSystemRunner) {
		this.inner = inner;
	}

	static new(): SystemRunner {
		return new SystemRunner(system_runner_new());
	}

	len(): number {
		return system_runner_len(this.inner);
	}

	addSystem(system: System): void {
		system_runner_add_system(this.inner, system.inner);
	}

	hasParallelAccessConflicts(): boolean {
		return moonBool(system_runner_has_parallel_access_conflicts(this.inner));
	}

	runPhase(world: World, ctx: SystemContext, phase: PhaseKey): boolean {
		return moonBool(
			system_runner_run_phase(this.inner, world.inner, ctx.inner, phase.inner),
		);
	}
}

export function createTransformPropagationSystem(
	world: World,
	phase: PhaseKey,
): System {
	return new System(transform_propagation_system(world.inner, phase.inner));
}
