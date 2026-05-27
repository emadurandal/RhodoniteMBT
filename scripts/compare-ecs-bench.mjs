// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.dirname(fileURLToPath(new URL("../package.json", import.meta.url)));
const args = process.argv.slice(2);

let baselinePath = path.join(root, "benchmarks/ecs/baseline.jsonl");
let currentPath = "";
let summaryMarkdownPath = "";
let failOnRegression = process.env.RHODONITE_ECS_BENCH_FAIL_ON_REGRESSION === "1";

for (let i = 0; i < args.length; i++) {
	const arg = args[i];
	if (arg === "--baseline") {
		baselinePath = requireValue(arg, args[++i]);
	} else if (arg === "--current") {
		currentPath = requireValue(arg, args[++i]);
	} else if (arg === "--summary-md") {
		summaryMarkdownPath = requireValue(arg, args[++i]);
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
		warnings.push(entry("NEW", `NEW ${describe(cur)} has no baseline row`, cur));
		continue;
	}
	if (cur.checksum !== base.checksum) {
		warnings.push(
			entry(
				"CHECKSUM",
				`CHECKSUM ${describe(cur)} baseline=${base.checksum} current=${cur.checksum}`,
				cur,
				base,
			),
		);
		continue;
	}
	const medianDelta = cur.median_ms - base.median_ms;
	const medianRatio = ratio(cur.median_ms, base.median_ms);
	const nsRatio = ratio(cur.ns_per_item, base.ns_per_item);
	const message = `${describe(cur)} median ${formatMs(base.median_ms)} -> ${formatMs(cur.median_ms)} (${formatRatio(medianRatio)}), ns/item ${formatNumber(base.ns_per_item)} -> ${formatNumber(cur.ns_per_item)} (${formatRatio(nsRatio)})`;
	if (medianRatio > medianRatioThreshold && medianDelta >= minMedianDeltaMs) {
		warnings.push(entry("REGRESSION", `REGRESSION ${message}`, cur, base));
	} else if (medianRatio < 0.9 && medianDelta <= -minMedianDeltaMs) {
		improvements.push(entry("IMPROVED", `IMPROVED ${message}`, cur, base));
	} else {
		stable.push(entry("OK", `OK ${message}`, cur, base));
	}
}

for (const [key, base] of baselineByKey) {
	if (currentScopes.has(scopeFor(base)) && !currentByKey.has(key)) {
		warnings.push(
			entry("MISSING", `MISSING ${describe(base)} is present in baseline only`, undefined, base),
		);
	}
}

console.log(
	`ecs_bench_compare: baseline=${path.relative(root, baseline.path)} current=${path.relative(root, current.path)}`,
);
console.log(
	`ecs_bench_compare: ok=${stable.length} improved=${improvements.length} warnings=${warnings.length}`,
);
for (const line of warnings) {
	console.warn(`ecs_bench_compare: WARN ${line.message}`);
}
for (const line of improvements) {
	console.log(`ecs_bench_compare: ${line.message}`);
}

if (summaryMarkdownPath.length > 0) {
	fs.writeFileSync(
		summaryMarkdownPath,
		renderSummaryMarkdown({
			baseline,
			current,
			stable,
			improvements,
			warnings,
			failOnRegression,
		}),
	);
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
		`compare-ecs-bench: ${message}\nusage: node scripts/compare-ecs-bench.mjs --current path [--baseline path] [--summary-md path] [--fail-on-regression]`,
	);
	process.exit(2);
}

function entry(kind, message, currentRow = undefined, baselineRow = undefined) {
	return { kind, message, currentRow, baselineRow };
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

function renderSummaryMarkdown(result) {
	const warningCounts = countByKind(result.warnings);
	const lines = [
		"## ECS Bench Comparison",
		"",
		`Baseline: \`${path.relative(root, result.baseline.path)}\``,
		`Current: \`${path.relative(root, result.current.path)}\``,
		"",
		"| Status | Count |",
		"| --- | ---: |",
		`| Stable | ${result.stable.length} |`,
		`| Improved | ${result.improvements.length} |`,
		`| Warnings | ${result.warnings.length} |`,
		`| Fail on regression | ${result.failOnRegression ? "yes" : "no"} |`,
		"",
		"### Warning Categories",
		"",
		"| Category | Count |",
		"| --- | ---: |",
		...["REGRESSION", "NEW", "MISSING", "CHECKSUM"].map(
			(kind) => `| ${kind} | ${warningCounts.get(kind) ?? 0} |`,
		),
	];
	appendEntryTable(lines, "Top Warnings", result.warnings, 10);
	appendEntryTable(lines, "Top Improvements", result.improvements, 10);
	lines.push("");
	return `${lines.join("\n")}\n`;
}

function appendEntryTable(lines, title, entries, limit) {
	lines.push("", `### ${title}`, "");
	if (entries.length === 0) {
		lines.push("None.");
		return;
	}
	lines.push("| Kind | Case | Count | Median | Ratio |");
	lines.push("| --- | --- | ---: | --- | ---: |");
	for (const item of entries.slice(0, limit)) {
		const row = item.currentRow ?? item.baselineRow;
		const base = item.baselineRow;
		const cur = item.currentRow;
		const median = base && cur
			? `${formatMs(base.median_ms)} -> ${formatMs(cur.median_ms)}`
			: cur
				? `${formatMs(cur.median_ms)}`
				: base
					? `${formatMs(base.median_ms)}`
					: "";
		const medianRatio = base && cur ? formatRatio(ratio(cur.median_ms, base.median_ms)) : "";
		lines.push(
			`| ${escapeMarkdownTable(item.kind)} | ${escapeMarkdownTable(row ? `${row.target}/${row.build_mode} ${row.case}` : item.message)} | ${row?.count ?? ""} | ${escapeMarkdownTable(median)} | ${medianRatio} |`,
		);
	}
	if (entries.length > limit) {
		lines.push(`| ... | ${entries.length - limit} more |  |  |  |`);
	}
}

function countByKind(entries) {
	const counts = new Map();
	for (const item of entries) {
		counts.set(item.kind, (counts.get(item.kind) ?? 0) + 1);
	}
	return counts;
}

function escapeMarkdownTable(value) {
	return String(value).replaceAll("|", "\\|").replace(/\r?\n/g, " ");
}
