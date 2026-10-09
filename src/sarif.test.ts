import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { dedupe, fixSarif } from "./sarif.js";

let dir: string;
let file: string;

beforeEach(() => {
    dir = mkdtempSync(join(tmpdir(), "govulncheck-action-"));
    file = join(dir, "results.sarif");
});

afterEach(() => {
    rmSync(dir, { recursive: true, force: true });
});

// biome-ignore lint/suspicious/noExplicitAny: test fixtures are untyped SARIF documents
function fix(sarif: unknown): any {
    writeFileSync(file, JSON.stringify(sarif));
    fixSarif(file);
    return JSON.parse(readFileSync(file, "utf8"));
}

function rules(...items: unknown[]) {
    return { runs: [{ tool: { driver: { rules: items } } }] };
}

function stacks(...items: unknown[]) {
    return { runs: [{ tool: { driver: { rules: [] } }, results: [{ ruleId: "GO-2024-0001", stacks: items }] }] };
}

describe("fixSarif", () => {
    it("handles missing file path", () => {
        expect(() => fixSarif("")).toThrow("output-file is required");
    });

    it("handles non-existent file", () => {
        expect(() => fixSarif("/nonexistent/file.sarif")).toThrow("does not exist");
    });

    it("rejects invalid JSON", () => {
        writeFileSync(file, "not json");
        expect(() => fixSarif(file)).toThrow();
    });

    it("removes duplicate tags", () => {
        const out = fix(rules({ id: "GO-2024-0001", properties: { tags: ["CVE-2024-0001", "CVE-2024-0001"] } }));
        expect(out.runs[0].tool.driver.rules[0].properties.tags).toEqual(["CVE-2024-0001"]);
    });

    it("sorts tags like jq's unique", () => {
        const out = fix(rules({ id: "GO-2024-0001", properties: { tags: ["b", "a", "b"] } }));
        expect(out.runs[0].tool.driver.rules[0].properties.tags).toEqual(["a", "b"]);
    });

    it("handles empty rules array", () => {
        const out = fix(rules());
        expect(out.runs[0].tool.driver.rules).toEqual([]);
    });

    it("preserves non-duplicate tags", () => {
        const out = fix(rules({ id: "GO-2024-0001", properties: { tags: ["CVE-2024-0001"] } }));
        expect(out.runs[0].tool.driver.rules[0].properties.tags).toEqual(["CVE-2024-0001"]);
    });

    it("handles rules without properties", () => {
        const out = fix(rules({ id: "GO-2024-0001" }));
        expect(out.runs[0].tool.driver.rules).toEqual([{ id: "GO-2024-0001" }]);
    });

    it("keeps rules without tags alongside rules with tags", () => {
        const out = fix(
            rules(
                { id: "GO-2024-0001", properties: {} },
                { id: "GO-2024-0002", properties: { tags: ["CVE-2024-0002", "CVE-2024-0002"] } },
            ),
        );
        expect(out.runs[0].tool.driver.rules).toEqual([
            { id: "GO-2024-0001", properties: {} },
            { id: "GO-2024-0002", properties: { tags: ["CVE-2024-0002"] } },
        ]);
    });

    it("removes duplicate stacks and keeps their order", () => {
        const b = { message: { text: "stack b" }, frames: [{ module: "b" }] };
        const a = { message: { text: "stack a" }, frames: [{ module: "a" }] };
        const out = fix(stacks(b, b, a, a));
        expect(out.runs[0].results[0].stacks).toEqual([b, a]);
    });

    it("keeps stacks that differ only in frames", () => {
        const out = fix(
            stacks(
                { message: { text: "stack" }, frames: [{ module: "a" }] },
                { message: { text: "stack" }, frames: [{ module: "b" }] },
            ),
        );
        expect(out.runs[0].results[0].stacks).toHaveLength(2);
    });

    it("treats stacks with reordered keys as duplicates", () => {
        const out = fix(stacks({ message: { text: "stack" }, frames: [] }, { frames: [], message: { text: "stack" } }));
        expect(out.runs[0].results[0].stacks).toHaveLength(1);
    });

    it("handles results without stacks", () => {
        const out = fix({ runs: [{ tool: { driver: { rules: [] } }, results: [{ ruleId: "GO-2024-0001" }] }] });
        expect(out.runs[0].results).toEqual([{ ruleId: "GO-2024-0001" }]);
    });

    it("writes pretty-printed JSON with a trailing newline", () => {
        fix(rules());
        expect(readFileSync(file, "utf8")).toEndWith("}\n");
        expect(readFileSync(file, "utf8")).toContain('\n  "runs"');
    });
});

describe("dedupe", () => {
    it("keeps the first occurrence of each item", () => {
        expect(dedupe([1, 2, 1, 3, 2])).toEqual([1, 2, 3]);
    });

    it("distinguishes values that only look alike", () => {
        expect(dedupe([1, "1", null, "null"])).toEqual([1, "1", null, "null"]);
    });
});
