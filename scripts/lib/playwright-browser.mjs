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
	return async ({
		args,
		attachPageDiagnostics = defaultPageDiagnostics,
		headless,
		url,
		userDataDir,
		verbose,
		logPrefix,
	}) => {
		assertSafeArgs(args);
		const context = await chromium.launchPersistentContext(userDataDir, {
			args,
			executablePath: browserPath,
			headless,
		});
		let detachPageDiagnostics = () => {};
		try {
			const page = context.pages()[0] ?? await context.newPage();
			detachPageDiagnostics =
				attachPageDiagnostics({ context, page, verbose, logPrefix }) ?? (() => {});
			await page.goto(url);
			return { context, page };
		} catch (error) {
			detachPageDiagnostics();
			await context.close();
			throw error;
		}
	};
}

export function attachBrowserDiagnostics({
	context,
	logPrefix,
	page,
	rejectBrowserFailure,
	verbose,
}) {
	let diagnostics = "";
	let active = true;
	const append = (line) => {
		diagnostics = appendOutputTail(diagnostics, `${line}\n`);
		if (verbose) {
			console.error(`${logPrefix}: ${line}`);
		}
	};
	const failBrowser = (message) => {
		if (!active) {
			return;
		}
		append(message);
		rejectBrowserFailure(new Error(message));
	};
	const onConsole = (message) => {
		append(`console ${message.type()} ${message.text()}`);
	};
	const onPageError = (error) => {
		append(`pageerror ${error.message}`);
	};
	const onRequestFailed = (request) => {
		append(`requestfailed ${request.url()} ${request.failure()?.errorText ?? ""}`);
	};
	const onCrash = () => {
		failBrowser("browser page crashed before reporting results");
	};
	const onPageClose = () => {
		failBrowser("browser page closed before reporting results");
	};
	const onContextClose = () => {
		failBrowser("browser context closed before reporting results");
	};
	page.on("console", onConsole);
	page.on("pageerror", onPageError);
	page.on("requestfailed", onRequestFailed);
	page.on("crash", onCrash);
	page.on("close", onPageClose);
	context.on("close", onContextClose);
	return {
		get: () => diagnostics,
		stop: () => {
			active = false;
			page.off("console", onConsole);
			page.off("pageerror", onPageError);
			page.off("requestfailed", onRequestFailed);
			page.off("crash", onCrash);
			page.off("close", onPageClose);
			context.off("close", onContextClose);
		},
	};
}

export function formatBrowserFailure(error, diagnostics) {
	const message = error instanceof Error ? error.message : String(error);
	if (message.includes("browser diagnostics:")) {
		return message;
	}
	return message + formatBrowserDiagnostics(diagnostics);
}

function appendOutputTail(existing, text) {
	const next = existing + text;
	return next.length > 8000 ? next.slice(next.length - 8000) : next;
}

function formatBrowserDiagnostics(diagnostics) {
	return diagnostics.trim() ? `\nbrowser diagnostics:\n${diagnostics.trim()}` : "";
}

function defaultPageDiagnostics({ page, verbose, logPrefix }) {
	if (!verbose) {
		return undefined;
	}
	const onConsole = (message) => {
		console.log(`${logPrefix}: console ${message.type()} ${message.text()}`);
	};
	const onPageError = (error) => {
		console.error(`${logPrefix}: pageerror ${error.message}`);
	};
	const onRequestFailed = (request) => {
		console.error(
			`${logPrefix}: requestfailed ${request.url()} ${request.failure()?.errorText ?? ""}`,
		);
	};
	page.on("console", onConsole);
	page.on("pageerror", onPageError);
	page.on("requestfailed", onRequestFailed);
	return () => {
		page.off("console", onConsole);
		page.off("pageerror", onPageError);
		page.off("requestfailed", onRequestFailed);
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
