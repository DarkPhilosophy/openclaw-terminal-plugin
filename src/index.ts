import { exec } from "child_process";
import { promisify } from "util";

const execAsync = promisify(exec);

/**
 * OpenClaw Terminal Plugin
 * Provides direct system access via slash commands and a native web console.
 */
export default function(api) {
  // 1. Register Slash Commands
  
  // /sh <command> - Execute shell command and return output
  api.registerCommand({
    name: "sh",
    description: "Execute a shell command on the host",
    acceptsArgs: true,
    requireAuth: true,
    handler: async (ctx) => {
      const command = ctx.args?.trim();
      if (!command) {
        return { text: "Usage: /sh <command>" };
      }

      try {
        api.logger.info(`Terminal plugin executing (slash): ${command}`);
        const { stdout, stderr } = await execAsync(command, { timeout: 30000 });
        
        let response = "";
        if (stdout) {
          response += "```\n" + stdout + "\n```";
        }
        if (stderr) {
          if (response) response += "\n\n**Stderr:**\n";
          response += "```\n" + stderr + "\n```";
        }
        
        if (!response) {
          response = "Command executed successfully (no output).";
        }

        return { text: response };
      } catch (error) {
        return { text: `Error executing command:\n\`\`\`\n${error.message}\n\`\`\`` };
      }
    },
  });

  // /console - Provide a link to the integrated system console
  api.registerCommand({
    name: "console",
    description: "Get the link to the integrated system console",
    requireAuth: true,
    handler: (ctx) => {
      return { text: `📟 **Integrated System Console:** [Open Console](/console)` };
    },
  });

  // 2. Register Gateway RPC Method for Web UI
  // This allows the console.html UI to securely execute commands via the Gateway WebSocket
  api.registerGatewayMethod("terminal.exec", async ({ params, respond }) => {
    const { command } = params;
    if (!command) {
      return respond(false, { error: "No command provided" });
    }

    try {
      api.logger.info(`Terminal plugin executing (RPC): ${command}`);
      const { stdout, stderr } = await execAsync(command, { timeout: 30000 });
      respond(true, { stdout, stderr });
    } catch (error) {
      respond(false, { 
        error: error.message, 
        stdout: error.stdout, 
        stderr: error.stderr 
      });
    }
  });
}
