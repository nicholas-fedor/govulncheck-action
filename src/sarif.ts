// SARIF post-processing to fix duplicate CVE tags and call stacks.
// Workaround for https://github.com/golang/go/issues/75890

import { existsSync, readFileSync, writeFileSync } from "node:fs";

interface SarifRule {
    properties?: { tags?: unknown[] };
}

interface SarifResult {
    stacks?: unknown[];
}

interface SarifRun {
    tool?: { driver?: { rules?: SarifRule[] } };
    results?: SarifResult[];
}

interface SarifLog {
    runs?: SarifRun[];
}

/** Serializes a value with object keys sorted, so equal values compare equal regardless of key order. */
function canonical(value: unknown): string {
    if (Array.isArray(value)) {
        return `[${value.map(canonical).join(",")}]`;
    }
    if (value !== null && typeof value === "object") {
        const entries = Object.keys(value)
            .sort()
            .map((key) => `${JSON.stringify(key)}:${canonical((value as Record<string, unknown>)[key])}`);
        return `{${entries.join(",")}}`;
    }
    return JSON.stringify(value);
}

/** Removes repeated items, keeping the first occurrence of each in order. */
export function dedupe<T>(items: T[]): T[] {
    const seen = new Set<string>();
    return items.filter((item) => {
        const key = canonical(item);
        if (seen.has(key)) {
            return false;
        }
        seen.add(key);
        return true;
    });
}

/** Returns the unique tags in sorted order. */
function uniqueTags(tags: unknown[]): unknown[] {
    return dedupe(tags).sort((a, b) => {
        const left = canonical(a);
        const right = canonical(b);
        return left < right ? -1 : left > right ? 1 : 0;
    });
}

/** Deduplicates rule tags and result stacks, which the SARIF schema requires to be unique. */
export function dedupeSarif(log: SarifLog): SarifLog {
    for (const run of log.runs ?? []) {
        for (const rule of run.tool?.driver?.rules ?? []) {
            if (rule.properties?.tags) {
                rule.properties.tags = uniqueTags(rule.properties.tags);
            }
        }
        for (const result of run.results ?? []) {
            if (result.stacks) {
                result.stacks = dedupe(result.stacks);
            }
        }
    }
    return log;
}

/** Rewrites a SARIF file in place with duplicate tags and stacks removed. */
export function fixSarif(outputFile: string): void {
    if (outputFile === "") {
        throw new Error("output-file is required");
    }
    if (!existsSync(outputFile)) {
        throw new Error(`Output file does not exist: ${outputFile}`);
    }

    const log = JSON.parse(readFileSync(outputFile, "utf8")) as SarifLog;
    writeFileSync(outputFile, `${JSON.stringify(dedupeSarif(log), null, 2)}\n`);
}
