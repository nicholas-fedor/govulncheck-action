import { describe, expect, it } from "bun:test";
import { type ArgsInputs, buildArgs } from "./args.js";

const defaults: ArgsInputs = {
    workDir: ".",
    outputFormat: "text",
    goPackage: "./...",
    scanLevel: "symbol",
    includeTests: "false",
    buildTags: "",
    dbUrl: "",
    mode: "source",
    show: "",
};

function args(override: Partial<ArgsInputs> = {}): string[] {
    return buildArgs({ ...defaults, ...override });
}

describe("buildArgs", () => {
    it("returns basic arguments", () => {
        expect(args()).toEqual(["-C", ".", "-format", "text", "./..."]);
    });

    it("includes scan-level when not default", () => {
        expect(args({ scanLevel: "module" })).toEqual(["-C", ".", "-format", "text", "-scan-level", "module", "./..."]);
    });

    it("excludes scan-level when default", () => {
        expect(args()).not.toContain("-scan-level");
    });

    it("includes -test when enabled in source mode", () => {
        expect(args({ includeTests: "true" })).toContain("-test");
    });

    it("excludes -test when disabled", () => {
        expect(args()).not.toContain("-test");
    });

    it("excludes -test in binary mode", () => {
        expect(args({ includeTests: "true", mode: "binary" })).not.toContain("-test");
    });

    it("includes -tags when provided", () => {
        expect(args({ buildTags: "tag1,tag2" })).toEqual(["-C", ".", "-format", "text", "-tags", "tag1,tag2", "./..."]);
    });

    it("excludes -tags when empty", () => {
        expect(args()).not.toContain("-tags");
    });

    it("includes -db when provided", () => {
        expect(args({ dbUrl: "https://custom.db" })).toEqual([
            "-C",
            ".",
            "-format",
            "text",
            "-db",
            "https://custom.db",
            "./...",
        ]);
    });

    it("excludes -db when empty", () => {
        expect(args()).not.toContain("-db");
    });

    it("includes -mode when not default", () => {
        expect(args({ mode: "binary" })).toEqual(["-C", ".", "-format", "text", "-mode", "binary", "./..."]);
    });

    it("excludes -mode when default", () => {
        expect(args()).not.toContain("-mode");
    });

    it("includes -show when provided with text format", () => {
        expect(args({ show: "traces" })).toEqual(["-C", ".", "-format", "text", "-show", "traces", "./..."]);
    });

    it("excludes -show when empty", () => {
        expect(args()).not.toContain("-show");
    });

    it("excludes -show with non-text format", () => {
        expect(args({ outputFormat: "json", show: "verbose" })).not.toContain("-show");
    });

    it("splits multiple package patterns into separate arguments", () => {
        expect(args({ goPackage: "pkg/... internal/..." })).toEqual([
            "-C",
            ".",
            "-format",
            "text",
            "pkg/...",
            "internal/...",
        ]);
    });

    it("splits package patterns on any whitespace", () => {
        expect(args({ goPackage: " pkg/...\tinternal/...\ncmd/... " }).slice(4)).toEqual([
            "pkg/...",
            "internal/...",
            "cmd/...",
        ]);
    });

    it("combines every flag in a fixed order", () => {
        expect(
            args({
                workDir: "app",
                scanLevel: "package",
                includeTests: "true",
                buildTags: "integration",
                dbUrl: "https://db.example",
                show: "verbose",
            }),
        ).toEqual([
            "-C",
            "app",
            "-format",
            "text",
            "-scan-level",
            "package",
            "-test",
            "-tags",
            "integration",
            "-db",
            "https://db.example",
            "-show",
            "verbose",
            "./...",
        ]);
    });
});
