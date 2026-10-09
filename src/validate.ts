import { existsSync, realpathSync } from "node:fs";
import { dirname, isAbsolute, join, relative, resolve } from "node:path";

const OUTPUT_FORMATS = ["text", "json", "sarif", "openvex"] as const;
const SCAN_LEVELS = ["module", "package", "symbol"] as const;
const MODES = ["source", "binary", "extract"] as const;
const SHOW_VALUES = ["traces", "verbose"] as const;

export interface ValidationInputs {
    outputFormat: string;
    scanLevel: string;
    mode: string;
    show: string;
    includeTests: string;
    goPackage: string;
    workDir: string;
    outputFile: string;
    workspace: string;
}

function validateChoice(name: string, value: string, choices: readonly string[]): void {
    if (!choices.includes(value)) {
        throw new Error(`Invalid ${name} '${value}'. Valid values: ${choices.join(", ")}`);
    }
}

export function validateOutputFormat(value: string): void {
    validateChoice("output-format", value, OUTPUT_FORMATS);
}

export function validateScanLevel(value: string): void {
    validateChoice("scan-level", value, SCAN_LEVELS);
}

export function validateMode(value: string): void {
    validateChoice("mode", value, MODES);
}

export function validateShow(value: string): void {
    validateChoice("show", value, SHOW_VALUES);
}

export function validateIncludeTests(value: string): void {
    if (value !== "" && value !== "true" && value !== "false") {
        throw new Error(`Invalid include-tests '${value}'. Valid values: true, false`);
    }
}

export function validateGoPackage(value: string): void {
    if (value === "") {
        throw new Error("go-package cannot be empty");
    }
}

/**
 * Resolves a path like `realpath -m`: symlinks in the part of the path that
 * exists are followed, and the remaining components are appended as-is.
 */
export function resolveReal(path: string): string {
    const absolute = resolve(path);
    let existing = absolute;
    while (!existsSync(existing)) {
        const parent = dirname(existing);
        if (parent === existing) {
            return absolute;
        }
        existing = parent;
    }
    return join(realpathSync(existing), relative(existing, absolute));
}

function hasTraversal(path: string): boolean {
    return path.includes("..") || path.includes("%2e") || path.includes("%2E");
}

function isWithin(path: string, root: string, allowRoot: boolean): boolean {
    const rel = relative(root, path);
    if (rel === "") {
        return allowRoot;
    }
    return !rel.startsWith("..") && !isAbsolute(rel);
}

/** Rejects an output-file path that could resolve outside the workspace. */
export function validateOutputFilePath(outputFile: string, workspace = "."): void {
    if (outputFile === "") {
        return;
    }
    if (isAbsolute(outputFile)) {
        throw new Error("output-file path must be a relative path");
    }
    if (
        hasTraversal(outputFile) ||
        !isWithin(resolveReal(join(workspace, outputFile)), resolveReal(workspace), false)
    ) {
        throw new Error("output-file path must be within workspace");
    }
}

/** Rejects a work-dir path that could resolve outside the workspace. */
export function validateWorkDirPath(workDir: string, workspace = "."): void {
    if (workDir === "" || workDir === ".") {
        return;
    }
    if (isAbsolute(workDir)) {
        throw new Error("work-dir path must be a relative path");
    }
    if (hasTraversal(workDir) || !isWithin(resolveReal(join(workspace, workDir)), resolveReal(workspace), true)) {
        throw new Error("work-dir path must be within workspace");
    }
}

/** Runs every input validation and throws on the first failure. */
export function validateInputs(inputs: ValidationInputs): void {
    if (inputs.outputFormat !== "") validateOutputFormat(inputs.outputFormat);
    if (inputs.scanLevel !== "") validateScanLevel(inputs.scanLevel);
    if (inputs.mode !== "") validateMode(inputs.mode);
    if (inputs.show !== "") validateShow(inputs.show);
    validateIncludeTests(inputs.includeTests);
    validateGoPackage(inputs.goPackage);
    validateWorkDirPath(inputs.workDir, inputs.workspace);
    validateOutputFilePath(inputs.outputFile, inputs.workspace);
}
