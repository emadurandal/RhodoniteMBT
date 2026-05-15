import { spawn } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.dirname(fileURLToPath(new URL("../package.json", import.meta.url)));
const examplesDir = path.join(root, "moon/rhodonite_examples");

const args = process.argv.slice(2);
const target = args.find((arg) => !arg.startsWith("-")) ?? "all";
const update = args.includes("--update") ||
	process.env.RHODONITE_UPDATE_VISUAL_SNAPSHOTS === "1";
const verbose = args.includes("--verbose") ||
	process.env.RHODONITE_VISUAL_VERBOSE === "1";

if (!["all", "native", "browser"].includes(target)) {
	console.error(
		"usage: node scripts/run-visual-regression.mjs [all|native|browser] [--update] [--verbose]",
	);
	process.exit(2);
}

if (target === "all" || target === "native") {
	await runNative();
}
if (target === "all" || target === "browser") {
	await runBrowser();
}

async function runNative() {
	await run("moon", [
		"test",
		"--target",
		"native",
		"moon/rhodonite_examples/src/visual_regression",
	], {
		env: updateEnv(),
	});
}

async function runBrowser() {
	await run("moon", ["build", "--target", "js"], { cwd: examplesDir });
	await run("moon", [
		"build",
		"--target",
		"wasm",
		"--release",
		"src/ecs-mass-cubes/wasm/main",
	], { cwd: examplesDir });
	await run("moon", [
		"build",
		"--target",
		"wasm-gc",
		"--release",
		"src/ecs-mass-cubes/wasm/main",
	], { cwd: examplesDir });
	await run(process.execPath, ["scripts/run-browser-visual-regression.mjs"], {
		env: {
			...updateEnv(),
			...(verbose ? { RHODONITE_BROWSER_VERBOSE: "1" } : {}),
		},
	});
}

function updateEnv() {
	return update ? { RHODONITE_UPDATE_VISUAL_SNAPSHOTS: "1" } : {};
}

function run(command, commandArgs, options = {}) {
	const cwd = options.cwd ?? root;
	const env = { ...process.env, ...(options.env ?? {}) };
	if (verbose) {
		return spawnAndWait(command, commandArgs, { cwd, env, stdio: "inherit" });
	}
	return new Promise((resolve, reject) => {
		const child = spawn(command, commandArgs, {
			cwd,
			env,
			stdio: ["ignore", "pipe", "pipe"],
		});
		let stdout = "";
		let stderr = "";
		child.stdout.setEncoding("utf8");
		child.stderr.setEncoding("utf8");
		child.stdout.on("data", (chunk) => {
			stdout += chunk;
		});
		child.stderr.on("data", (chunk) => {
			stderr += chunk;
		});
		child.on("error", reject);
		child.on("close", (code, signal) => {
			const filteredStdout = alignVisualResultColumns(filterWarnings(stdout));
			const filteredStderr = alignVisualResultColumns(filterWarnings(stderr));
			if (filteredStdout.length > 0) {
				process.stdout.write(filteredStdout);
			}
			if (filteredStderr.length > 0) {
				process.stderr.write(filteredStderr);
			}
			if (code === 0) {
				resolve();
			} else {
				reject(
					new Error(
						`${command} ${commandArgs.join(" ")} failed with ${signal ?? `exit code ${code}`}`,
					),
				);
			}
		});
	});
}

function spawnAndWait(command, commandArgs, options) {
	return new Promise((resolve, reject) => {
		const child = spawn(command, commandArgs, options);
		child.on("error", reject);
		child.on("close", (code, signal) => {
			if (code === 0) {
				resolve();
			} else {
				reject(
					new Error(
						`${command} ${commandArgs.join(" ")} failed with ${signal ?? `exit code ${code}`}`,
					),
				);
			}
		});
	});
}

function filterWarnings(text) {
	const lines = text.split(/(\r?\n)/);
	const out = [];
	let skipWarningBlock = false;
	for (let i = 0; i < lines.length; i += 2) {
		const line = lines[i] ?? "";
		const newline = lines[i + 1] ?? "";
		if (skipWarningBlock) {
			if (/╯\s*$/.test(line)) {
				skipWarningBlock = false;
			}
			continue;
		}
		if (/^Warning:/.test(line)) {
			const nextLine = lines[i + 2] ?? "";
			if (/^\s*╭─\[/.test(nextLine)) {
				skipWarningBlock = true;
			}
			continue;
		}
		if (/^Finished\. moon:/.test(line)) {
			continue;
		}
		out.push(line, newline);
	}
	return out.join("");
}

function alignVisualResultColumns(text) {
	const lines = text.split(/(\r?\n)/);
	const visualResultPattern =
		/^(visual_regression\((?:native|browser)\): (?:PASS|FAIL|SKIP|UPDATE) )(\S+\.png)(.*)$/;
	let filenameWidth = 0;
	for (let i = 0; i < lines.length; i += 2) {
		const match = visualResultPattern.exec(lines[i] ?? "");
		if (match) {
			filenameWidth = Math.max(filenameWidth, match[2].length);
		}
	}
	if (filenameWidth === 0) {
		return text;
	}
	for (let i = 0; i < lines.length; i += 2) {
		const line = lines[i] ?? "";
		const match = visualResultPattern.exec(line);
		if (match) {
			lines[i] = `${match[1]}${match[2].padEnd(filenameWidth)}${match[3]}`;
		}
	}
	return lines.join("");
}
