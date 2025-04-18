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

        public CmdCommandResponse()
        {
            Output = string.Empty; // Initialize Output to an empty string
        }
    }
}
