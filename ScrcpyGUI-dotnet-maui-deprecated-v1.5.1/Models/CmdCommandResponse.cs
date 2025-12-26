using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ScrcpyGUI.Models
{
    /// <summary>
    /// Represents the response from a command-line execution.
    /// DEPRECATED: This .NET MAUI application is being replaced by a Flutter version.
    /// Captures output, errors, and exit codes from CMD/ADB/Scrcpy commands.
    /// </summary>
    public class CmdCommandResponse
    {
        /// <summary>
        /// Gets or sets the processed output (prioritizes error output if present).
        /// </summary>
        public string Output { get; set; }

        /// <summary>
        /// Gets or sets the raw standard error stream output.
        /// </summary>
        public string RawError { get; set; }

        /// <summary>
        /// Gets or sets the raw standard output stream output.
        /// </summary>
        public string RawOutput { get; set; }

        /// <summary>
        /// Gets or sets the exit code returned by the command process.
        /// </summary>
        public int ExitCode { get; set; }

        /// <summary>
        /// Initializes a new instance of the CmdCommandResponse class with empty strings.
        /// </summary>
        public CmdCommandResponse()
        {
            Output = string.Empty;
            RawError = string.Empty;
            RawOutput = string.Empty;
        }
    }
}
