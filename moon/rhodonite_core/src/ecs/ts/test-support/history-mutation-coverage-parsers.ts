// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

export function moonBitPublicMethodsByReceiver(
	mbti: string,
	receivers: readonly string[],
): Map<string, string[]> {
	const receiverSet = new Set<string>(receivers);
	const methods = new Map<string, string[]>(
		receivers.map((receiver) => [receiver, []]),
	);
	const pattern = /^pub fn ([A-Za-z][A-Za-z0-9_]*)::([A-Za-z_][A-Za-z0-9_]*)\(/gm;
	for (const match of mbti.matchAll(pattern)) {
		const receiver = match[1];
		const method = match[2];
		if (method !== undefined && receiverSet.has(receiver)) {
			methods.get(receiver)?.push(method);
		}
	}
	for (const values of methods.values()) {
		values.sort();
	}
	return methods;
}

export function publicFunctionNames(source: string): Set<string> {
	const functions = new Set<string>();
	const pattern = /^pub fn ([A-Za-z_][A-Za-z0-9_]*)\(/gm;
	for (const match of source.matchAll(pattern)) {
		if (match[1] !== undefined) {
			functions.add(match[1]);
		}
	}
	return functions;
}

export function declaredBridgeFunctions(dts: string): Set<string> {
	const functions = new Set<string>();
	const pattern = /^\s*export function ([A-Za-z_][A-Za-z0-9_]*)\(/gm;
	for (const match of dts.matchAll(pattern)) {
		if (match[1] !== undefined) {
			functions.add(match[1]);
		}
	}
	return functions;
}

export function bridgeImports(source: string): Set<string> {
	const imports = new Set<string>();
	const pattern =
		/import\s*{(?<names>[\s\S]*?)}\s*from\s*"@moon\/rhodonite_core\/ecs\/js_bridge";/g;
	for (const match of source.matchAll(pattern)) {
		const names = match.groups?.names;
		if (names === undefined) {
			continue;
		}
		for (const raw of names.split(",")) {
			const name = raw.trim().split(/\s+as\s+/u)[0]?.trim();
			if (name !== undefined && name.length > 0) {
				imports.add(name);
			}
		}
	}
	const namespacePattern =
		/import\s+\*\s+as\s+(?<name>[A-Za-z_][A-Za-z0-9_]*)\s+from\s+"@moon\/rhodonite_core\/ecs\/js_bridge";/g;
	for (const match of source.matchAll(namespacePattern)) {
		const namespace = match.groups?.name;
		if (namespace === undefined) {
			continue;
		}
		const memberPattern = new RegExp(
			`${namespace}\\.([A-Za-z_][A-Za-z0-9_]*)`,
			"g",
		);
		for (const member of source.matchAll(memberPattern)) {
			if (member[1] !== undefined) {
				imports.add(member[1]);
			}
		}
	}
	return imports;
}

export function exportedFunctions(source: string): Set<string> {
	const functions = new Set<string>();
	const pattern = /^export function ([A-Za-z_][A-Za-z0-9_]*)\(/gm;
	for (const match of source.matchAll(pattern)) {
		if (match[1] !== undefined) {
			functions.add(match[1]);
		}
	}
	return functions;
}

export function moonBitTopLevelFunctions(mbti: string): Set<string> {
	const functions = new Set<string>();
	const pattern = /^pub fn ([A-Za-z_][A-Za-z0-9_]*)\(/gm;
	for (const match of mbti.matchAll(pattern)) {
		if (match[1] !== undefined) {
			functions.add(match[1]);
		}
	}
	return functions;
}

