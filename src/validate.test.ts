import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, symlinkSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
    resolveReal,
    type ValidationInputs,
    validateGoPackage,
    validateIncludeTests,
    validateInputs,
    validateMode,
    validateOutputFilePath,
    validateOutputFormat,
    validateScanLevel,
    validateShow,
    validateWorkDirPath,
} from "./validate.js";

describe("validateOutputFormat", () => {
    it.each(["text", "json", "sarif", "openvex"])("accepts %s", (value) => {
        expect(() => validateOutputFormat(value)).not.toThrow();
    });

    it("rejects invalid", () => {
        expect(() => validateOutputFormat("invalid")).toThrow("Invalid output-format 'invalid'");
    });
});

describe("validateScanLevel", () => {
    it.each(["symbol", "package", "module"])("accepts %s", (value) => {
        expect(() => validateScanLevel(value)).not.toThrow();
    });

    it("rejects invalid", () => {
        expect(() => validateScanLevel("invalid")).toThrow("Invalid scan-level 'invalid'");
    });
});

describe("validateMode", () => {
    it.each(["source", "binary", "extract"])("accepts %s", (value) => {
        expect(() => validateMode(value)).not.toThrow();
    });

    it("rejects invalid", () => {
        expect(() => validateMode("invalid")).toThrow("Invalid mode 'invalid'");
    });
});

describe("validateShow", () => {
    it.each(["traces", "verbose"])("accepts %s", (value) => {
        expect(() => validateShow(value)).not.toThrow();
    });

    it("rejects invalid", () => {
        expect(() => validateShow("invalid")).toThrow("Invalid show 'invalid'");
    });
});

describe("validateIncludeTests", () => {
    it.each(["true", "false", ""])("accepts '%s'", (value) => {
        expect(() => validateIncludeTests(value)).not.toThrow();
    });

    it("rejects invalid", () => {
        expect(() => validateIncludeTests("maybe")).toThrow("Invalid include-tests 'maybe'");
    });
});

describe("validateGoPackage", () => {
    it.each(["./...", "./cmd/app"])("accepts %s", (value) => {
        expect(() => validateGoPackage(value)).not.toThrow();
    });

    it("rejects empty", () => {
        expect(() => validateGoPackage("")).toThrow("go-package cannot be empty");
    });
});

describe("validateInputs", () => {
    const valid: ValidationInputs = {
        outputFormat: "json",
        scanLevel: "symbol",
        mode: "source",
        show: "",
        includeTests: "false",
        goPackage: "./...",
        workDir: ".",
        outputFile: "",
        workspace: "/workspace",
    };

    it("passes with valid inputs", () => {
        expect(() => validateInputs(valid)).not.toThrow();
    });

    it("skips enum checks for empty values", () => {
        expect(() =>
            validateInputs({ ...valid, outputFormat: "", scanLevel: "", mode: "", show: "", includeTests: "" }),
        ).not.toThrow();
    });

    it.each([
        ["output-format", { outputFormat: "invalid" }],
        ["scan-level", { scanLevel: "invalid" }],
        ["mode", { mode: "invalid" }],
        ["show", { show: "invalid" }],
        ["include-tests", { includeTests: "maybe" }],
        ["go-package", { goPackage: "" }],
        ["work-dir", { workDir: "../etc" }],
        ["output-file", { outputFile: "../etc/passwd" }],
    ])("fails with invalid %s", (_name, override) => {
        expect(() => validateInputs({ ...valid, ...override })).toThrow();
    });
});

describe("validateOutputFilePath", () => {
    it("allows valid path", () => {
        expect(() => validateOutputFilePath("results.json", "/workspace")).not.toThrow();
    });

    it("allows empty path", () => {
        expect(() => validateOutputFilePath("", "/workspace")).not.toThrow();
    });

    it("rejects the workspace itself", () => {
        expect(() => validateOutputFilePath(".", "/workspace")).toThrow("output-file path must be within workspace");
    });

    it("rejects absolute path", () => {
        expect(() => validateOutputFilePath("/etc/passwd", "/workspace")).toThrow(
            "output-file path must be a relative path",
        );
    });

    it.each([
        ["path traversal", "../etc/passwd"],
        ["encoded traversal", "%2e%2e/%2e%2e/etc"],
        ["uppercase encoded traversal", "%2E%2E/etc"],
        ["double-encoded traversal", "..%252f..%252fetc"],
    ])("rejects %s", (_name, value) => {
        expect(() => validateOutputFilePath(value, "/workspace")).toThrow("output-file path must be within workspace");
    });
});

describe("validateWorkDirPath", () => {
    it.each(["src", ".", ""])("allows '%s'", (value) => {
        expect(() => validateWorkDirPath(value, "/workspace")).not.toThrow();
    });

    it("rejects absolute path", () => {
        expect(() => validateWorkDirPath("/etc/passwd", "/workspace")).toThrow("work-dir path must be a relative path");
    });

    it.each([
        ["path traversal", "../etc"],
        ["encoded traversal", "%2e%2e/%2e%2e/etc"],
        ["double-encoded traversal", "..%252f..%252fetc"],
    ])("rejects %s", (_name, value) => {
        expect(() => validateWorkDirPath(value, "/workspace")).toThrow("work-dir path must be within workspace");
    });
});

describe("symlinks", () => {
    let root: string;
    let workspace: string;

    beforeEach(() => {
        root = mkdtempSync(join(tmpdir(), "govulncheck-action-"));
        workspace = join(root, "workspace");
        mkdirSync(join(workspace, "src"), { recursive: true });
        mkdirSync(join(root, "outside"));
        symlinkSync(join(root, "outside"), join(workspace, "escape"));
        symlinkSync(join(workspace, "src"), join(workspace, "inside"));
    });

    afterEach(() => {
        rmSync(root, { recursive: true, force: true });
    });

    it("resolveReal follows existing symlinks and keeps missing components", () => {
        expect(resolveReal(join(workspace, "escape", "missing", "file"))).toBe(
            join(resolveReal(root), "outside", "missing", "file"),
        );
    });

    it("rejects an output-file through a symlink that leaves the workspace", () => {
        expect(() => validateOutputFilePath("escape/results.sarif", workspace)).toThrow(
            "output-file path must be within workspace",
        );
    });

    it("rejects a work-dir through a symlink that leaves the workspace", () => {
        expect(() => validateWorkDirPath("escape", workspace)).toThrow("work-dir path must be within workspace");
    });

    it("allows paths through a symlink that stays in the workspace", () => {
        expect(() => validateOutputFilePath("inside/results.sarif", workspace)).not.toThrow();
        expect(() => validateWorkDirPath("inside", workspace)).not.toThrow();
    });
});
