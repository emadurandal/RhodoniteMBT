// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import type {
	MoonPreparedQuery,
	MoonQuery,
	MoonQueryPlan,
	MoonQueryPlanArchetype,
	MoonQueryRow,
	MoonRawPreparedQuery,
	MoonRawQuery,
	MoonRawQueryArchetype,
	MoonRawQueryRow,
	MoonWorld,
	MoonWorldHistory,
} from "@moon/rhodonite_core/ecs/js_bridge";
import {
	prepared_query_for_each,
	prepared_query_is_stale,
	prepared_query_plan,
	prepared_query_refresh,
	query_for_each,
	query_new,
	query_plan,
	query_plan_archetype_index,
	query_plan_archetype_row_count,
	query_plan_archetype_version,
	query_plan_archetypes,
	query_plan_candidate_archetype_count,
	query_plan_matched_archetype_count,
	query_plan_matched_row_count,
	query_plan_required_components,
	query_plan_stale,
	query_prepare,
	query_required_components,
	query_row_entity,
	query_row_has,
	query_row_read,
	query_row_write,
	query_row_write_tracked,
	raw_prepared_query_for_each,
	raw_prepared_query_for_each_archetype,
	raw_prepared_query_is_stale,
	raw_prepared_query_plan,
	raw_prepared_query_refresh,
	raw_query_archetype_component_stride,
	raw_query_archetype_entity,
	raw_query_archetype_has,
	raw_query_archetype_length,
	raw_query_archetype_read_column,
	raw_query_archetype_write_column,
	raw_query_archetype_write_column_rows_tracked,
	raw_query_archetype_write_column_tracked,
	raw_query_for_each,
	raw_query_for_each_archetype,
	raw_query_new,
	raw_query_plan,
	raw_query_prepare,
	raw_query_row_entity,
	raw_query_row_has,
	raw_query_row_read_view,
	raw_query_row_write_view,
	raw_query_row_write_tracked,
} from "@moon/rhodonite_core/ecs/js_bridge";
import { ComponentTypeId, EntityId } from "./types.ts";
import { ByteView, byteView, moonBool } from "./views.ts";

export class Query {
	readonly inner: MoonQuery;

	constructor(inner: MoonQuery) {
		this.inner = inner;
	}

	static new(required: ComponentTypeId[]): Query {
		return new Query(query_new(required.map((component) => component.inner)));
	}

	requiredComponents(): ComponentTypeId[] {
		return query_required_components(this.inner).map(
			(component) => new ComponentTypeId(component),
		);
	}

	forEach(world: { readonly inner: MoonWorld }, f: (row: QueryRow) => void): void {
		query_for_each(this.inner, world.inner, (row) => f(new QueryRow(row)));
	}

	prepare(world: { readonly inner: MoonWorld }): PreparedQuery {
		return new PreparedQuery(query_prepare(this.inner, world.inner));
	}

	plan(world: { readonly inner: MoonWorld }): QueryPlan {
		return new QueryPlan(query_plan(this.inner, world.inner));
	}
}

export class PreparedQuery {
	readonly inner: MoonPreparedQuery;

	constructor(inner: MoonPreparedQuery) {
		this.inner = inner;
	}

	forEach(world: { readonly inner: MoonWorld }, f: (row: QueryRow) => void): void {
		prepared_query_for_each(this.inner, world.inner, (row) =>
			f(new QueryRow(row)),
		);
	}

	plan(world: { readonly inner: MoonWorld }): QueryPlan {
		return new QueryPlan(prepared_query_plan(this.inner, world.inner));
	}

	isStale(world: { readonly inner: MoonWorld }): boolean {
		return moonBool(prepared_query_is_stale(this.inner, world.inner));
	}

	refresh(world: { readonly inner: MoonWorld }): PreparedQuery {
		return new PreparedQuery(prepared_query_refresh(this.inner, world.inner));
	}
}

export class QueryPlanArchetype {
	readonly inner: MoonQueryPlanArchetype;

	constructor(inner: MoonQueryPlanArchetype) {
		this.inner = inner;
	}

	index(): number {
		return query_plan_archetype_index(this.inner);
	}

	rowCount(): number {
		return query_plan_archetype_row_count(this.inner);
	}
}

export class QueryPlan {
	readonly inner: MoonQueryPlan;

	constructor(inner: MoonQueryPlan) {
		this.inner = inner;
	}

	requiredComponents(): ComponentTypeId[] {
		return query_plan_required_components(this.inner).map(
			(component) => new ComponentTypeId(component),
		);
	}

	archetypeVersion(): number {
		return query_plan_archetype_version(this.inner);
	}

	candidateArchetypeCount(): number {
		return query_plan_candidate_archetype_count(this.inner);
	}

	matchedArchetypeCount(): number {
		return query_plan_matched_archetype_count(this.inner);
	}

	matchedRowCount(): number {
		return query_plan_matched_row_count(this.inner);
	}

	stale(): boolean {
		return moonBool(query_plan_stale(this.inner));
	}

	archetypes(): QueryPlanArchetype[] {
		return query_plan_archetypes(this.inner).map(
			(archetype) => new QueryPlanArchetype(archetype),
		);
	}
}

export class RawQuery {
	readonly inner: MoonRawQuery;

	constructor(inner: MoonRawQuery) {
		this.inner = inner;
	}

	static new(required: ComponentTypeId[]): RawQuery {
		return new RawQuery(raw_query_new(required.map((component) => component.inner)));
	}

	forEach(world: { readonly inner: MoonWorld }, f: (row: RawQueryRow) => void): void {
		raw_query_for_each(this.inner, world.inner, (row) => f(new RawQueryRow(row)));
	}

