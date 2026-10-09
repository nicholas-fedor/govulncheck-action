import { closeSync, openSync, writeSync } from "node:fs";
import { resolve } from "node:path";
import * as core from "@actions/core";
import * as exec from "@actions/exec";
import { buildArgs } from "./args.js";
import { getInputs } from "./inputs.js";
import { fixSarif } from "./sarif.js";
import { validateInputs } from "./validate.js";

/**
 * Runs govulncheck with its stdout written to outputFile. Stderr still goes
 * to the log, and the command line is not echoed into the file.
 */
async function runToFile(args: string[], outputFile: string): Promise<number> {
    const fd = openSync(outputFile, "w");
    try {
        return await exec.exec("govulncheck", args, {
            ignoreReturnCode: true,
            silent: true,
            listeners: {
                stdout: (data: Buffer) => {
                    writeSync(fd, data);
                },
                stderr: (data: Buffer) => {
                    process.stderr.write(data);
                },
            },
        });
    } finally {
        closeSync(fd);
    }
}

export async function run(): Promise<void> {
    try {
        const inputs = getInputs();

        const workspace = process.env.GITHUB_WORKSPACE || ".";

        core.info("Running validations...");
        validateInputs({ ...inputs, workspace });

        // Write to the same workspace-relative path that was validated.
        const outputPath = inputs.outputFile ? resolve(workspace, inputs.outputFile) : "";

        core.info("Building govulncheck arguments...");
        const args = buildArgs(inputs);

        core.info(`Running govulncheck with arguments: ${args.join(" ")}`);
        const exitCode = outputPath
            ? await runToFile(args, outputPath)
            : await exec.exec("govulncheck", args, { ignoreReturnCode: true });

        if (exitCode !== 0) {
            core.setFailed(`govulncheck exited with code ${exitCode}`);
            process.exitCode = exitCode;
            return;
        }

        // Apply SARIF workaround if needed (https://github.com/golang/go/issues/75890)
        if (outputPath && inputs.outputFormat === "sarif") {
            core.info("Applying SARIF duplicate tags and stacks fix...");
            fixSarif(outputPath);
            core.info("SARIF duplicate tags and stacks fixed");
        }

        core.info("govulncheck completed successfully");
    } catch (err) {
        core.setFailed(err instanceof Error ? err.message : String(err));
    }
}
