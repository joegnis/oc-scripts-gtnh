local utils = require "utils"

local inheritsFrom = utils.inheritsFrom
local isInstance = utils.isInstance


-- An empty table used in super() for example
local NOT_PROVIDED = {}

---@class Base1
---@field v1 integer
local Base1 = {}
Base1.class = function() return Base1 end
Base1.super = function () return NOT_PROVIDED end

---@param v1 integer?
function Base1:new(v1)
  local o = {}
  self.__index = self
  o = setmetatable(o, self)

  o.v1 = v1 or 0

  return o
end

---@class Class1: Base1
local Class1 = inheritsFrom(Base1)
Class1.class = function() return Class1 end
Class1.super = function() return Base1 end

---@param v1 integer?
function Class1:new(v1)
  local o = {}
  -- Have to use parent class directly instead of self.super()
  -- Pass in self as the first parameter to properly set metatable
  o = Base1.new(self, v1)
  return o
end

---@class Class2: Class1
local Class2 = inheritsFrom(Class1)
Class2.class = function() return Class2 end
Class2.super = function() return Class1 end

function Class2:new(v1)
  local o = {}
  o = Class1.new(self, v1)
  return o
end

describe("Basic functions can", function()
  it("create multiple distinct instances of same class", function()
    local inst1 = Base1:new()
    local inst2 = Base1:new(2)

    assert.are.equal(0, inst1.v1)
    assert.are.equal(2, inst2.v1)

    inst1.v1 = 3
    assert.are.equal(3, inst1.v1)
    assert.are.equal(2, inst2.v1)
  end)

  it("test if an object is an instance of a class", function()
    local instB1 = Base1:new()
    local instC1 = Class1:new()
    local instC2 = Class2:new()

    assert.is_true(isInstance(instB1, Base1))
    assert.is_true(isInstance(instC1, Class1))
    -- Can also check through the inheritance chain
    assert.is_true(isInstance(instC1, Base1))
    assert.is_false(isInstance(instB1, Class1))
    assert.is_true(isInstance(instC2, Class1))
  end)

  it("get current class and parent class", function()
    local instB1 = Base1:new()
    local instC1 = Class1:new()

    assert.are.equal(Base1, instB1.class())
    assert.are.equal(Base1, instC1.super())
    assert.are.equal(Class1, instC1.class())
    assert.are.equal(NOT_PROVIDED, instB1.super())
  end)
end)

describe("Inheritance", function()
  it("can have up to depth 1", function()
    local inst1 = Class1:new(1)
    assert.are.equal(1, inst1.v1)
    assert.are.equal(Class1, inst1.class())
    assert.are.equal(Base1, inst1.super())
    assert.is_true(isInstance(inst1, Class1))
    assert.is_true(isInstance(inst1, Base1))
    assert.is_false(isInstance(inst1, Class2))
  end)

  it("can have up to depth 2", function()
    local inst2 = Class2:new(2)
    assert.are.equal(2, inst2.v1)
    assert.are.equal(Class2, inst2.class())
    assert.are.equal(Class1, inst2.super())
    assert.is_true(isInstance(inst2, Class2))
    assert.is_true(isInstance(inst2, Class1))
    assert.is_true(isInstance(inst2, Base1))
    assert.is_false(isInstance(inst2, NOT_PROVIDED))
  end)
end)

describe("Traps include", function()
  it("foobar", function()
    ---@class Test: Base1
    local Test = inheritsFrom(Base1)

    function Test:new(v1)
      local o = {}
      o = Base1.new(self, v1)
      return o
    end

    local testInst = Test:new(3)
    assert.are.equal(3, testInst.v1)
    assert.is_true(isInstance(testInst, Test))
    assert.is_true(isInstance(testInst, Base1))
  end)
end)
