-- Saying something from a mod verb on Gen 2.
--
-- Vm:showText takes a text KEY and looks it up in the cache's text table
-- (Gold's ids are ROM pointer strings like "55:4067"); a key it cannot
-- find falls back to the literal string "..." rather than raising.  So
-- passing a sentence straight in silently prints "..." -- the state
-- changes land, the words never do, and only a screenshot catches it.
--
-- The fix is to put the sentence in the table first and then name it.
-- vm.text is the same merged table the `text` registry writes to, so a
-- line parked there resolves exactly like an extracted one.  Keys rotate
-- so a box still on screen is never overwritten underneath itself.
local Dialogue = {}

local counter = 0

function Dialogue.say(ctx, body)
  if not (ctx and ctx.vm and type(body) == "string") then return false end
  local vm = ctx.vm
  if type(vm.text) ~= "table" or type(vm.showText) ~= "function" then
    return false
  end
  counter = (counter + 1) % 64
  local key = "showa:say:" .. counter
  vm.text[key] = body
  vm:showText(key)
  return true
end

-- What a verb actually put on screen last, for a driver to assert on:
-- the whole point of this module is that the state changing is not
-- evidence the words arrived.
function Dialogue.lastShown(ctx)
  local vm = ctx and ctx.vm
  if not (vm and vm.lastTextKey) then return nil end
  return vm.text and vm.text[vm.lastTextKey]
end

return Dialogue
