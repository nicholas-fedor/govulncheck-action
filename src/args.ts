export interface ArgsInputs {
    workDir: string;
    outputFormat: string;
    goPackage: string;
    scanLevel: string;
    includeTests: string;
    buildTags: string;
    dbUrl: string;
    mode: string;
    show: string;
}

/** Builds the govulncheck command-line arguments, omitting flags left at their defaults. */
export function buildArgs(inputs: ArgsInputs): string[] {
    const args = ["-C", inputs.workDir, "-format", inputs.outputFormat];

    if (inputs.scanLevel !== "" && inputs.scanLevel !== "symbol") {
        args.push("-scan-level", inputs.scanLevel);
    }

    // -test only applies to source mode.
    if (inputs.includeTests === "true" && inputs.mode === "source") {
        args.push("-test");
    }

    if (inputs.buildTags !== "") {
        args.push("-tags", inputs.buildTags);
    }

    if (inputs.dbUrl !== "") {
        args.push("-db", inputs.dbUrl);
    }

    if (inputs.mode !== "" && inputs.mode !== "source") {
        args.push("-mode", inputs.mode);
    }

    // -show is only valid for text output.
    if (inputs.show !== "" && inputs.outputFormat === "text") {
        args.push("-show", inputs.show);
    }

    // go-package may hold several whitespace-separated patterns, such as "pkg/... internal/...".
    args.push(...inputs.goPackage.split(/\s+/).filter((pattern) => pattern !== ""));

    return args;
}
