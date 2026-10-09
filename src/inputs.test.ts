import { afterEach, describe, expect, it, mock, spyOn } from "bun:test";
import * as core from "@actions/core";
import { getInputs } from "./inputs.js";

afterEach(() => {
    mock.restore();
});

function setInputs(values: Record<string, string>): void {
    spyOn(core, "getInput").mockImplementation((name: string) => (values[name] ?? "").trim());
}

describe("getInputs", () => {
    it("applies defaults for empty inputs", () => {
        setInputs({});
        expect(getInputs()).toEqual({
            workDir: ".",
            outputFormat: "text",
            goPackage: "./...",
            scanLevel: "symbol",
            includeTests: "false",
            buildTags: "",
            dbUrl: "",
            mode: "source",
            show: "",
            outputFile: "",
        });
    });

    it("reads every input by its action.yml name", () => {
        setInputs({
            "work-dir": "app",
            "output-format": "sarif",
            "go-package": "pkg/...",
            "scan-level": "module",
            "include-tests": "true",
            "build-tags": "integration",
            "db-url": "https://db.example",
            mode: "binary",
            show: "traces",
            "output-file": "results.sarif",
        });
        expect(getInputs()).toEqual({
            workDir: "app",
            outputFormat: "sarif",
            goPackage: "pkg/...",
            scanLevel: "module",
            includeTests: "true",
            buildTags: "integration",
            dbUrl: "https://db.example",
            mode: "binary",
            show: "traces",
            outputFile: "results.sarif",
        });
    });

    it("reads inputs from INPUT_ environment variables", () => {
        process.env["INPUT_WORK-DIR"] = " app ";
        try {
            expect(getInputs().workDir).toBe("app");
        } finally {
            delete process.env["INPUT_WORK-DIR"];
        }
    });
});
