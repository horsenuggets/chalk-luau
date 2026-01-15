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

        it("should restore outer style after nested reset", function()
            local ENTRY_POINT = "main.luau"
            local result = Chalk.dim(`Entry point is {Chalk.reset(ENTRY_POINT)}.`)
            -- The "." at the end should still be dim, not reset
            -- dim open: \27[2m, dim close: \27[22m, reset: \27[0m
            -- Reset makes "main.luau" appear in normal/default style, then dim resumes
            local expected = "\27[2mEntry point is \27[0mmain.luau\27[2m.\27[22m"
            expect(result).to.equal(expected)
        end)

        it("should handle nested styles without reset", function()
            local result = Chalk.dim(`Hello {Chalk.bold("world")}!`)
            -- bold close is \27[22m which is same as dim close, so dim re-opens after it
            local expected = "\27[2mHello \27[1mworld\27[22m\27[2m!\27[22m"
            expect(result).to.equal(expected)
        end)
    end)
end
