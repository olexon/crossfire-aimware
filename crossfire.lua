--[[

   Thanks to:                                                                                                                        
   @2878713023 for his valorant kill gif lua, his code helped me with positioning of the killmark and making it disappear after time 
   @stacky for his "third party files loaded" bypass

]]

local cache = {
    victim_idx = nil,
    hsed = false,
    event_kill = false,
    timestamp = 0,
    counter = 0,
    killcount = 0,
}

first_f = file.Open("crossfire_pictures/first.png", "r")
second_f = file.Open("crossfire_pictures/second.png", "r")
third_f = file.Open("crossfire_pictures/third.png", "r")
fourth_f = file.Open("crossfire_pictures/fourth.png", "r")
fifth_f = file.Open("crossfire_pictures/fifth.png", "r")
sixth_f = file.Open("crossfire_pictures/sixth.png", "r")
headshot_f = file.Open("crossfire_pictures/hs.png", "r")

local pictures = {
    first = first_f:Read(),
    second = second_f:Read(),
    third = third_f:Read(),
    fourth = fourth_f:Read(),
    fifth = fifth_f:Read(),
    sixth = sixth_f:Read(),
    headshot = headshot_f:Read(),
}

first_f:Close()
second_f:Close()
third_f:Close()
fourth_f:Close()
fifth_f:Close()
sixth_f:Close()
headshot_f:Close()

local texture = draw.CreateTexture(common.DecodePNG(pictures.first))

local function main(event)
    if event then
        if event:GetName() == "player_hurt" then
            local lp_index = client.GetLocalPlayerIndex()
            
            local attacker_index = client.GetPlayerIndexByUserID(event:GetInt("attacker"))
            local victim_index = client.GetPlayerIndexByUserID(event:GetInt("userid"))
                        
            if (attacker_index == lp_index and victim_index ~= lp_index) then
                local hitgroup = event:GetInt("hitgroup")

                if (hitgroup == 1) then
                    cache.victim_idx = victim_index
                    cache.hsed = true
                else
                    client.Command("play crossfire/1", true)
                end
            end
        elseif event:GetName() == "player_death" then
            local lp_index = client.GetLocalPlayerIndex()
            
            local attacker_index = client.GetPlayerIndexByUserID(event:GetInt("attacker"))
            local victim_index = client.GetPlayerIndexByUserID(event:GetInt("userid"))
                        
            if (attacker_index == lp_index and victim_index ~= lp_index) then
                cache.killcount = cache.killcount + 1

                if cache.killcount == 1 then
                    client.Command("play crossfire/1", true)
                    draw.UpdateTexture(texture, common.DecodePNG(pictures.first))
                    cache.event_kill = true
                elseif cache.killcount == 2 then
                    client.Command("play crossfire/2", true)
                    draw.UpdateTexture(texture, common.DecodePNG(pictures.second))
                    cache.event_kill = true
                elseif cache.killcount == 3 then
                    client.Command("play crossfire/3", true)
                    draw.UpdateTexture(texture, common.DecodePNG(pictures.third))
                    cache.event_kill = true
                elseif cache.killcount == 4 then
                    client.Command("play crossfire/4", true)
                    draw.UpdateTexture(texture, common.DecodePNG(pictures.fourth))
                    cache.event_kill = true
                elseif cache.killcount == 5 then
                    client.Command("play crossfire/5", true)
                    draw.UpdateTexture(texture, common.DecodePNG(pictures.fifth))
                    cache.event_kill = true
                elseif cache.killcount >= 6 then
                    client.Command("play crossfire/6", true)
                    draw.UpdateTexture(texture, common.DecodePNG(pictures.sixth))
                    cache.event_kill = true
                end
            elseif (victim_index == lp_index) then
                cache.killcount = 0
            end
        elseif  event:GetName() == "round_prestart" then
            cache.killcount = 0
        end
    end
end

local function is_alive_after_hs() -- this is just retarded but i dont know how to / cant check if victim was hs'd on player_death event lol
    if cache.victim_idx == nil then
        return
    end

    local is_alive = entities.GetByIndex(cache.victim_idx):IsAlive()

    if not is_alive and cache.hsed then  
        client.Command("play crossfire/hs", true)
        draw.UpdateTexture(texture, common.DecodePNG(pictures.headshot))
    elseif is_alive and cache.hsed then
        client.Command("play crossfire/1", true)
    end

    cache.hsed = false
    cache.victim_idx = nil
end

local function draw_killmarks()
    local screen_size = {draw.GetScreenSize()} -- X [1] Y [2]
    
    local w, h = 158, 158
    local x, y = screen_size[1] * 0.5 - w * 0.5, screen_size[2] * 0.7

    if cache.event_kill == true then
        local time = math.floor(globals.CurTime() * 1000)

        if cache.timestamp - time > 30 then
            cache.timestamp = 0
        end

        if cache.timestamp - time  < 1 then
            cache.counter = cache.counter + 1

            cache.timestamp = time + 30
        end

        draw.SetTexture(texture)
        draw.FilledRect(x, y, x + w, y + h)
    end
    if cache.counter == 75 then
        cache.event_kill = false
        cache.counter = 0
    end
end

local function remove_stock_hitsound()
    gui.SetValue("esp.world.hiteffects.sound", false)
end

local bypass_ref = gui.Reference("Misc", "General", "Bypass")
local bypass_check = gui.Checkbox(bypass_ref, "bypass_check", "Bypass Third Party Files", false)
bypass_check:SetDescription("Bypass third party files check")


-- stacky's code
ffi.cdef[[
    typedef void* (__cdecl* tCreateInterface)(const char* name, int* returnCode);
    void* GetProcAddress(void* hModule, const char* lpProcName);
    void* GetModuleHandleA(const char* lpModuleName);
]]

local function GetInterface(dll_name, interface_name)
    local CreateInterface = ffi.cast("tCreateInterface", ffi.C.GetProcAddress(ffi.C.GetModuleHandleA(dll_name), "CreateInterface"))
    local interface = CreateInterface(interface_name, ffi.new("int*"))
    return interface
end

local function bypass()
    local fileSystem = ffi.cast("int*", GetInterface("filesystem_stdio.dll", "VFileSystem017"))
    fileSystem[56] = 1
end

client.AllowListener("player_death")
client.AllowListener("player_hurt")
client.AllowListener("round_prestart")

callbacks.Register('FireGameEvent', main)
callbacks.Register('Draw', function()
    is_alive_after_hs() 
    draw_killmarks()
    remove_stock_hitsound()
    if bypass_check:GetValue() then
        bypass()
    end
end)