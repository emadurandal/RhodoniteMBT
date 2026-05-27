// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import {
	auditedClassByName,
	auditedMoonBitSurfaces,
	auditedSurfaces,
	bridgeParityEntries,
	cameraControlParityEntries,
	ledgerEntries,
	moonBitOnlyTrackedEntries,
	prototypeMethods,
	wrapperSourceUrls,
	assertUniqueLabels,
	type WrapperSourceName,
} from "./test-support/history-mutation-coverage-ledger.ts";
import {
	bridgeImports,
	declaredBridgeFunctions,
	exportedFunctions,
	moonBitPublicMethodsByReceiver,
	moonBitTopLevelFunctions,
	publicFunctionNames,
} from "./test-support/history-mutation-coverage-parsers.ts";

function readSources(urls: readonly URL[]): string {
	return urls.map((url) => readFileSync(url, { encoding: "utf8" })).join("\n");
}

describe("ECS TypeScript wrapper: history mutation coverage audit", () => {
	it("classifies every audited public prototype method", () => {
		for (const surface of auditedSurfaces) {
			const actual = prototypeMethods(surface.ctor);
			const ledger = ledgerEntries(surface);
			const expected = [...ledger.keys()].sort();

			expect(actual, `${surface.name} public method audit drifted`).toEqual(
				expected,
			);
			expect(
				expected.length,
				`${surface.name} must keep an explicit history coverage classification`,
			).toBeGreaterThan(0);
		}
	});

	it("classifies every audited MoonBit public method", () => {
		const mbti = readFileSync(new URL("../pkg.generated.mbti", import.meta.url), {
			encoding: "utf8",
		});
		const publicMethods = moonBitPublicMethodsByReceiver(
			mbti,
			auditedMoonBitSurfaces.map((surface) => surface.name),
		);

		for (const surface of auditedMoonBitSurfaces) {
			const actual = publicMethods.get(surface.name) ?? [];
			const ledger = ledgerEntries(surface);
			const expected = [...ledger.keys()].sort();

			expect(actual, `${surface.name} MoonBit public method audit drifted`).toEqual(
				expected,
			);
			expect(
				expected.length,
				`${surface.name} must keep an explicit MoonBit history coverage classification`,
			).toBeGreaterThan(0);
		}
	});

	it("keeps tracked bridge declarations and wrapper methods in parity", () => {
		assertUniqueLabels(
			bridgeParityEntries.map((entry) => entry.label),
			"bridge parity entry",
		);
		const bridgeMbt = readSources([
			new URL("../js_bridge/bridge.mbt", import.meta.url),
			new URL("../js_bridge/bridge_part2.mbt", import.meta.url),
			new URL("../js_bridge/bridge_part3.mbt", import.meta.url),
			new URL("../js_bridge/bridge_part4.mbt", import.meta.url),
		]);
		const bridgeDts = readSources([
			new URL("./ecs-bridge.d.ts", import.meta.url),
			new URL("./ecs-bridge-history.d.ts", import.meta.url),
		]);
		const mbti = readFileSync(new URL("../pkg.generated.mbti", import.meta.url), {
			encoding: "utf8",
		});
		const bridgeMbtFunctions = publicFunctionNames(bridgeMbt);
		const bridgeDtsFunctions = declaredBridgeFunctions(bridgeDts);
		const publicMethods = moonBitPublicMethodsByReceiver(
			mbti,
			auditedMoonBitSurfaces.map((surface) => surface.name),
		);
		const wrapperImportsBySource = new Map<WrapperSourceName, Set<string>>();
		for (const [name, url] of Object.entries(wrapperSourceUrls) as Array<
			[WrapperSourceName, URL]
		>) {
			wrapperImportsBySource.set(
				name,
				bridgeImports(readFileSync(url, { encoding: "utf8" })),
			);
		}

		for (const entry of bridgeParityEntries) {
			expect(
				bridgeMbtFunctions.has(entry.bridge),
				`${entry.label} must have a MoonBit js_bridge function ${entry.bridge}`,
			).toBe(true);
			expect(
				bridgeDtsFunctions.has(entry.bridge),
				`${entry.label} must declare ${entry.bridge} in ecs-bridge.d.ts`,
			).toBe(true);
			expect(
				wrapperImportsBySource.get(entry.wrapperSource)?.has(entry.bridge),
				`${entry.label} must import ${entry.bridge} in ${entry.wrapperSource}`,
			).toBe(true);
			expect(
				prototypeMethods(auditedClassByName[entry.surface]).includes(
					entry.tsMethod,
				),
				`${entry.label} must expose ${entry.surface}.${entry.tsMethod}`,
			).toBe(true);
			if (
				entry.moonBitReceiver !== undefined &&
				entry.moonBitMethod !== undefined
			) {
				expect(
					publicMethods.get(entry.moonBitReceiver)?.includes(entry.moonBitMethod),
					`${entry.label} must match MoonBit public method ${entry.moonBitReceiver}::${entry.moonBitMethod}`,
				).toBe(true);
			}
		}
	});

	it("keeps tracked camera-control TypeScript mirrors in parity", () => {
		assertUniqueLabels(
			cameraControlParityEntries.map((entry) => entry.moonBitFunction),
			"camera-control parity entry",
		);
		const mbti = readFileSync(new URL("../pkg.generated.mbti", import.meta.url), {
			encoding: "utf8",
		});
		const cameraControlSource = readSources([
			new URL("./camera-control-core.ts", import.meta.url),
			new URL("./camera-control-projection.ts", import.meta.url),
			new URL("./camera-control-sync.ts", import.meta.url),
		]);
		const moonBitFunctions = moonBitTopLevelFunctions(mbti);
		const tsExports = exportedFunctions(cameraControlSource);

		for (const entry of cameraControlParityEntries) {
			expect(
				moonBitFunctions.has(entry.moonBitFunction),
				`camera-control must keep MoonBit helper ${entry.moonBitFunction}`,
			).toBe(true);
			expect(
				tsExports.has(entry.tsExport),
				`camera-control must expose TypeScript mirror ${entry.tsExport}`,
			).toBe(true);
		}
	});

	it("keeps MoonBit-only tracked helpers explicit", () => {
		assertUniqueLabels(
			moonBitOnlyTrackedEntries.map((entry) => entry.label),
			"MoonBit-only tracked entry",
		);
		const mbti = readFileSync(new URL("../pkg.generated.mbti", import.meta.url), {
			encoding: "utf8",
		});
		const bridgeDts = readSources([
			new URL("./ecs-bridge.d.ts", import.meta.url),
			new URL("./ecs-bridge-history.d.ts", import.meta.url),
		]);
		const publicMethods = moonBitPublicMethodsByReceiver(
			mbti,
			auditedMoonBitSurfaces.map((surface) => surface.name),
		);
		const bridgeDtsFunctions = declaredBridgeFunctions(bridgeDts);

		for (const entry of moonBitOnlyTrackedEntries) {
			expect(
				publicMethods.get(entry.receiver)?.includes(entry.method),
				`${entry.label} must remain classified as a MoonBit tracked helper`,
			).toBe(true);
			expect(
				bridgeDtsFunctions.has(entry.reservedBridge),
				`${entry.label} now has TS bridge ${entry.reservedBridge}; move it into bridge parity coverage`,
			).toBe(false);
		}
	});
});
