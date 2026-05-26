// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import type {
	MoonPreparedQuery,
	MoonQuery,
	MoonQueryCache,
	MoonQueryPlan,
	MoonQueryPlanArchetype,
	MoonQueryRow,
	MoonRawPreparedQuery,
	MoonRawQuery,
	MoonRawQueryCache,
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
	query_component_index,
	query_cache_component_index,
	query_cache_for_each,
	query_cache_new,
	query_cache_plan,
	query_cache_refresh,
	query_cache_required_components,
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
	query_row_has_at,
	query_row_read,
	query_row_read_at,
	query_row_write,
	query_row_write_at,
	query_row_write_tracked,
	query_row_write_tracked_at,
	raw_prepared_query_for_each,
	raw_prepared_query_for_each_archetype,
	raw_prepared_query_is_stale,
	raw_prepared_query_plan,
	raw_prepared_query_refresh,
	raw_query_cache_for_each,
	raw_query_cache_for_each_archetype,
	raw_query_cache_new,
	raw_query_cache_plan,
	raw_query_cache_refresh,
	raw_query_cache_required_components,
	raw_query_cache_component_index,
	raw_query_archetype_component_stride,
	raw_query_archetype_component_stride_at,
	raw_query_archetype_entity,
	raw_query_archetype_has,
	raw_query_archetype_has_at,
	raw_query_archetype_length,
	raw_query_archetype_read_column,
	raw_query_archetype_read_column_at,
	raw_query_archetype_write_column,
	raw_query_archetype_write_column_at,
	raw_query_archetype_write_column_rows_tracked,
	raw_query_archetype_write_column_rows_tracked_at,
	raw_query_archetype_write_column_tracked,
	raw_query_archetype_write_column_tracked_at,
	raw_query_component_index,
	raw_query_for_each,
	raw_query_for_each_archetype,
	raw_query_new,
	raw_query_plan,
	raw_query_prepare,
	raw_query_row_entity,
	raw_query_row_has,
	raw_query_row_has_at,
	raw_query_row_read_view,
	raw_query_row_read_view_at,
	raw_query_row_write_view,
	raw_query_row_write_view_at,
	raw_query_row_write_tracked,
	raw_query_row_write_tracked_at,
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

	componentIndex(component: ComponentTypeId): number {
		return query_component_index(this.inner, component.inner);
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

export class QueryCache {
	readonly inner: MoonQueryCache;

	constructor(inner: MoonQueryCache) {
		this.inner = inner;
	}

	static new(required: ComponentTypeId[]): QueryCache {
		return new QueryCache(
			query_cache_new(required.map((component) => component.inner)),
		);
	}

	requiredComponents(): ComponentTypeId[] {
		return query_cache_required_components(this.inner).map(
			(component) => new ComponentTypeId(component),
		);
	}

	componentIndex(component: ComponentTypeId): number {
		return query_cache_component_index(this.inner, component.inner);
	}

	plan(world: { readonly inner: MoonWorld }): QueryPlan {
		return new QueryPlan(query_cache_plan(this.inner, world.inner));
	}

	refresh(world: { readonly inner: MoonWorld }): void {
		query_cache_refresh(this.inner, world.inner);
	}

	forEach(world: { readonly inner: MoonWorld }, f: (row: QueryRow) => void): void {
		query_cache_for_each(this.inner, world.inner, (row) =>
			f(new QueryRow(row)),
		);
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

	componentIndex(component: ComponentTypeId): number {
		return raw_query_component_index(this.inner, component.inner);
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

export class RawQueryCache {
	readonly inner: MoonRawQueryCache;

	constructor(inner: MoonRawQueryCache) {
		this.inner = inner;
	}

	static new(required: ComponentTypeId[]): RawQueryCache {
		return new RawQueryCache(
			raw_query_cache_new(required.map((component) => component.inner)),
		);
	}

	requiredComponents(): ComponentTypeId[] {
		return raw_query_cache_required_components(this.inner).map(
			(component) => new ComponentTypeId(component),
		);
	}

	componentIndex(component: ComponentTypeId): number {
		return raw_query_cache_component_index(this.inner, component.inner);
	}

	plan(world: { readonly inner: MoonWorld }): QueryPlan {
		return new QueryPlan(raw_query_cache_plan(this.inner, world.inner));
	}

	refresh(world: { readonly inner: MoonWorld }): void {
		raw_query_cache_refresh(this.inner, world.inner);
	}

	forEach(world: { readonly inner: MoonWorld }, f: (row: RawQueryRow) => void): void {
		raw_query_cache_for_each(this.inner, world.inner, (row) =>
			f(new RawQueryRow(row)),
		);
	}

	forEachArchetype(
		world: { readonly inner: MoonWorld },
		f: (archetype: RawQueryArchetype) => void,
	): void {
		raw_query_cache_for_each_archetype(this.inner, world.inner, (archetype) =>
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

	hasAt(index: number): boolean {
		return moonBool(query_row_has_at(this.inner, index));
	}

	read(component: ComponentTypeId, f: (bytes: ByteView) => void): void {
		query_row_read(this.inner, component.inner, (bytes) => f(byteView(bytes)));
	}

	readAt(index: number, f: (bytes: ByteView) => void): void {
		query_row_read_at(this.inner, index, (bytes) => f(byteView(bytes)));
	}

	write(component: ComponentTypeId, f: (bytes: ByteView) => void): void {
		query_row_write(this.inner, component.inner, (bytes) => f(byteView(bytes)));
	}

	writeAt(index: number, f: (bytes: ByteView) => void): void {
		query_row_write_at(this.inner, index, (bytes) => f(byteView(bytes)));
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

	writeTrackedAt(
		history: { readonly inner: MoonWorldHistory },
		index: number,
		f: (bytes: ByteView) => void,
	): boolean {
		return moonBool(
			query_row_write_tracked_at(this.inner, history.inner, index, (bytes) =>
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

	hasAt(index: number): boolean {
		return moonBool(raw_query_row_has_at(this.inner, index));
	}

	readView(component: ComponentTypeId): ByteView {
		return byteView(raw_query_row_read_view(this.inner, component.inner));
	}

	readViewAt(index: number): ByteView {
		return byteView(raw_query_row_read_view_at(this.inner, index));
	}

	writeView(component: ComponentTypeId): ByteView {
		return byteView(raw_query_row_write_view(this.inner, component.inner));
	}

	writeViewAt(index: number): ByteView {
		return byteView(raw_query_row_write_view_at(this.inner, index));
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

	writeTrackedAt(
		history: { readonly inner: MoonWorldHistory },
		index: number,
		f: (bytes: ByteView) => void,
	): boolean {
		return moonBool(
			raw_query_row_write_tracked_at(this.inner, history.inner, index, (bytes) =>
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

	hasAt(index: number): boolean {
		return moonBool(raw_query_archetype_has_at(this.inner, index));
	}

	componentStride(component: ComponentTypeId): number {
		return raw_query_archetype_component_stride(this.inner, component.inner);
	}

	componentStrideAt(index: number): number {
		return raw_query_archetype_component_stride_at(this.inner, index);
	}

	readColumn(component: ComponentTypeId): ByteView {
		return byteView(raw_query_archetype_read_column(this.inner, component.inner));
	}

	readColumnAt(index: number): ByteView {
		return byteView(raw_query_archetype_read_column_at(this.inner, index));
	}

	writeColumn(component: ComponentTypeId): ByteView {
		return byteView(raw_query_archetype_write_column(this.inner, component.inner));
	}

	writeColumnAt(index: number): ByteView {
		return byteView(raw_query_archetype_write_column_at(this.inner, index));
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

	writeColumnTrackedAt(
		history: { readonly inner: MoonWorldHistory },
		index: number,
		f: (bytes: ByteView) => void,
	): boolean {
		return moonBool(
			raw_query_archetype_write_column_tracked_at(
				this.inner,
				history.inner,
				index,
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

	writeColumnRowsTrackedAt(
		history: { readonly inner: MoonWorldHistory },
		index: number,
		rows: number[],
		f: (row: number, bytes: ByteView) => void,
	): boolean {
		return moonBool(
			raw_query_archetype_write_column_rows_tracked_at(
				this.inner,
				history.inner,
				index,
				rows,
				(row, bytes) => f(row, byteView(bytes)),
			),
		);
	}
}
