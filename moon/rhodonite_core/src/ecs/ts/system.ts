// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import type {
	MoonCommandBufferCommandFailure,
	MoonCommandBuffer,
	MoonPhaseKey,
	MoonSystem,
	MoonSystemContext,
	MoonSystemPhasePlan,
	MoonSystemPlanBatch,
	MoonSystemPlanSystem,
	MoonSystemRunBatchReport,
	MoonSystemRunReport,
	MoonSystemRunSystemReport,
	MoonSystemRunner,
} from "@moon/rhodonite_core/ecs/js_bridge";
import {
	command_buffer_command_failure_command_index,
	command_buffer_command_failure_command_kind,
	command_buffer_command_failure_component,
	command_buffer_command_failure_entity,
	command_buffer_command_failure_reason,
	command_buffer_add_component,
	command_buffer_add_component_bytes,
	command_buffer_create_entity,
	command_buffer_destroy_entity,
	command_buffer_is_empty,
	command_buffer_len,
	command_buffer_remove_component,
	command_buffer_set_camera_matrices_col_major,
	command_buffer_set_component_bytes,
	command_buffer_set_global_transform_col_major,
	command_buffer_set_global_transform_format,
	camera_blob_sync_command_system,
	orbit_camera_blob_sync_command_system,
	orbit_camera_transform_command_system,
	phase_key_name,
	phase_key_new,
	system_conflicts_with,
	system_context_delta_seconds,
	system_context_frame_index,
	system_context_new,
	system_new,
	system_new_direct,
	system_new_with_structural_write,
	system_phase,
	system_reads,
	system_runner_add_system,
	system_runner_has_parallel_access_conflicts,
	system_runner_len,
	system_runner_new,
	system_runner_plan_phase,
	system_runner_run_phase,
	system_runner_run_phase_report,
	system_structural_write,
	system_writes,
	system_name,
	system_phase_plan_batches,
	system_phase_plan_phase,
	system_phase_plan_system_count,
	system_plan_batch_index,
	system_plan_batch_systems,
	system_plan_system_batch_index,
	system_plan_system_name,
	system_plan_system_phase,
	system_plan_system_reads,
	system_plan_system_runner_index,
	system_plan_system_structural_write,
	system_plan_system_writes,
	system_run_batch_report_applied_command_count,
	system_run_batch_report_failed_command_count,
	system_run_batch_report_index,
	system_run_batch_report_ok,
	system_run_batch_report_queued_command_count,
	system_run_batch_report_system_count,
	system_run_batch_report_systems,
	system_run_report_applied_command_count,
	system_run_report_batch_count,
	system_run_report_batches,
	system_run_report_failed_command_count,
	system_run_report_ok,
	system_run_report_phase,
	system_run_report_queued_command_count,
	system_run_report_system_count,
	system_run_system_report_applied_command_count,
	system_run_system_report_batch_index,
	system_run_system_report_failed_command_count,
	system_run_system_report_failures,
	system_run_system_report_name,
	system_run_system_report_queued_command_count,
	system_run_system_report_runner_index,
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

	setGlobalTransform(entity: EntityId, matrixColMajor: ArrayLike<number>): void {
		command_buffer_set_global_transform_col_major(
			this.inner,
			entity.inner,
			Array.from(matrixColMajor),
		);
	}

	setGlobalTransformFormat(entity: EntityId, formatCode: 0 | 1): void {
		command_buffer_set_global_transform_format(
			this.inner,
			entity.inner,
			formatCode,
		);
	}

	setCameraMatrices(
		entity: EntityId,
		viewColMajor: ArrayLike<number>,
		projColMajor: ArrayLike<number>,
		near: number,
		far: number,
		aspect: number,
		projectionKind: number,
		flags: number,
	): void {
		command_buffer_set_camera_matrices_col_major(
			this.inner,
			entity.inner,
			Array.from(viewColMajor),
			Array.from(projColMajor),
			near,
			far,
			aspect,
			projectionKind,
			flags,
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

export type DirectSystemCallback = (world: World, ctx: SystemContext) => void;

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

	static newDirect(
		name: string,
		phase: PhaseKey,
		reads: ComponentTypeId[],
		writes: ComponentTypeId[],
		run: DirectSystemCallback,
	): System {
		return new System(
			system_new_direct(
				name,
				phase.inner,
				reads.map((component) => component.inner),
				writes.map((component) => component.inner),
				(world, ctx) => run(new World(world), new SystemContext(ctx)),
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

export class SystemPlanSystem {
	readonly inner: MoonSystemPlanSystem;

	constructor(inner: MoonSystemPlanSystem) {
		this.inner = inner;
	}

	runnerIndex(): number {
		return system_plan_system_runner_index(this.inner);
	}

	batchIndex(): number {
		return system_plan_system_batch_index(this.inner);
	}

	name(): string {
		return system_plan_system_name(this.inner);
	}

	phase(): PhaseKey {
		return new PhaseKey(system_plan_system_phase(this.inner));
	}

	reads(): ComponentTypeId[] {
		return system_plan_system_reads(this.inner).map(
			(component) => new ComponentTypeId(component),
		);
	}

	writes(): ComponentTypeId[] {
		return system_plan_system_writes(this.inner).map(
			(component) => new ComponentTypeId(component),
		);
	}

	structuralWrite(): boolean {
		return moonBool(system_plan_system_structural_write(this.inner));
	}
}

export class SystemPlanBatch {
	readonly inner: MoonSystemPlanBatch;

	constructor(inner: MoonSystemPlanBatch) {
		this.inner = inner;
	}

	index(): number {
		return system_plan_batch_index(this.inner);
	}

	systems(): SystemPlanSystem[] {
		return system_plan_batch_systems(this.inner).map(
			(system) => new SystemPlanSystem(system),
		);
	}
}

export class SystemPhasePlan {
	readonly inner: MoonSystemPhasePlan;

	constructor(inner: MoonSystemPhasePlan) {
		this.inner = inner;
	}

	phase(): PhaseKey {
		return new PhaseKey(system_phase_plan_phase(this.inner));
	}

	systemCount(): number {
		return system_phase_plan_system_count(this.inner);
	}

	batchCount(): number {
		return system_phase_plan_batches(this.inner).length;
	}

	batches(): SystemPlanBatch[] {
		return system_phase_plan_batches(this.inner).map(
			(batch) => new SystemPlanBatch(batch),
		);
	}
}

export class CommandBufferCommandFailure {
	readonly inner: MoonCommandBufferCommandFailure;

	constructor(inner: MoonCommandBufferCommandFailure) {
		this.inner = inner;
	}

	commandIndex(): number {
		return command_buffer_command_failure_command_index(this.inner);
	}

	commandKind(): string {
		return command_buffer_command_failure_command_kind(this.inner);
	}

	reason(): string {
		return command_buffer_command_failure_reason(this.inner);
	}

	entity(): EntityId {
		return new EntityId(command_buffer_command_failure_entity(this.inner));
	}

	component(): ComponentTypeId {
		return new ComponentTypeId(command_buffer_command_failure_component(this.inner));
	}
}

export class SystemRunSystemReport {
	readonly inner: MoonSystemRunSystemReport;

	constructor(inner: MoonSystemRunSystemReport) {
		this.inner = inner;
	}

	runnerIndex(): number {
		return system_run_system_report_runner_index(this.inner);
	}

	batchIndex(): number {
		return system_run_system_report_batch_index(this.inner);
	}

	name(): string {
		return system_run_system_report_name(this.inner);
	}

	queuedCommandCount(): number {
		return system_run_system_report_queued_command_count(this.inner);
	}

	appliedCommandCount(): number {
		return system_run_system_report_applied_command_count(this.inner);
	}

	failedCommandCount(): number {
		return system_run_system_report_failed_command_count(this.inner);
	}

	failures(): CommandBufferCommandFailure[] {
		return system_run_system_report_failures(this.inner).map(
			(failure) => new CommandBufferCommandFailure(failure),
		);
	}
}

export class SystemRunBatchReport {
	readonly inner: MoonSystemRunBatchReport;

	constructor(inner: MoonSystemRunBatchReport) {
		this.inner = inner;
	}

	index(): number {
		return system_run_batch_report_index(this.inner);
	}

	ok(): boolean {
		return moonBool(system_run_batch_report_ok(this.inner));
	}

	systemCount(): number {
		return system_run_batch_report_system_count(this.inner);
	}

	queuedCommandCount(): number {
		return system_run_batch_report_queued_command_count(this.inner);
	}

	appliedCommandCount(): number {
		return system_run_batch_report_applied_command_count(this.inner);
	}

	failedCommandCount(): number {
		return system_run_batch_report_failed_command_count(this.inner);
	}

	systems(): SystemRunSystemReport[] {
		return system_run_batch_report_systems(this.inner).map(
			(system) => new SystemRunSystemReport(system),
		);
	}
}

export class SystemRunReport {
	readonly inner: MoonSystemRunReport;

	constructor(inner: MoonSystemRunReport) {
		this.inner = inner;
	}

	phase(): PhaseKey {
		return new PhaseKey(system_run_report_phase(this.inner));
	}

	ok(): boolean {
		return moonBool(system_run_report_ok(this.inner));
	}

	batchCount(): number {
		return system_run_report_batch_count(this.inner);
	}

	systemCount(): number {
		return system_run_report_system_count(this.inner);
	}

	queuedCommandCount(): number {
		return system_run_report_queued_command_count(this.inner);
	}

	appliedCommandCount(): number {
		return system_run_report_applied_command_count(this.inner);
	}

	failedCommandCount(): number {
		return system_run_report_failed_command_count(this.inner);
	}

	batches(): SystemRunBatchReport[] {
		return system_run_report_batches(this.inner).map(
			(batch) => new SystemRunBatchReport(batch),
		);
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

	planPhase(phase: PhaseKey): SystemPhasePlan {
		return new SystemPhasePlan(system_runner_plan_phase(this.inner, phase.inner));
	}

	runPhase(world: World, ctx: SystemContext, phase: PhaseKey): boolean {
		return moonBool(
			system_runner_run_phase(this.inner, world.inner, ctx.inner, phase.inner),
		);
	}

	runPhaseReport(world: World, ctx: SystemContext, phase: PhaseKey): SystemRunReport {
		return new SystemRunReport(
			system_runner_run_phase_report(
				this.inner,
				world.inner,
				ctx.inner,
				phase.inner,
			),
		);
	}
}

export function createTransformPropagationSystem(
	world: World,
	phase: PhaseKey,
): System {
	return new System(transform_propagation_system(world.inner, phase.inner));
}

export function createOrbitCameraTransformCommandSystem(
	world: World,
	phase: PhaseKey,
	orbitComponent: ComponentTypeId,
	homeComponent: ComponentTypeId,
): System {
	return new System(
		orbit_camera_transform_command_system(
			world.inner,
			phase.inner,
			orbitComponent.inner,
			homeComponent.inner,
		),
	);
}

export function createCameraBlobSyncCommandSystem(
	world: World,
	phase: PhaseKey,
	lensComponent: ComponentTypeId,
): System {
	return new System(
		camera_blob_sync_command_system(
			world.inner,
			phase.inner,
			lensComponent.inner,
		),
	);
}

export function createOrbitCameraBlobSyncCommandSystem(
	world: World,
	phase: PhaseKey,
	orbitComponent: ComponentTypeId,
	lensComponent: ComponentTypeId,
): System {
	return new System(
		orbit_camera_blob_sync_command_system(
			world.inner,
			phase.inner,
			orbitComponent.inner,
			lensComponent.inner,
		),
	);
}
