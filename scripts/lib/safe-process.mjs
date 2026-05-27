// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { spawn } from "node:child_process";
import { accessSync, constants } from "node:fs";
import path from "node:path";

const windowsExecutableExts = [".exe", ".cmd", ".bat", ".com"];

// Centralized launchers for repository-owned tooling. They never invoke a shell,
// so arguments are passed as argv values instead of command-line text.
export function startMoonProcess(args, options = {}) {
	assertSafeArgs(args);
	return spawn("moon", args, {
		...options,
		shell: false,
		windowsHide: true,
	});
}

export function runMoonProcess(args, options = {}) {
	return waitForProcess("moon", args, startMoonProcess(args, options));
}

export function startNodeScriptProcess(scriptPath, args = [], options = {}) {
	assertSafeScriptPath(scriptPath);
	assertSafeArgs(args);
	return spawn(process.execPath, [scriptPath, ...args], {
		...options,
		shell: false,
		windowsHide: true,
	});
}

export function runNodeScriptProcess(scriptPath, args = [], options = {}) {
	return waitForProcess(
		process.execPath,
		[scriptPath, ...args],
		startNodeScriptProcess(scriptPath, args, options),
	);
}

export function hasBrowserExecutable() {
	return findBrowserExecutable() !== undefined;
}

export function startBrowserProcess(args, options = {}) {
	assertSafeArgs(args);
	const browserPath = findBrowserExecutable();
	if (!browserPath) {
		throw new Error("Chrome/Chromium browser not found");
	}
	return spawn(browserPath, args, {
		...options,
		shell: false,
		windowsHide: true,
	});
}

function waitForProcess(commandLabel, args, child) {
	return new Promise((resolve, reject) => {
		child.on("error", reject);
		child.on("close", (code, signal) => {
			if (code === 0) {
				resolve();
			} else {
				reject(
					new Error(
						`${commandLabel} ${args.join(" ")} failed with ${signal ?? `exit code ${code}`}`,
					),
				);
			}
		});
	});
}

function isExecutable(candidate) {
	try {
		accessSync(candidate, constants.X_OK);
		return true;
	} catch {
		return false;
	}
}

function findExecutable(name) {
	if (path.isAbsolute(name) || name.includes(path.sep)) {
		return isExecutable(name) ? name : undefined;
	}
	const pathEnv = process.env.PATH ?? "";
	const searchDirs = pathEnv.split(path.delimiter).filter(Boolean);
	const candidates = process.platform === "win32"
		? windowsExecutableExts.map((ext) => `${name}${ext}`)
		: [name];
	for (const dir of searchDirs) {
		for (const candidate of candidates) {
			const fullPath = path.join(dir, candidate);
			if (isExecutable(fullPath)) {
				return fullPath;
			}
		}
	}
	return undefined;
}

function findBrowserExecutable() {
	const fromEnv = process.env.RHODONITE_BROWSER || process.env.CHROME;
	if (fromEnv && isExecutable(fromEnv)) {
		return fromEnv;
	}
	for (const candidate of platformBrowserCandidates()) {
		if (isExecutable(candidate)) {
			return candidate;
		}
	}
	for (const name of [
		"google-chrome",
		"google-chrome-stable",
		"chromium",
		"chromium-browser",
		"microsoft-edge",
	]) {
		const found = findExecutable(name);
		if (found) {
			return found;
		}
	}
	return undefined;
}

function assertSafeScriptPath(scriptPath) {
	if (
		!scriptPath.startsWith("scripts/") ||
		path.isAbsolute(scriptPath) ||
		scriptPath.includes("..") ||
		scriptPath.includes("\0")
	) {
		throw new Error(`unsafe Node script path: ${scriptPath}`);
	}
}

function platformBrowserCandidates() {
	if (process.platform === "darwin") {
		return [
			"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
			"/Applications/Chromium.app/Contents/MacOS/Chromium",
			"/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
		];
	}
	if (process.platform === "win32") {
		const roots = [
			process.env.PROGRAMFILES,
			process.env["PROGRAMFILES(X86)"],
			process.env.LOCALAPPDATA,
		].filter(Boolean);
		return roots.flatMap((root) => [
			path.join(root, "Google/Chrome/Application/chrome.exe"),
			path.join(root, "Chromium/Application/chrome.exe"),
			path.join(root, "Microsoft/Edge/Application/msedge.exe"),
		]);
	}
	return [
		"/usr/bin/google-chrome",
		"/usr/bin/google-chrome-stable",
		"/usr/bin/chromium",
		"/usr/bin/chromium-browser",
		"/usr/bin/microsoft-edge",
		"/usr/local/bin/google-chrome",
		"/usr/local/bin/chromium",
	];
}

function assertSafeArgs(args) {
	if (!Array.isArray(args) || args.some((arg) => typeof arg !== "string")) {
		throw new TypeError("process arguments must be an array of strings");
	}
	for (const arg of args) {
		if (arg.includes("\0")) {
			throw new Error("process arguments must not contain null bytes");
		}
	}
}
