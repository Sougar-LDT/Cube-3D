--Make it so i can use ANSI escape code in classic window terminal
os.execute("reg add HKCU\\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1")
--//Modules//--
local vector3 = require('Class.vector3')
local vector2 = require('Class.vector2')
local round = require('Functionnal.round')
local setWindowSize = require('Functionnal.setWindowSize')
local getCmdWindowSize = require('Functionnal.getCmdWindowSize')
--//Configurations//--
local ROTATION_SPEEDS = {
    X = 0.2,
    Y = 0.2,
    Z = 0.2,
}
local SHOW_VERTICES = false
local CUBE_SCALE_FACTOR = 0.4
--//Constants//--
local CAMERA_DIRECTION = vector3.new(0,0,1)
local BUFFER = {}
local CUBE_VERTICES = {
    vector3.new(-1,1,-1), -- 1
    vector3.new(1,1,-1), -- 2
    vector3.new(-1,-1,-1), -- 3
    vector3.new(1,-1,-1), -- 4

    vector3.new(-1,1,1), -- 5
    vector3.new(1,1,1), -- 6
    vector3.new(-1,-1,1), -- 7
    vector3.new(1,-1,1), -- 8
}
local CUBE_TRIANGLES = {
    --back
    {1,2,4},
    {1,4,3},
    --right
    {2,6,8},
    {2,8,4},
    --left
    {1,3,7},
    {1,7,5},
    --front
    {5,7,8},
    {6,5,8},
    --top
    {5,2,1},
    {5,6,2},
    --bottom
    {7,4,8},
    {7,3,4},
}

local SYMBOLS = "@$#*!=;:~-,."
local MINIMUM_DIMENSION = 20
--//Variables//--
local screen = {}
local rows = nil-- y
local columns = nil -- x
local rotationX,rotationY,rotationZ = 0,0,0
local drawTimeElapsed = nil
local timePerFrame = nil
--//Functions//--

---@param y number
---@param x0 number
---@param x1 number
---@param symbol string
local function drawLine(y,x0,x1,symbol)
    local left = x0
    local right = x1
    if left > right then
        left = x1
        right = x0
    end
    for i = left,right do
        if not screen[y] then
            goto continue
        end
        screen[y][i] = symbol
        ::continue::
    end
end

---@param top Vector2
---@param bottom1 Vector2
---@param bottom2 Vector2
---@param symbol string
local function drawFlatBottom(top,bottom1,bottom2,symbol)
    local xBeginning = top.x
    local xEnd = top.x
    local side1Slope = -(top.x - bottom1.x)/(top.y - bottom1.y)
    local side2Slope = -(top.x - bottom2.x)/(top.y - bottom2.y)
    for y = round(top.y),round(bottom1.y) do
        drawLine(y,round(xBeginning),round(xEnd),symbol)
        xBeginning = xBeginning - side1Slope
        xEnd = xEnd - side2Slope
    end
    if SHOW_VERTICES then
        screen[top.y][top.x] = '%'
        screen[bottom1.y][bottom1.x] = '%'
        screen[bottom2.y][bottom2.x] = '%'
    end
end

---@param bottom Vector2
---@param top1 Vector2
---@param top2 Vector2
---@param symbol string
local function drawFlatTop(bottom,top1,top2,symbol)
    local xBeginning = bottom.x
    local xEnd = bottom.x
    local side1Slope = (bottom.x - top1.x)/(bottom.y-top1.y)
    local side2Slope = (bottom.x - top2.x)/(bottom.y-top2.y)
    for y = round(bottom.y),round(top1.y),-1 do
        drawLine(y,round(xBeginning),round(xEnd),symbol)
        xBeginning = xBeginning - side1Slope
        xEnd = xEnd - side2Slope
    end
    if SHOW_VERTICES then
        screen[bottom.y][bottom.x] = '%'
        screen[top1.y][top1.x] = '%'
        screen[top2.y][top2.x] = '%'
    end
end

--Max : <b>3 vertices</b>
---@param ... Vector2
local function getTriangleDescendingYVertices(...)
    local top0,vertices = vector2.minY(...)
    local top1,vertices = vector2.minY(table.unpack(vertices))
    local top2 = vertices[1]
    return top0,top1,top2
end

---@param v1 Vector2
---@param v2 Vector2
---@param v3 Vector2
---@param symbol string
local function drawTriangle(v1,v2,v3,symbol)
    local vertex1,vertex2,vertex3 = getTriangleDescendingYVertices(table.unpack({v1,v2,v3}))
    local xMidpoint = round(vertex1.x + (vertex2.y - vertex1.y)/(vertex3.y - vertex1.y)*(vertex3.x - vertex1.x))
    local midpoint = vector2.new(xMidpoint,vertex2.y)
    drawFlatBottom(vertex1,midpoint,vertex2,symbol)
    drawFlatTop(vertex3,midpoint,vertex2,symbol)
end

---@param v1 Vector3
---@return Vector2
local function projectToCenter2D(v1)
    return vector2.new(
        v1.x/v1.z + columns/2,
        v1.y/v1.z + rows/2
    ):round()
end

---@param v1 Vector3
---@param angle number
---@return Vector3
local function rotateAroundY(v1,angle)
    return vector3.new(
        v1.x*math.cos(angle) + math.sin(angle)*v1.z,
        v1.y,
        v1.x*-math.sin(angle) + math.cos(angle)*v1.z
    )
end

