// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { accessSync, constants } from "node:fs";
import path from "node:path";
import { chromium } from "playwright-core";

const windowsExecutableExts = [".exe", ".cmd", ".bat", ".com"];

export function createBrowserLauncher() {
	const browserPath = findBrowserExecutable();
	if (!browserPath) {
		return undefined;
	}
	return async ({ args, headless, url, userDataDir, verbose, logPrefix }) => {
		assertSafeArgs(args);
		const context = await chromium.launchPersistentContext(userDataDir, {
			args,
			executablePath: browserPath,
			headless,
		});
		const page = context.pages()[0] ?? await context.newPage();
		if (verbose) {
			page.on("console", (message) => {
				console.log(`${logPrefix}: console ${message.type()} ${message.text()}`);
			});
			page.on("pageerror", (error) => {
				console.error(`${logPrefix}: pageerror ${error.message}`);
			});
			page.on("requestfailed", (request) => {
				console.error(
					`${logPrefix}: requestfailed ${request.url()} ${request.failure()?.errorText ?? ""}`,
				);
			});
		}
		await page.goto(url);
		return { context, page };
	};
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
		throw new TypeError("browser arguments must be an array of strings");
	}
	for (const arg of args) {
		if (arg.includes("\0")) {
			throw new Error("browser arguments must not contain null bytes");
		}
	}
}