	prepare(world: { readonly inner: MoonWorld }): RawPreparedQuery {
		return new RawPreparedQuery(raw_query_prepare(this.inner, world.inner));
	}

	plan(world: { readonly inner: MoonWorld }): QueryPlan {
		return new QueryPlan(raw_query_plan(this.inner, world.inner));
	}

	forEachArchetype(
		world: { readonly inner: MoonWorld },
		f: (archetype: RawQueryArchetype) => void,
	): void {
		raw_query_for_each_archetype(this.inner, world.inner, (archetype) =>
			f(new RawQueryArchetype(archetype)),
		);
	}
}

export class RawPreparedQuery {
	readonly inner: MoonRawPreparedQuery;

	constructor(inner: MoonRawPreparedQuery) {
		this.inner = inner;
	}

	forEach(world: { readonly inner: MoonWorld }, f: (row: RawQueryRow) => void): void {
		raw_prepared_query_for_each(this.inner, world.inner, (row) =>
			f(new RawQueryRow(row)),
		);
	}

	plan(world: { readonly inner: MoonWorld }): QueryPlan {
		return new QueryPlan(raw_prepared_query_plan(this.inner, world.inner));
	}

	isStale(world: { readonly inner: MoonWorld }): boolean {
		return moonBool(raw_prepared_query_is_stale(this.inner, world.inner));
	}

	refresh(world: { readonly inner: MoonWorld }): RawPreparedQuery {
		return new RawPreparedQuery(raw_prepared_query_refresh(this.inner, world.inner));
	}

	forEachArchetype(
		world: { readonly inner: MoonWorld },
		f: (archetype: RawQueryArchetype) => void,
	): void {
		raw_prepared_query_for_each_archetype(this.inner, world.inner, (archetype) =>
			f(new RawQueryArchetype(archetype)),
		);
	}
}

export class QueryRow {
	readonly inner: MoonQueryRow;

	constructor(inner: MoonQueryRow) {
		this.inner = inner;
	}

	entity(): EntityId {
		return new EntityId(query_row_entity(this.inner));
	}

	has(component: ComponentTypeId): boolean {
		return moonBool(query_row_has(this.inner, component.inner));
	}

	read(component: ComponentTypeId, f: (bytes: ByteView) => void): void {
		query_row_read(this.inner, component.inner, (bytes) => f(byteView(bytes)));
	}

	write(component: ComponentTypeId, f: (bytes: ByteView) => void): void {
		query_row_write(this.inner, component.inner, (bytes) => f(byteView(bytes)));
	}

	writeTracked(
		history: { readonly inner: MoonWorldHistory },
		component: ComponentTypeId,
		f: (bytes: ByteView) => void,
	): boolean {
		return moonBool(
			query_row_write_tracked(this.inner, history.inner, component.inner, (bytes) =>
				f(byteView(bytes)),
			),
		);
	}
}

export class RawQueryRow {
	readonly inner: MoonRawQueryRow;

	constructor(inner: MoonRawQueryRow) {
		this.inner = inner;
	}

	entity(): EntityId {
		return new EntityId(raw_query_row_entity(this.inner));
	}

	has(component: ComponentTypeId): boolean {
		return moonBool(raw_query_row_has(this.inner, component.inner));
	}

	readView(component: ComponentTypeId): ByteView {
		return byteView(raw_query_row_read_view(this.inner, component.inner));
	}

	writeView(component: ComponentTypeId): ByteView {
		return byteView(raw_query_row_write_view(this.inner, component.inner));
	}

	writeTracked(
		history: { readonly inner: MoonWorldHistory },
		component: ComponentTypeId,
		f: (bytes: ByteView) => void,
	): boolean {
		return moonBool(
			raw_query_row_write_tracked(this.inner, history.inner, component.inner, (bytes) =>
				f(byteView(bytes)),
			),
		);
	}
}

export class RawQueryArchetype {
	readonly inner: MoonRawQueryArchetype;

	constructor(inner: MoonRawQueryArchetype) {
		this.inner = inner;
	}

	length(): number {
		return raw_query_archetype_length(this.inner);
	}

	entity(row: number): EntityId {
		return new EntityId(raw_query_archetype_entity(this.inner, row));
	}

	has(component: ComponentTypeId): boolean {
		return moonBool(raw_query_archetype_has(this.inner, component.inner));
	}

	componentStride(component: ComponentTypeId): number {
		return raw_query_archetype_component_stride(this.inner, component.inner);
	}

	readColumn(component: ComponentTypeId): ByteView {
		return byteView(raw_query_archetype_read_column(this.inner, component.inner));
	}

	writeColumn(component: ComponentTypeId): ByteView {
		return byteView(raw_query_archetype_write_column(this.inner, component.inner));
	}

	writeColumnTracked(
		history: { readonly inner: MoonWorldHistory },
		component: ComponentTypeId,
		f: (bytes: ByteView) => void,
	): boolean {
		return moonBool(
			raw_query_archetype_write_column_tracked(
				this.inner,
				history.inner,
				component.inner,
				(bytes) => f(byteView(bytes)),
			),
		);
	}

	writeColumnRowsTracked(
		history: { readonly inner: MoonWorldHistory },
		component: ComponentTypeId,
		rows: number[],
		f: (row: number, bytes: ByteView) => void,
	): boolean {
		return moonBool(
			raw_query_archetype_write_column_rows_tracked(
				this.inner,
				history.inner,
				component.inner,
				rows,
				(row, bytes) => f(row, byteView(bytes)),
			),
		);
	}
}
