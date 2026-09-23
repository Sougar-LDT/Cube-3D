--Make it so i can use ANSI escape code in classic window terminal
os.execute("reg add HKCU\\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1")
--//Modules//--
local vector3 = require('Class.vector3')
local vector2 = require('Class.vector2')
local round = require('Functionnal.round')
--//Constants//--
--[[
local ROWS = 51
local COLUMNS = 150
]]
local SHOW_VERTICES = false
local ROWS = 39 -- y
local COLUMNS = 127 -- x
local CUBE_SCALE = 80
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
    {2,4,8},
    --left
    {1,3,7},
    {1,7,5},
    --front
    {5,7,8},
    {5,6,7},
    --top
    {5,1,2},
    {5,2,6},
    --bottom
    {7,8,4},
    {7,4,3},
}
local SYMBOLS = ".#@£$%!§?]|<"
--//Variables//--
local screen = {}
local rotationX,rotationY,rotationZ = 0,0,0
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
        --print(y,i)
        screen[y][i] = symbol
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
    --print(round(top.y),round(bottom1.y))
    for y = round(top.y),round(bottom1.y) do
        --print(y,round(xBeginning),round(xEnd))
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
        v1.x/v1.z + COLUMNS/2,
        v1.y/v1.z + ROWS/2
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
            local cubeVertice = vector3.new(transformedVertices[i].x,transformedVertices[i].y,transformedVertices[i].z)
            local xValue = cubeVertice.x
            local yValue = cubeVertice.y
            local zValue = cubeVertice.z
            --Rotate
            --rotateAroundX(transformedVertices[i],rx)
           
            --rotateAroundZ(transformedVertices[i],rx)
            --Push it into the screen
            transformedVertices[i].z = zValue + 8
            transformedVertices[i].x = xValue * CUBE_SCALE*2
            transformedVertices[i].y = yValue * CUBE_SCALE
        end

        --[[
        
        ]]
        local projectedPoints = {}
        for i = 1,3 do
            projectedPoints[i] = projectToCenter2D(transformedVertices[i])
        end
        --SYMBOLS:sub(triangleIndex,triangleIndex)
        drawTriangle(projectedPoints[1],projectedPoints[2],projectedPoints[3],'*')
        --back face culling
    end
end

local function displayScreen()
    for row = 1,ROWS do
        local offset = 3 + (row - 1) * (COLUMNS + 1)
        for i = 1, COLUMNS do
            BUFFER[offset + i] = screen[row][i]
        end
        if row < ROWS then
           BUFFER[offset + COLUMNS + 1] = '\n' 
        end
    end
    io.write(table.concat(BUFFER))
end

local function busy_wait(seconds)
    local start = os.clock()
    while os.clock() - start < seconds do
        --Doing nothing, just burning CPU cycles
    end
end

local function clearScreen()
    for row = 1, ROWS do
        screen[row] = {}
        for column = 1,COLUMNS do
            screen[row][column] = ' '
        end
    end
end

--//Setup//--
--Clear terminal (and potentially hide cursor : x1B[?25l instead of x1B[?25h)
io.write("\x1B[2J\x1B[?25l")
--Put cursor at top left corner (0,0)
BUFFER[1] = '\x1B'
BUFFER[2] = '['
BUFFER[3] = 'H'
--//Main Loop//--
while true do
    clearScreen()
    
    --[[
        screen[20][30] = '0'
        screen[30][50] = '0'
        screen[20][60] = '0'
        drawFlatBottom(vector2.new(60,10),vector2.new(60,20),vector2.new(90,20))
    drawFlatTop(vector2.new(90,20),vector2.new(90,10),vector2.new(60,10))
    ]]
    drawCube(0,rotationY,0)
    rotationY = (rotationY + math.rad(0.1)) % (2*math.pi)
    displayScreen()
end