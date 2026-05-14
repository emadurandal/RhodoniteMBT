import type {
	MoonPreparedQuery,
	MoonQuery,
	MoonQueryRow,
	MoonRawPreparedQuery,
	MoonRawQuery,
	MoonRawQueryArchetype,
	MoonRawQueryRow,
	MoonWorld,
} from "@moon/rhodonite_core/ecs/js_bridge";
import {
	prepared_query_for_each,
	query_for_each,
	query_new,
	query_prepare,
	query_required_components,
	query_row_entity,
	query_row_has,
	query_row_read,
	query_row_write,
	raw_prepared_query_for_each,
	raw_prepared_query_for_each_archetype,
	raw_query_archetype_component_stride,
	raw_query_archetype_entity,
	raw_query_archetype_has,
	raw_query_archetype_length,
	raw_query_archetype_read_column,
	raw_query_archetype_write_column,
	raw_query_for_each,
	raw_query_for_each_archetype,
	raw_query_new,
	raw_query_prepare,
	raw_query_row_entity,
	raw_query_row_has,
	raw_query_row_read_view,
	raw_query_row_write_view,
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
}
