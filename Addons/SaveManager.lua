local SaveManager = {} do
	SaveManager.Folder 					= "Fondra/Games/Criminality"
	SaveManager.Ignore 					= {}
	SaveManager.Parser 					= {
		Toggle = {
			Save = function(Index, Object) 
				return { Type = "Toggle", Index = Index, Value = Object.Value } 
			end,
			
			Load = function(Index, Data)
				if Toggles[Index] then 
					Toggles[Index]:SetValue(Data.Value)
				end
			end
		},

		Slider = {
			Save = function(Index, Object)
				return { Type = "Slider", Index = Index, Value = tostring(Object.Value) }
			end,

			Load = function(Index, Data)
				if Options[Index] then 
					Options[Index]:SetValue(Data.Value)
				end
			end
		},

		Dropdown = {
			Save = function(Index, Object)
				return { Type = "Dropdown", Index = Index, Value = Object.Value, Multi = Object.Multi }
			end,

			Load = function(Index, Data)
				if Options[Index] then 
					Options[Index]:SetValue(Data.Value)
				end
			end
		},

		ColorPicker = {
			Save = function(Index, Object)
				return { Type = "ColorPicker", Index = Index, Value = Object.Value:ToHex(), Transparency = Object.Transparency }
			end,

			Load = function(Index, Data)
				if Options[Index] then
					Options[Index]:SetValueRGB(Color3.fromHex(Data.Value), Data.Transparency)
				end
			end
		},

		KeyPicker = {
			Save = function(Index, Object)
				return { Type = "KeyPicker", Index = Index, Mode = Object.Mode, Key = Object.Value }
			end,

			Load = function(Index, Data)
				if Options[Index] then 
					Options[Index]:SetValue({ Data.Key, Data.Mode })
				end
			end
		},

		Input = {
			Save = function(Index, Object)
				return { Type = "Input", Index = Index, Text = Object.Value }
			end,

			Load = function(Index, Data)
				if Options[Index] and type(Data.Text) == "string" then
					Options[Index]:SetValue(Data.Text)
				end
			end,
		}
	}

	function SaveManager:SetIgnoreIndexes(List)
		for _, Key in next, List do
			self.Ignore[Key] 			= true
		end
	end

	function SaveManager:SetFolder(Folder)
		self.Folder 					= Folder
		self:BuildFolderTree()
	end

	function SaveManager:Save(Name)
		if (not Name) then return false, "No config file is selected." end

		local Path 						= string.format("%s/%s.json", self.Folder, Name)
		local Data 						= { Objects = {} }

		for Index, Toggle in next, Toggles do
			if self.Ignore[Index] then continue end

			table.insert(Data.Objects, self.Parser[Toggle.Type].Save(Index, Toggle))
		end

		for Index, Option in next, Options do
			if not self.Parser[Option.Type] then continue end
			if self.Ignore[Index] then continue end

			table.insert(Data.Objects, self.Parser[Option.Type].Save(Index, Option))
		end	

		local Success, Encoded 			= pcall(Fondra.Services.HttpService.JSONEncode, Fondra.Services.HttpService, Data)
		
		if not Success then return false, "Failed to encode Data." end
		writefile(Path, Encoded)

		return true
	end

	function SaveManager:Load(Name)
		if (not Name) then return false, "No config file is selected." end
		
		local File 						= string.format("%s/%s.json", self.Folder, Name)

		if not isfile(File) then return false, "Invalid file." end

		local Success, Decoded 			= pcall(Fondra.Services.HttpService.JSONDecode, Fondra.Services.HttpService, readfile(File))

		if not Success then return false, "Decode Error." end

		for _, Option in next, Decoded.Objects do
			if self.Parser[Option.Type] then
				task.spawn(function() self.Parser[Option.Type].Load(Option.Index, Option) end)
			end
		end

		return true
	end

	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({ 
			"BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor",
			"ThemeManager_ThemeList", "ThemeManager_CustomThemeList", "ThemeManager_CustomThemeName",
		})
	end

	function SaveManager:BuildFolderTree()
		local Directorys 				= {}

		self.Folder:gsub("([^/]+)", function(Directory)
			table.insert(Directorys, Directory)
		end)

		for _, Directory in next, Directorys do
			local Directory             = table.concat(Directorys, "/", 1, _)

			if isfolder(Directory) then continue end

			makefolder(Directory)
		end
	end

	function SaveManager:RefreshConfigList()
		local List 						= listfiles(self.Folder)
		local Output			 		= {}

		for i = 1, #List do
			local File  				= List[i]

			if File:sub(-5) == ".json" then
				local Position 			= File:find(".json", 1, true)
				local Start 			= Position
				local Character 		= File:sub(Position, Position)

				while Character ~= "/" and Character ~= "\\" and Character ~= "" do
					Position 			= Position - 1
					Character 			= File:sub(Position, Position)
				end

				if Character == "/" or Character == "\\" then
					table.insert(Output, File:sub(Position + 1, Start - 1))
				end
			end
		end
		
		return Output
	end

	function SaveManager:SetLibrary(Library)
		self.Library 					= Library
	end

	function SaveManager:LoadAutoloadConfig()
		if isfile(string.format("%s/AutoLoad.txt", self.Folder)) then
			local Name 					= readfile(string.format("%s/AutoLoad.txt", self.Folder))
			local Success, Error 		= self:Load(Name)

			if not Success then return self.Library:Notify(string.format("Failed to load autoload config: %s", Error)) end

			self.Library:Notify(string.format("Auto loaded config %q", Name))
		end
	end

	function SaveManager:BuildConfigSection(Tab)
		assert(self.Library, "Must set SaveManager.Library")

		local Credits = Tab:AddRightGroupbox("Credits") do
			Credits:AddLabel("Incognito - Developer")
			Credits:AddLabel("Inori - UI Library")

			Credits:AddDivider()

			Credits:AddButton("Join Discord", function()
				Fondra.Method({
					Url             	= "http://127.0.0.1:6463/rpc?v=1",
					Method              = "POST",
	
					Headers = {
						["Content-Type"]= "application/json",
						["Origin"]      = "https://discord.com"
					},
	
					Body = Fondra.Services.HttpService:JSONEncode({
						cmd             = "INVITE_BROWSER",
						args            = { code = "fpgeKk2Axk" },
						nonce           = Fondra.Services.HttpService:GenerateGUID(false)
					}),
				})
			end)
		end
	
		local Menu = Tab:AddRightGroupbox("Settings") do
			Menu:AddToggle("FondraTelemetry", {
				Text                    = "Telemetry",
				Default                 = false
			})

			Menu:AddToggle("FondraKeybindUI", {
				Text                    = "Keybinds UI",
				Default                 = false
			})
		
			Menu:AddToggle("FondraMainUI", {
				Text                    = "Main UI",
				Default                 = true
			}):AddKeyPicker("FondraMainUIKey", {
				Default 				= "Insert",
				SyncToggleState 		= true,
				Mode 					= "Toggle",
			
				Text 					= "UI Toggle",
				NoUI 					= false,
			})

			Menu:AddDivider()

			Menu:AddDropdown("FondraWatermarkData", {
				Values                  = { "Version", "FPS", "Ping", "Date", "Time" }, 
				Default                 = 1,
				Multi                   = true,
				Text                    = "Watermark Data"
			})

			Menu:AddButton("Unload", function()
				Library:Unload()
			end)

			Toggles.FondraMainUI:OnChanged(function(V)
				task.spawn(self.Library.Toggle)
			end)

			Toggles.FondraKeybindUI:OnChanged(function(V)
				self.Library.KeybindFrame.Visible = V
			end)
		end

		local Section 					= Tab:AddRightGroupbox("Configuration")

		Section:AddInput("SaveManager_ConfigName", { Text = "Config name" })
		Section:AddDropdown("SaveManager_ConfigList", { Text = "Config list", Values = self:RefreshConfigList(), AllowNull = true })

		Section:AddDivider()

		Section:AddButton("Create config", function()
			local Name 					= Options.SaveManager_ConfigName.Value

			if Name:gsub(" ", "") == "" then  return self.Library:Notify("Invalid config name. [Empty]", 2) end

			local Success, Error 		= self:Save(Name)

			if not Success then return self.Library:Notify(string.format("Failed to save config: %s", Error)) end

			self.Library:Notify(string.format("Created config %q", Name))

			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			Options.SaveManager_ConfigList:SetValue(nil)
		end):AddButton("Load config", function()
			local Name 					= Options.SaveManager_ConfigList.Value
			local Success, Error 		= self:Load(Name)
			
			if not Success then return self.Library:Notify(string.format("Failed to load config: %s", Error)) end

			self.Library:Notify(string.format("Loaded config %q", Name))
		end)

		Section:AddButton("Overwrite config", function()
			local Name 					= Options.SaveManager_ConfigList.Value
			local Success, Error 		= self:Save(Name)

			if not Success then return self.Library:Notify(string.format("Failed to override config: %s", Error)) end

			self.Library:Notify(string.format("Overwrote config %q", Name))
		end)

		Section:AddButton("Refresh list", function()
			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			Options.SaveManager_ConfigList:SetValue(nil)
		end)

		Section:AddButton("Set as autoload", function()
			local Name 					= Options.SaveManager_ConfigList.Value

			writefile(string.format("%s/AutoLoad.txt", self.Folder), Name)
			SaveManager.AutoloadLabel:SetText(string.format("Current autoload config: %s", Name))
			self.Library:Notify(string.format("Set %q to auto load", Name))
		end)

		SaveManager.AutoloadLabel 		= Section:AddLabel("Current autoload config: none", true)

		if isfile(string.format("%s/AutoLoad.txt", self.Folder)) then
			local Name 					= readfile(string.format("%s/AutoLoad.txt", self.Folder))
			SaveManager.AutoloadLabel:SetText(string.format("Current autoload config: %s", Name))
		end

		SaveManager:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
	end
end

Fondra.Services.RunService:BindToRenderStep("Watermark.lua", Enum.RenderPriority.Camera.Value + 1, function(Delta)
    if not Fondra.Cooldowns.Watermark then Fondra.Cooldowns.Watermark = tick() end

    if (tick() - Fondra.Cooldowns.Watermark) <= 1 then return end

    Fondra.Cooldowns.Watermark                                  = tick()

    local List                                                  = {}
    local Result                                                = {}

    for Index, Value in next, Options.FondraWatermarkData:GetActiveValues() do
        if (Value == "FPS") then table.insert(Result, 1 / Delta) continue end
        if (Value == "Ping") then table.insert(Result, Fondra.Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) continue end
    end

    Library:SetWatermark(string.format("Fondra %s", table.concat(List, " - ")))
end)

return SaveManager
