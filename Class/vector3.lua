local vector3 = {}
vector3.__index = vector3
--//Types//--
---@class Vector3
---@field x number
---@field y number
---@field z number
---@field clone fun(self : Vector3) : Vector3
--//Constants//--

--//Variables//--

--//Private Functions//--

--//Methods//--

--<b>Vector3</b> constructor
---@param x number?
---@param y number?
---@param z number?
---@return Vector3
function vector3.new(x,y,z)
    local self = setmetatable({},vector3)
    self.x = x or 0
    self.y = y or 0
    self.z = z or 0
    return self
end
---@param self Vector3
---@return Vector3
function vector3.clone(self)
    return vector3.new(self.x,self.y,self.z)
end

return vector3