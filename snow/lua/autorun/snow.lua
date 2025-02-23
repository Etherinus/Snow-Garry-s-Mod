AddCSLuaFile()

if SERVER then return end
if not system.IsWindows() then return end

local SnowSystem = {
    Enabled = CreateClientConVar("snowflakes_enabled", "1", true, false),
    Emitter = ParticleEmitter(Vector(), false),
    Particles = {
        Density = 10,
        Size = {min = 5, max = 10},
        Wind = Vector(0, 0, -600),
        Spread = 3000,
        Height = {min = 1000, max = 2000}
    },
    Fog = {
        Color = Vector(240, 240, 240),
        Distance = 20000,
        Density = 1
    }
}

hook.Add("OnReloaded", "SnowCleanup", function()
    if SnowSystem.Emitter then
        SnowSystem.Emitter:Finish()
        SnowSystem.Emitter = nil
    end
end)

local math_Rand = math.Rand
local Vector = Vector
local EyePos = EyePos
local util_QuickTrace = util.QuickTrace
local IsSkyboxVisibleFromPoint = util.IsSkyboxVisibleFromPoint

local function CreateSnowflake(start_pos)
    if not SnowSystem.Emitter then
        SnowSystem.Emitter = ParticleEmitter(start_pos, false)
    end

    local particle = SnowSystem.Emitter:Add("particle/particle_glow_04", start_pos)
    if not particle then return end

    local traceEnd = Vector(0, 0, -2000)
    local tr = util_QuickTrace(start_pos, traceEnd)
    local life_time = (start_pos.z - tr.HitPos.z) * 0.0035
    if not tr.Hit then
        life_time = 10
    end

    particle:SetDieTime(math.min(life_time, 10))
    particle:SetStartAlpha(255)
    particle:SetEndAlpha(255)
    particle:SetAirResistance(120)
    
    local size = math_Rand(SnowSystem.Particles.Size.min, SnowSystem.Particles.Size.max)
    particle:SetStartSize(size)
    particle:SetEndSize(size)
    
    particle:SetVelocity(SnowSystem.Particles.Wind)
    particle:SetGravity(SnowSystem.Particles.Wind)
end

hook.Add("Think", "SnowSpawn", function()
    if not SnowSystem.Enabled:GetBool() then return end

    local eye_pos = EyePos()
    if not IsSkyboxVisibleFromPoint(eye_pos) then return end

    for _ = 1, SnowSystem.Particles.Density do
        local start_pos = eye_pos + Vector(
            math_Rand(-SnowSystem.Particles.Spread, SnowSystem.Particles.Spread),
            math_Rand(-SnowSystem.Particles.Spread, SnowSystem.Particles.Spread),
            math_Rand(SnowSystem.Particles.Height.min, SnowSystem.Particles.Height.max)
        )
        CreateSnowflake(start_pos)
    end
end)

local function ConfigureFog()
    render.FogMode(MATERIAL_FOG_LINEAR)
    render.FogStart(0)
    render.FogEnd(SnowSystem.Fog.Distance)
    render.FogMaxDensity(SnowSystem.Fog.Density)
    render.FogColor(SnowSystem.Fog.Color:Unpack())
    return true
end

hook.Add("SetupWorldFog", "SnowFog", ConfigureFog)
hook.Add("SetupSkyboxFog", "SnowFog", ConfigureFog)

concommand.Add("enablesnow", function()
    local new_state = not SnowSystem.Enabled:GetBool()
    SnowSystem.Enabled:SetBool(new_state)
    
    chat.AddText(
        Color(255, 0, 0), "[Snow System] ",
        Color(255, 255, 255), new_state and "Snow enabled!" or "Snow disabled!"
    )
end)
