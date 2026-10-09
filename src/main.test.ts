import { afterEach, beforeEach, describe, expect, it, mock, spyOn } from "bun:test";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import * as core from "@actions/core";
import * as exec from "@actions/exec";
import { run } from "./main.js";

type ExecOptions = NonNullable<Parameters<typeof exec.exec>[2]>;

let dir: string;
let cwd: string;
let workspace: string | undefined;
let infos: string[];
let failed: ReturnType<typeof spyOn>;

function setInputs(values: Record<string, string>): void {
    spyOn(core, "getInput").mockImplementation((name: string) => (values[name] ?? "").trim());
}

/** Fakes govulncheck by writing the given stdout and stderr and returning the exit code. */
function fakeGovulncheck(stdout: string, exitCode = 0, stderr = "") {
    return spyOn(exec, "exec").mockImplementation(async (_cmd, _args, options?: ExecOptions) => {
        if (stdout) options?.listeners?.stdout?.(Buffer.from(stdout));
        if (stderr) options?.listeners?.stderr?.(Buffer.from(stderr));
        return exitCode;
    });
}

beforeEach(() => {
    dir = mkdtempSync(join(tmpdir(), "govulncheck-action-"));
    cwd = process.cwd();
    workspace = process.env.GITHUB_WORKSPACE;
    process.chdir(dir);
    process.env.GITHUB_WORKSPACE = dir;
    infos = [];
    spyOn(core, "info").mockImplementation((message: string) => {
        infos.push(message);
    });
    failed = spyOn(core, "setFailed").mockImplementation(() => {});
});

afterEach(() => {
    mock.restore();
    process.chdir(cwd);
    if (workspace === undefined) {
        delete process.env.GITHUB_WORKSPACE;
    } else {
        process.env.GITHUB_WORKSPACE = workspace;
    }
    process.exitCode = 0;
    rmSync(dir, { recursive: true, force: true });
});

describe("run", () => {
    it("runs govulncheck with the default arguments", async () => {
        setInputs({});
        const govulncheck = fakeGovulncheck("");

        await run();

        expect(govulncheck).toHaveBeenCalledWith("govulncheck", ["-C", ".", "-format", "text", "./..."], {
            ignoreReturnCode: true,
        });
        expect(infos).toEqual([
            "Running validations...",
            "Building govulncheck arguments...",
            "Running govulncheck with arguments: -C . -format text ./...",
            "govulncheck completed successfully",
        ]);
        expect(failed).not.toHaveBeenCalled();
    });

    it("fails without running govulncheck when an input is invalid", async () => {
        setInputs({ "output-format": "xml" });
        const govulncheck = fakeGovulncheck("");

        await run();

        expect(failed).toHaveBeenCalledWith("Invalid output-format 'xml'. Valid values: text, json, sarif, openvex");
        expect(govulncheck).not.toHaveBeenCalled();
    });

    it("fails with govulncheck's exit code when it reports vulnerabilities", async () => {
        setInputs({});
        fakeGovulncheck("", 3);

        await run();

        expect(failed).toHaveBeenCalledWith("govulncheck exited with code 3");
        expect(process.exitCode).toBe(3);
        expect(infos).not.toContain("govulncheck completed successfully");
    });

    it("fails when govulncheck cannot be started", async () => {
        setInputs({});
        spyOn(exec, "exec").mockRejectedValue(new Error("Unable to locate executable file: govulncheck"));

        await run();

        expect(failed).toHaveBeenCalledWith("Unable to locate executable file: govulncheck");
    });

    it("writes only govulncheck's stdout to the output file", async () => {
        setInputs({ "output-format": "json", "output-file": "results.json" });
        const stderr = spyOn(process.stderr, "write").mockImplementation(() => true);
        const govulncheck = fakeGovulncheck('{"config":{}}\n', 0, "progress\n");

        await run();

        const options = govulncheck.mock.calls[0]?.[2] as ExecOptions;
        expect(options.silent).toBe(true);
        expect(options.ignoreReturnCode).toBe(true);
        expect(readFileSync(join(dir, "results.json"), "utf8")).toBe('{"config":{}}\n');
        expect(stderr).toHaveBeenCalledWith(Buffer.from("progress\n"));
        expect(failed).not.toHaveBeenCalled();
    });

    it("writes the output file relative to the workspace, not the working directory", async () => {
        setInputs({ "output-format": "json", "output-file": "results.json" });
        mkdirSync(join(dir, "sub"));
        process.chdir(join(dir, "sub"));
        fakeGovulncheck("{}");

        await run();

        expect(readFileSync(join(dir, "results.json"), "utf8")).toBe("{}");
        expect(existsSync(join(dir, "sub", "results.json"))).toBe(false);
    });

    it("leaves non-SARIF output untouched", async () => {
        setInputs({ "output-format": "json", "output-file": "results.json" });
        fakeGovulncheck('{"b":1,"a":[1,1]}');

        await run();

        expect(readFileSync(join(dir, "results.json"), "utf8")).toBe('{"b":1,"a":[1,1]}');
        expect(infos).not.toContain("Applying SARIF duplicate tags and stacks fix...");
    });

    it("removes duplicate stacks from SARIF output", async () => {
        setInputs({ "output-format": "sarif", "output-file": "results.sarif" });
        const stack = { message: { text: "stack" }, frames: [] };
        fakeGovulncheck(JSON.stringify({ runs: [{ results: [{ stacks: [stack, stack] }] }] }));

        await run();

        const sarif = JSON.parse(readFileSync(join(dir, "results.sarif"), "utf8"));
        expect(sarif.runs[0].results[0].stacks).toEqual([stack]);
        expect(infos).toContain("SARIF duplicate tags and stacks fixed");
        expect(failed).not.toHaveBeenCalled();
    });

    it("skips the SARIF fix when govulncheck fails", async () => {
        setInputs({ "output-format": "sarif", "output-file": "results.sarif" });
        fakeGovulncheck("partial", 1);

        await run();

        expect(readFileSync(join(dir, "results.sarif"), "utf8")).toBe("partial");
        expect(failed).toHaveBeenCalledWith("govulncheck exited with code 1");
    });

    it("rejects an output file outside the workspace", async () => {
        setInputs({ "output-file": "../results.sarif" });
        const govulncheck = fakeGovulncheck("");

        await run();

        expect(failed).toHaveBeenCalledWith("output-file path must be within workspace");
        expect(govulncheck).not.toHaveBeenCalled();
    });
});
