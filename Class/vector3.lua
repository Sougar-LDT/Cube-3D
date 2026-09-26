local vector3 = {}
vector3.__index = vector3
---@param self Vector3
vector3.__tostring = function(self)
    return ("x : %f, y : %f, z : %f"):format(self.x,self.y,self.z)
end
--//Types//--
---@class Vector3
---@field x number
---@field y number
---@field z number
---@field magnitude number
---@field clone fun(self : Vector3) : Vector3
---@field dot fun(self : Vector3,v1 : Vector3) : number
---@field cross fun(self : Vector3,v1 : Vector3) : Vector3 
---@field normalize fun(self : Vector3) : Vector3 
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
    self.magnitude = math.sqrt(self.x^2 + self.y^2 + self.z^2)
    return self
end
---@param self Vector3
---@return Vector3
function vector3.clone(self)
    return vector3.new(self.x,self.y,self.z)
end
---@param self Vector3
---@return Vector3
function vector3.normalize(self)
    return vector3.new(
        self.x/self.magnitude,
        self.y/self.magnitude,
        self.z/self.magnitude
    )
end
---@param self Vector3
---@param v1 Vector3
---@return Vector3
function vector3.cross(self,v1)
    return vector3.new(
        (self.y * v1.z) - (self.z * v1.y),
        (self.z * v1.x) - (self.x * v1.z),
        (self.x * v1.y) - (self.y * v1.x)
    )
end
---@param self Vector3
---@param v1 Vector3
---@return number
function vector3.dot(self,v1)
    return self.x * v1.x + self.y * v1.y + self.z * v1.z
end


return vector3