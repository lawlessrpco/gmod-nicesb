-- NiceScoreboard
-- By lion

-- Config
local config = {
    -- HTML Content for the title
    Title = [[<!doctypehtml><html lang=en><meta charset=UTF-8><meta content="IE=edge"http-equiv=X-UA-Compatible><meta content="width=device-width,initial-scale=1"name=viewport><style>@import url(https://fonts.googleapis.com/css2?family=Montserrat:wght@900&display=swap);*{margin:0;padding:0}body{background:url(https://static.lawlessrp.co/sleek/backgrounds/images/steve.jpg) no-repeat center center fixed;background-size:cover;font-family:Montserrat,sans-serif;backdrop-filter:blur(5px)}.inner{width:100vw;height:100vh;background:rgba(255,75,75,.25)}.inner .title{color:#fff;position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);font-size:5vw}</style><div class=inner><h3 class=title>LawlessRP.co</h3></div>]],
    Ranks = { -- Falls back to defaults if rank isnt provided
        ["superadmin"] = {"Super Administrator", Color(255, 0, 0), Material("icon16/application_xp_terminal.png")},
        ["admin"] = {"Administrator", Color(100, 37, 37), Material("icon16/star.png")},
        ["jradmin"] = {"Jr Administrator", Color(0, 255, 157), Material("icon16/star.png")},
        ["user"] = {"User", Color(0, 255, 157), Material("icon16/user.png")}
    },
    BottomBranding = "donate.lawlessrp.co",
    Margin = 5,
    Font = "Arial"
}

-- Some Utils (paralax f4)
local blur = Material("pp/blurscreen")
local panel = FindMetaTable("Panel")

function panel:NSBDrawBlur(amount, heavyness)
	local x, y = self:LocalToScreen(0, 0)
	local scrW, scrH = ScrW(), ScrH()

	surface.SetDrawColor(255,255,255)
	surface.SetMaterial(blur)

	for i = 1, heavyness do
		blur:SetFloat("$blur", (i / 3) * (amount or 6))
		blur:Recompute()

		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
	end
end

function surface.NSBDrawBlurRect(x, y, w, h, amount, heavyness)
	local X, Y = 0,0
	local scrW, scrH = ScrW(), ScrH()

	surface.SetDrawColor(255,255,255)
	surface.SetMaterial(blur)

	for i = 1, heavyness do
		blur:SetFloat("$blur", (i / 3) * (amount or 6))
		blur:Recompute()

		render.UpdateScreenEffectTexture()

		render.SetScissorRect(x, y, x+w, y+h, true)
			surface.DrawTexturedRect(X * -1, Y * -1, scrW, scrH)
		render.SetScissorRect(0, 0, 0, 0, false)
	end
end

print("NiceScoreboard loading")

nsb = {}

surface.CreateFont("NSB:Title", {
    font = "Montserrat Medium",
    weight = 500,
    size = ScreenScale(15)
})

surface.CreateFont("NSB:Detail", {
    font = "Montserrat Medium",
    weight = 500,
    size = ScreenScale(10)
})

surface.CreateFont("NSB:Warn", {
    font = "Montserrat Medium",
    weight = 500,
    size = ScreenScale(7)
})

local gradMat = Material("gui/gradient_down")
local gradMatRight = Material("gui/gradient")

if nsb.Frame then
    nsb.Frame:Remove()
end

-- Returns a sorted list of players by their team
local function getSortedPlayers()
    local sortedPlayers = {}

    for k, v in pairs(player.GetAll()) do
        if not sortedPlayers[v:Team()] then
            sortedPlayers[v:Team()] = {}
        end

        table.insert(sortedPlayers[v:Team()], v)
    end

    return sortedPlayers
end

-- Returns a count of people in a usergroup
local function getUsergroupCount(g)
    local cnt = 0

    for k, v in pairs(player.GetAll()) do
        if v:GetUserGroup() == g then
            cnt = cnt + 1
        end
    end
    return cnt
end

if IsValid(nsb.Frame) then
    nsb.Frame:Remove() -- fast reload fixer
end

-- Easy font system
-- from unity, lawlessrp custom lib
nsb.FontCache = nsb.FontCache or {}

function nsb.Font(size)
    -- Cache
    if nsb.FontCache[size] then
        return nsb.FontCache[size]
    end

    -- Make the new font
    surface.CreateFont("NSB/" .. size, {
        font = config.Font,
        size = size,
        weight = 500,
    })

    nsb.FontCache[size] = "NSB/" .. size

    return nsb.FontCache[size]
end

-- Create the f4 menu panel
local function createPanel()
    local rankFont = nsb.Font(ScreenScale(8))

    nsb.Frame = vgui.Create("DFrame")
    nsb.Frame:SetSize(ScrW() * .85, ScrH() * .85)
    nsb.Frame:SetAlpha(0)
    nsb.Frame:AlphaTo(255, 0.25, 0, nil)
    nsb.Frame:Center()
    nsb.Frame:ShowCloseButton(false)
    nsb.Frame:SetTitle("")

    nsb.Frame.Paint = function(s, w, h)
        s:NSBDrawBlur(7, 3)
        surface.SetDrawColor(0, 0, 0, 250)
        surface.DrawRect(0, 0, w, h)
    end

    function nsb.Frame.Populate()
        -- Calculate the size of the rank thing
        local rankw = 0

        for k, v in pairs(config.Ranks) do
            if getUsergroupCount(k) <= 0 then continue end
            surface.SetFont(rankFont)
            local textw, _ = surface.GetTextSize(v[1])
            rankw = math.max(rankw, textw)
        end

        if nsb.ContentPanel then
            nsb.ContentPanel:Remove()
        end
        nsb.ContentPanel = nsb.Frame:Add("Panel")
        nsb.ContentPanel:SetSize(nsb.Frame:GetWide() - config.Margin * 2, nsb.Frame:GetTall() - config.Margin * 2)
        nsb.ContentPanel:Center()

        local warn = nsb.ContentPanel:Add("DLabel")
        warn:Dock(BOTTOM)
        warn:SetContentAlignment(5)
        warn:SetColor(Color(78, 78, 78, 37))
        warn:SetText(config.BottomBranding)
        warn:SizeToContentsX(10)
        warn:SetFont("NSB:Warn")

        local titleHTML = nsb.ContentPanel:Add("DHTML")
        titleHTML:Dock(TOP)
        titleHTML:SetHTML(config.Title)
        titleHTML:DockMargin(0, 0, 0, config.Margin)
        titleHTML:SetTall(nsb.Frame:GetTall() * .15)
        titleHTML:SetMouseInputEnabled(false)

        local peoplePanel = nsb.ContentPanel:Add("DScrollPanel")
        peoplePanel:Dock(FILL)
        peoplePanel:InvalidateParent(true)

        for teamId, playerList in pairs(getSortedPlayers()) do
            local teamContent = peoplePanel:Add("DPanel")
            teamContent:Dock(TOP)
            teamContent:InvalidateParent(true)
            teamContent:DockMargin(0, 0, 0, config.Margin)
            teamContent.color_r = team.GetColor(teamId).r
            teamContent.color_g = team.GetColor(teamId).g
            teamContent.color_b = team.GetColor(teamId).b
            teamContent.outline_size = 1
            teamContent.Paint = function(s, w, h)
                surface.SetDrawColor(s.color_r, s.color_g, s.color_b)
                surface.DrawRect(0, 0, w, s.outline_size) -- top
                surface.DrawRect(0, h - s.outline_size, w, s.outline_size) -- bottom
                surface.DrawRect(0, 0, s.outline_size, h) -- left
                surface.DrawRect(w - s.outline_size, 0, s.outline_size, h) -- right
            end

            local teamTitlePanel = teamContent:Add("DPanel")
            teamTitlePanel:Dock(TOP)
            teamTitlePanel:InvalidateParent(true)
            teamTitlePanel:SetTall(30)
            teamTitlePanel.color = team.GetColor(teamId)
            teamTitlePanel.label = team.GetName(teamId)
            teamTitlePanel.count = #team.GetPlayers(teamId)
            if teamTitlePanel.count > 1 then
                teamTitlePanel.count_label = teamTitlePanel.count .. " People"
            else
                teamTitlePanel.count_label = "1 Person"
            end
            teamTitlePanel.Paint = function(s, w, h)
                draw.RoundedBox(0, 0, 0, w, h, s.color)
                draw.SimpleText(s.label, nsb.Font(ScreenScale(10)), config.Margin, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(s.count_label, nsb.Font(ScreenScale(8)), w - config.Margin, h / 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end

            for k, v in pairs(playerList) do
                local rankConfig = config.Ranks[v:GetUserGroup()] or {v:GetUserGroup(), color_white, Material("icon16/emoticon_happy.png")}
                local iconSize = 16

                local person = teamContent:Add("DButton")
                person:Dock(TOP)
                person:SetTall(40)
                person:InvalidateParent(true)
                person:DockPadding(1, 1, 1, 1)
                person:SetText("")
                person.team_color = team.GetColor(v:Team())
                person.Paint = function(s, w, h)
                    if !IsValid(v) then return end
                    if (v:SteamID() or "NULL") == LocalPlayer():SteamID() then
                        surface.SetMaterial(gradMatRight)
                        surface.SetDrawColor(s.team_color.r, s.team_color.g, s.team_color.b, 10)
                        surface.DrawTexturedRect(0, 0, w, h)
                    end
                    if s:IsHovered() then
                        draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(s.team_color, 10))
                    end
                end

                person.DoClick = function(s, w, h)
                    local menu = DermaMenu(false, s)

                    menu:AddOption("Copy SteamID", function()
                        SetClipboardText(v:SteamID() or "BOT")
                    end):SetIcon("icon16/page_white_copy.png")

                    menu:AddOption("Copy SteamID(64)", function()
                        SetClipboardText(v:SteamID64() or "BOT")
                    end):SetIcon("icon16/page_white_copy.png")

                    menu:AddSpacer()

                    menu:AddOption("Go To", function()
                        if SAM then
                            RunConsoleCommand("sam", "goto", v:SteamID() or v:Nick() or "UNKNOWN_PLAYER")
                        else
                            RunConsoleCommand("ulx", "goto", v:SteamID() or v:Nick() or "UNKNOWN_PLAYER")
                        end
                    end):SetIcon("icon16/arrow_out.png")

                    menu:AddOption("Bring", function()
                        if SAM then
                            RunConsoleCommand("sam", "bring", v:SteamID() or v:Nick() or "UNKNOWN_PLAYER")
                        else
                            RunConsoleCommand("ulx", "bring", v:SteamID() or v:Nick() or "UNKNOWN_PLAYER")
                        end
                    end):SetIcon("icon16/arrow_in.png")

                    menu:AddSpacer()

                    menu:AddOption("Exit / Close Menu"):SetIcon("icon16/stop.png")


                    menu:Open()
                end

                local avatar = person:Add("AvatarImage")
                avatar:Dock(LEFT)
                avatar:InvalidateParent(true)
                avatar:SetWide(avatar:GetTall())
                avatar:SetSteamID(v:SteamID64() or "BOT", 32)

                local cont = person:Add("DPanel")
                cont:Dock(FILL)
                cont:InvalidateParent(true)
                cont:SetMouseInputEnabled(false)

                cont.Paint = function(s, w, h)
                    if !IsValid(v) then return end
                    local my_money = LocalPlayer():getDarkRPVar("money") or 0
                    local their_money = v:getDarkRPVar("money") or 0

                    local money_color = color_white
                    if their_money > my_money then
                        money_color = Color(255, 75, 75, 100)
                    else
                        money_color = Color(75, 255, 75, 100)
                    end

                    draw.SimpleText(DarkRP.formatMoney(their_money), nsb.Font(ScreenScale(7)), w / 2, h / 2, money_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end

                local ico = cont:Add("DPanel")
                ico:Dock(LEFT)
                ico:InvalidateParent(true)
                ico:SetWide(iconSize + 2)
                ico:DockMargin(config.Margin, 0, 0, 0)
                ico.Paint = function(s, w, h)
                    if !IsValid(v) then return end
                    surface.SetMaterial(rankConfig[3])
                    surface.SetDrawColor(255, 255, 255)
                    surface.DrawTexturedRect((w/2) - (iconSize/2), (h/2) - (iconSize/2), iconSize, iconSize)
                end

                local rank = cont:Add("DLabel")
                rank:Dock(LEFT)
                rank:SetFont(rankFont)
                rank:SetContentAlignment(4)
                rank:SetText(rankConfig[1])
                rank:SetColor(rankConfig[2])
                rank:SizeToContentsX()
                rank:DockMargin(config.Margin, 0, config.Margin, 0)

                local username = cont:Add("DLabel")
                username:Dock(LEFT)
                username:SetFont(nsb.Font(ScreenScale(10)))
                username:SetText(v:Nick())
                username:SetContentAlignment(4)
                username:SizeToContentsX()

                local infoPanel = cont:Add("DLabel")
                infoPanel:Dock(RIGHT)
                infoPanel:SetColor(color_white)
                infoPanel:SetFont(nsb.Font(ScreenScale(7)))
                infoPanel:SetText(string.format("%dms", v:Ping()))
                infoPanel:SizeToContentsX()
                infoPanel:SetContentAlignment(6)
                infoPanel:DockMargin(0, 0, config.Margin, 0)
            end

            teamContent:SetTall(30 + (40 * table.Count(playerList)))
        end
    end

    nsb.Frame.Populate()
end

function nsb.Toggle(tgl)
    if tgl then
        if !nsb.Frame then
            createPanel()
        else
            nsb.Frame.Populate()
            nsb.Frame:AlphaTo(255, 0.25, 0, nil)
        end
    else
        if nsb.Frame then
            nsb.Frame:AlphaTo(0, 0.25, 0, nil)
        end
    end
end

hook.Add("ScoreboardShow", "NSB:ShowScoreboard", function()
    gui.EnableScreenClicker(true)
    nsb.Toggle(true)
    return true
end)

hook.Add("ScoreboardHide", "NSB:HideScoreboard", function()
    gui.EnableScreenClicker(false)
    nsb.Toggle(false)
end)
