AddCSLuaFile()

if SERVER then return end
if not system.IsWindows() then return end

local SnowSystem = {
    Enabled = CreateClientConVar("snowflakes_enabled", "1", true, false),
    TextureEnabled = CreateClientConVar("snow_texture_enabled", "1", true, false),
    Emitter = ParticleEmitter(Vector(), false),
    Materials = {
        Whitelist = {grass = true, dirt = true, paper = true, antlionsand = true},
        Replaced = {},
        Original = {}
    },
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
    RestoreMaterials()
end)

local math_Rand = math.Rand
local Vector = Vector
local EyePos = EyePos
local util_QuickTrace = util.QuickTrace

local function ApplySnowMaterial(mat)
    if not IsValid(mat) or SnowSystem.Materials.Replaced[mat:GetName()] then return end
    
    if not SnowSystem.Materials.Original[mat:GetName()] then
        SnowSystem.Materials.Original[mat:GetName()] = {
            texture = mat:GetTexture("$basetexture"),
            texture2 = mat:GetTexture("$basetexture2"),
            color = mat:GetVector("$color2") or Vector(1, 1, 1)
        }
    }

    mat:SetTexture("$basetexture", "nature/snowfloor001a")
    mat:SetTexture("$basetexture2", "nature/snowfloor001a")
    mat:SetVector("$color2", Vector(0.6, 0.6, 0.6))
    SnowSystem.Materials.Replaced[mat:GetName()] = true
end

local function RestoreMaterials()
    for name, data in pairs(SnowSystem.Materials.Original) do
        local mat = Material(name)
        if IsValid(mat) then
            mat:SetTexture("$basetexture", data.texture)
            mat:SetTexture("$basetexture2", data.texture2)
            mat:SetVector("$color2", data.color)
        end
    end
    SnowSystem.Materials.Replaced = {}
    SnowSystem.Materials.Original = {}
end

local function ReplaceSurfaceMaterials()
    local world = game.GetWorld()
    for _, surface in pairs(world:GetBrushSurfaces()) do
        local mat = surface:GetMaterial()
        if IsValid(mat) then
            local surface_prop = string.lower(mat:GetString("$surfaceprop") or "")
            if SnowSystem.Materials.Whitelist[surface_prop] then
                ApplySnowMaterial(mat)
            end
        end
    end

    local flatgrass = Material("infmap/flatgrass")
    if flatgrass then
        ApplySnowMaterial(flatgrass)
    end
end

local TextureReplacements = {
    ["maps/rp_bangclaw_test22222/concrete/concretefloor033k_c17_3224_-2651_560"] = "concrete/concretefloor033k",
}

local function ReplaceSpecificTextures(enable)
    for original, replacement in pairs(TextureReplacements) do
        local mat = Material(original)
        if IsValid(mat) then
            if enable then
                mat:SetTexture("$basetexture", "nature/snowfloor001a")
            else
                mat:SetTexture("$basetexture", replacement)
            end
        end
    end
end

hook.Add("InitPostEntity", "SnowInitialize", function()
    ReplaceSurfaceMaterials()
    ReplaceSpecificTextures(SnowSystem.TextureEnabled:GetBool())
    
    timer.Create("SnowRetryMaterials", 5, 3, function()
        ReplaceSurfaceMaterials()
        ReplaceSpecificTextures(SnowSystem.TextureEnabled:GetBool())
    end)
end)

local function CreateSnowflake(start_pos)
    local particle = SnowSystem.Emitter:Add("particle/particle_glow_04", start_pos)
    if not particle then return end

    local tr = util_QuickTrace(start_pos, Vector(0, 0, -2000))
    local life_time = (start_pos.z - tr.HitPos.z) * 0.0035
    
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
    if not util.IsSkyboxVisibleFromPoint(eye_pos) then return end

    for _ = 1, SnowSystem.Particles.Density do
        local start_pos = eye_pos + Vector(
            math_Rand(-SnowSystem.Particles.Spread, SnowSystem.Particles.Spread),
            math_Rand(-SnowSystem.Particles.Spread, SnowSystem.Particles.Spread),
            math_Rand(SnowSystem.Particles.Height.min, SnowSystem.Particles.Height.max)
        )
        CreateSnowflake(start_pos)
    end
end)

-- Fog system
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
    
    if new_state then
        ReplaceSurfaceMaterials()
        ReplaceSpecificTextures(true)
    else
        RestoreMaterials()
        ReplaceSpecificTextures(false)
    end
    
    chat.AddText(
        Color(255, 0, 0), "[Snow System] ",
        Color(255, 255, 255), new_state and "Snow enabled!" or "Snow disabled!"
    )
end)