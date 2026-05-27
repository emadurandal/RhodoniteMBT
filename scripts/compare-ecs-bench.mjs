// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.dirname(fileURLToPath(new URL("../package.json", import.meta.url)));
const args = process.argv.slice(2);

let baselinePath = path.join(root, "benchmarks/ecs/baseline.jsonl");
let currentPath = "";
let failOnRegression = process.env.RHODONITE_ECS_BENCH_FAIL_ON_REGRESSION === "1";

for (let i = 0; i < args.length; i++) {
	const arg = args[i];
	if (arg === "--baseline") {
		baselinePath = requireValue(arg, args[++i]);
	} else if (arg === "--current") {
		currentPath = requireValue(arg, args[++i]);
	} else if (arg === "--fail-on-regression") {
		failOnRegression = true;
	} else {
		usage(`unknown option '${arg}'`);
	}
}

if (currentPath.length === 0) {
	usage("--current is required");
}

const baseline = readJsonl(baselinePath, "baseline");
const current = readJsonl(currentPath, "current");
const baselineByKey = mapRows(baseline.rows);
const currentByKey = mapRows(current.rows);
const currentScopes = new Set(current.rows.map(scopeFor));

const warnings = [];
const improvements = [];
const stable = [];
const medianRatioThreshold = 1.2;
const minMedianDeltaMs = 0.05;

for (const [key, cur] of currentByKey) {
	const base = baselineByKey.get(key);
	if (!base) {
		warnings.push(`NEW ${describe(cur)} has no baseline row`);
		continue;
	}
	if (cur.checksum !== base.checksum) {
		warnings.push(
			`CHECKSUM ${describe(cur)} baseline=${base.checksum} current=${cur.checksum}`,
		);
		continue;
	}
	const medianDelta = cur.median_ms - base.median_ms;
	const medianRatio = ratio(cur.median_ms, base.median_ms);
	const nsRatio = ratio(cur.ns_per_item, base.ns_per_item);
	const message = `${describe(cur)} median ${formatMs(base.median_ms)} -> ${formatMs(cur.median_ms)} (${formatRatio(medianRatio)}), ns/item ${formatNumber(base.ns_per_item)} -> ${formatNumber(cur.ns_per_item)} (${formatRatio(nsRatio)})`;
	if (medianRatio > medianRatioThreshold && medianDelta >= minMedianDeltaMs) {
		warnings.push(`REGRESSION ${message}`);
	} else if (medianRatio < 0.9 && medianDelta <= -minMedianDeltaMs) {
		improvements.push(`IMPROVED ${message}`);
	} else {
		stable.push(`OK ${message}`);
	}
}

for (const [key, base] of baselineByKey) {
	if (currentScopes.has(scopeFor(base)) && !currentByKey.has(key)) {
		warnings.push(`MISSING ${describe(base)} is present in baseline only`);
	}
}

console.log(
	`ecs_bench_compare: baseline=${path.relative(root, baseline.path)} current=${path.relative(root, current.path)}`,
);
console.log(
	`ecs_bench_compare: ok=${stable.length} improved=${improvements.length} warnings=${warnings.length}`,
);
for (const line of warnings) {
	console.warn(`ecs_bench_compare: WARN ${line}`);
}
for (const line of improvements) {
	console.log(`ecs_bench_compare: ${line}`);
}

if (warnings.length > 0 && failOnRegression) {
	process.exit(1);
}

function requireValue(option, value) {
	if (value === undefined || value.startsWith("--")) {
		usage(`${option} requires a value`);
	}
	return value;
}

function usage(message) {
	console.error(
		`compare-ecs-bench: ${message}\nusage: node scripts/compare-ecs-bench.mjs --current path [--baseline path] [--fail-on-regression]`,
	);
	process.exit(2);
}

function readJsonl(filePath, label) {
	if (!fs.existsSync(filePath)) {
		console.warn(`ecs_bench_compare: WARN ${label} file not found: ${filePath}`);
		return { path: filePath, rows: [] };
	}
	const text = fs.readFileSync(filePath, "utf8");
	const rows = [];
	for (const [index, line] of text.split(/\r?\n/).entries()) {
		if (line.trim().length === 0) continue;
		try {
			rows.push(normalizeRow(JSON.parse(line)));
		} catch (error) {
			throw new Error(`${label} ${filePath}:${index + 1}: ${error.message}`);
		}
	}
	return { path: filePath, rows };
}

function normalizeRow(row) {
	return {
		target: String(row.target ?? "unknown"),
		build_mode: String(row.build_mode ?? "unknown"),
		schema: Number(row.schema),
		case: String(row.case),
		count: Number(row.count),
		runs: Number(row.runs),
		min_ms: Number(row.min_ms),
		median_ms: Number(row.median_ms),
		max_ms: Number(row.max_ms),
		ns_per_item: Number(row.ns_per_item),
		checksum: Number(row.checksum),
	};
}

function mapRows(rows) {
	const map = new Map();
	for (const row of rows) {
		map.set(keyFor(row), row);
	}
	return map;
}

function keyFor(row) {
	return [
		row.target,
		row.build_mode,
		row.schema,
		row.case,
		row.count,
	].join("\t");
}

function scopeFor(row) {
	return [
		row.target,
		row.build_mode,
		row.schema,
		row.count,
	].join("\t");
}

function describe(row) {
	return `${row.target}/${row.build_mode}/schema${row.schema} ${row.case} count=${row.count}`;
}

function ratio(current, baseline) {
	if (baseline === 0) {
		return current === 0 ? 1 : Number.POSITIVE_INFINITY;
	}
	return current / baseline;
}

function formatRatio(value) {
	return Number.isFinite(value) ? `${formatNumber(value)}x` : "infx";
}

function formatMs(value) {
	return `${formatNumber(value)}ms`;
}

function formatNumber(value) {
	if (!Number.isFinite(value)) return String(value);
	if (Math.abs(value) >= 100) return value.toFixed(1);
	if (Math.abs(value) >= 10) return value.toFixed(2);
	return value.toFixed(3);
}
