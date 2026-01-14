--[[

ChalkTest

Tests for the Chalk terminal styling library.

--]]

return function()
    describe("Chalk", function()
        local Chalk = require("../Source/Chalk")

        it("should style text with red foreground color", function()
            local redText = Chalk.red("This is red text")
            expect(redText).to.equal("\27[31mThis is red text\27[39m")
        end)

        it("should style text with bold modifier", function()
            local boldText = Chalk.bold("This is bold text")
            expect(boldText).to.equal("\27[1mThis is bold text\27[22m")
        end)

        it("should return empty string for nil input", function()
            local result = Chalk.red(nil)
            expect(result).to.equal("")
        end)

        it("should return empty string for empty string input", function()
            local result = Chalk.red("")
            expect(result).to.equal("")
        end)
    end)
end
