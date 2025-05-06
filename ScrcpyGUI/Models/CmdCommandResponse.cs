using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ScrcpyGUI.Models
{
    public class CmdCommandResponse
    {
        public string Output { get; set; }
        public string RawError { get; set; }
        public string RawOutput { get; set; }
        public int ExitCode { get; set; }

        public CmdCommandResponse()
        {
            Output = string.Empty; // Initialize Output to an empty string
            RawError = string.Empty; // Initialize RawError to an empty string
            RawOutput = string.Empty; // Initialize RawOutput to an empty string
        }
    }
}
