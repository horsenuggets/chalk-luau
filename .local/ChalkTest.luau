--[[

ChalkTest

Manual test script for Chalk terminal string styling.

--]]

local Chalk = require("../Source/Chalk")

print(Chalk.blueBright("This text is blue and bright!"))
print(Chalk.blue("This text is blue!"))
print(Chalk.rgb(123, 45, 67)("This text is in a custom RGB color!"))
