import type {
	MoonPreparedQuery,
	MoonQuery,
	MoonQueryArchetype,
	MoonQueryRow,
	MoonWorld,
} from "@moon/rhodonite_core/ecs/js_bridge";
import {
	prepared_query_for_each_archetype,
	query_archetype_component_stride,
	query_archetype_entity,
	query_archetype_has,
	query_archetype_length,
	query_archetype_read_column,
	query_archetype_write_column,
	query_for_each,
	query_for_each_archetype,
	query_new,
	query_prepare,
	query_required_components,
	query_row_entity,
	query_row_has,
	query_row_read_view,
	query_row_write_view,
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

	forEachArchetype(
		world: { readonly inner: MoonWorld },
		f: (archetype: QueryArchetype) => void,
	): void {
		query_for_each_archetype(this.inner, world.inner, (archetype) =>
			f(new QueryArchetype(archetype)),
		);
	}
}

export class PreparedQuery {
	readonly inner: MoonPreparedQuery;

	constructor(inner: MoonPreparedQuery) {
		this.inner = inner;
	}

	forEachArchetype(
		world: { readonly inner: MoonWorld },
		f: (archetype: QueryArchetype) => void,
	): void {
		prepared_query_for_each_archetype(this.inner, world.inner, (archetype) =>
			f(new QueryArchetype(archetype)),
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

	readView(component: ComponentTypeId): ByteView {
		return byteView(query_row_read_view(this.inner, component.inner));
	}

	writeView(component: ComponentTypeId): ByteView {
		return byteView(query_row_write_view(this.inner, component.inner));
	}
}

export class QueryArchetype {
	readonly inner: MoonQueryArchetype;

	constructor(inner: MoonQueryArchetype) {
		this.inner = inner;
	}

	length(): number {
		return query_archetype_length(this.inner);
	}

	entity(row: number): EntityId {
		return new EntityId(query_archetype_entity(this.inner, row));
	}

	has(component: ComponentTypeId): boolean {
		return moonBool(query_archetype_has(this.inner, component.inner));
	}

	componentStride(component: ComponentTypeId): number {
		return query_archetype_component_stride(this.inner, component.inner);
	}

	readColumn(component: ComponentTypeId): ByteView {
		return byteView(query_archetype_read_column(this.inner, component.inner));
	}

	writeColumn(component: ComponentTypeId): ByteView {
		return byteView(query_archetype_write_column(this.inner, component.inner));
	}
}
