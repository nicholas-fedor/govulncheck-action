import * as core from "@actions/core";

export interface ActionInputs {
    workDir: string;
    outputFormat: string;
    goPackage: string;
    scanLevel: string;
    includeTests: string;
    buildTags: string;
    dbUrl: string;
    mode: string;
    show: string;
    outputFile: string;
}

/** Reads an input, falling back to the default when it is empty. */
function input(name: string, fallback = ""): string {
    return core.getInput(name) || fallback;
}

/** Reads the action inputs, applying the same defaults as action.yml. */
export function getInputs(): ActionInputs {
    return {
        workDir: input("work-dir", "."),
        outputFormat: input("output-format", "text"),
        goPackage: input("go-package", "./..."),
        scanLevel: input("scan-level", "symbol"),
        includeTests: input("include-tests", "false"),
        buildTags: input("build-tags"),
        dbUrl: input("db-url"),
        mode: input("mode", "source"),
        show: input("show"),
        outputFile: input("output-file"),
    };
}