---@param v1 Vector3
---@param angle number
---@return Vector3
local function rotateAroundX(v1,angle)
    return vector3.new(
        v1.x,
        v1.y*math.cos(angle) + -math.sin(angle)*v1.z,
        v1.y*math.sin(angle) + math.cos(angle)*v1.z
    )
end

---@param v1 Vector3
---@param angle number
---@return Vector3
local function rotateAroundZ(v1,angle)
    return vector3.new(
        v1.y*-math.sin(angle) + math.cos(angle)*v1.x,
        v1.y*math.cos(angle) + math.sin(angle)*v1.x,
        v1.z
    )
end
---@param rx number  
---@param ry number
---@param rz number
local function drawCube(rx,ry,rz)
    for triangleIndex,triangle in pairs(CUBE_TRIANGLES) do
        ---@type Vector3[]
        local transformedVertices = {}
        for i = 1,3 do
            transformedVertices[i] = CUBE_VERTICES[triangle[i]]:clone()
            transformedVertices[i] = rotateAroundY(transformedVertices[i],ry)
            transformedVertices[i] = rotateAroundX(transformedVertices[i],rx)
            transformedVertices[i] = rotateAroundZ(transformedVertices[i],rz)
            local cubeVertice = vector3.new(transformedVertices[i].x,transformedVertices[i].y,transformedVertices[i].z)
            local xValue = cubeVertice.x
            local yValue = cubeVertice.y
            local zValue = cubeVertice.z
            local CUBE_SCALE = (rows+columns)*CUBE_SCALE_FACTOR
            --Push it into the screen
            transformedVertices[i].z = zValue + 8
            --Scale
            transformedVertices[i].x = xValue * CUBE_SCALE*2
            transformedVertices[i].y = yValue * CUBE_SCALE
        end
        local transformedDisplacement1 = vector3.new(
            (transformedVertices[2].x - transformedVertices[1].x),
            (transformedVertices[2].y - transformedVertices[1].y),
            (transformedVertices[2].z - transformedVertices[1].z)
        )
        local transformedDisplacement2 = vector3.new(
            (transformedVertices[3].x - transformedVertices[1].x),
            (transformedVertices[3].y - transformedVertices[1].y),
            (transformedVertices[3].z - transformedVertices[1].z)
        )
        local normal = transformedDisplacement1:cross(transformedDisplacement2)
        local dot = CAMERA_DIRECTION:dot(normal)
        if dot >= 0 then
            goto continue
        end
        local projectedPoints = {}
        for i = 1,3 do
            projectedPoints[i] = projectToCenter2D(transformedVertices[i])
        end
        local lightLevel = round((dot*5)/20000)
        local symbol = SYMBOLS:sub(lightLevel,lightLevel)
        if symbol == "" then
            symbol = SYMBOLS:sub(1,1)
        end
        drawTriangle(projectedPoints[1],projectedPoints[2],projectedPoints[3],symbol)
        --back face culling
        ::continue::
    end
end

local function displayScreen()
    BUFFER = {}
    BUFFER[1] = '\x1B'
    BUFFER[2] = '['
    BUFFER[3] = 'H'
    for row = 1,rows do
        local offset = 3 + (row - 1) * (columns + 1)
        for i = 1, columns do
            BUFFER[offset + i] = screen[row][i]
        end
        if row < rows then
           BUFFER[offset + columns + 1] = '\n' 
        end
    end
    io.write(table.concat(BUFFER))
end

local function busy_wait(seconds)
    local start = os.clock()
    while os.clock() - start < seconds do
        --Doing nothing just burning CPU cycles
    end
end

local function clearScreen()
    screen = {}
    for row = 1, rows do
        screen[row] = {}
        for column = 1,columns do
            screen[row][column] = ' '
        end
    end
end

---@param fps number
local function setTargetFps(fps)
    drawTimeElapsed = os.clock()
    timePerFrame = 1/fps
end

---@return number
local function getDeltaTime()
    local deltaTime = os.clock() - drawTimeElapsed
    drawTimeElapsed = os.clock()
    local sleepTime = timePerFrame - deltaTime
    if sleepTime > 0 then
        busy_wait(sleepTime)
        return 1
    end
    return deltaTime
end

local function init()
    local dimensions = getCmdWindowSize()
    io.write("Enter window width (default : auto) : ")
    local width = tonumber(io.read()) or dimensions.width
    io.write("Enter window height (default : auto) : ")
    local height = tonumber(io.read()) or dimensions.height
    if width < MINIMUM_DIMENSION then
        print("Width too small, fallback to auto")
        width = dimensions.width
    end
    if height < MINIMUM_DIMENSION then
        print("Height too small, fallback to auto")
        height = dimensions.height
    end
    rows = height
    columns = width
    setWindowSize(width,height)
end

--//Setup//--
init()
--Clear terminal (and potentially hide cursor : x1B[?25l instead of x1B[?25h)
io.write("\x1B[2J\x1B[?25h")
--Put cursor at top left corner (0,0)
BUFFER[1] = '\x1B'
BUFFER[2] = '['
BUFFER[3] = 'H'
--//Main Loop//--
setTargetFps(144)
while true do
    local delta = getDeltaTime()
    clearScreen()
    drawCube(rotationX,rotationY,rotationZ)
    rotationX = (rotationX + math.rad(ROTATION_SPEEDS.X*delta)) % (2*math.pi)
    rotationY = (rotationY + math.rad(ROTATION_SPEEDS.Y*delta)) % (2*math.pi)
    rotationZ = (rotationZ + math.rad(ROTATION_SPEEDS.Z*delta)) % (2*math.pi)
    displayScreen()
end