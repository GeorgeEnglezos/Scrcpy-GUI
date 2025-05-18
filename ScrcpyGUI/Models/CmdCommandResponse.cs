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
            Output = string.Empty;
            RawError = string.Empty;
            RawOutput = string.Empty;
        }
    }
}
