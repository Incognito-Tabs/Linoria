local ThemeManager = {} do
	ThemeManager.Folder 				= "Fondra/Themes"
	ThemeManager.Library			 	= nil
	ThemeManager.BuiltInThemes			= {
		["Default"] 					= { 1, Fondra.Services.HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"181b25","AccentColor":"448fe3","BackgroundColor":"16191f","OutlineColor":"323232"}') },
		["BBot"] 						= { 2, Fondra.Services.HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414"}') },
		["Fatality"]					= { 3, Fondra.Services.HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}') },
		["Jester"] 						= { 4, Fondra.Services.HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		["Mint"] 						= { 5, Fondra.Services.HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		["Tokyo Night"] 				= { 6, Fondra.Services.HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}') },
		["Ubuntu"] 						= { 7, Fondra.Services.HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"3e3e3e","AccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919"}') },
		["Quartz"] 						= { 8, Fondra.Services.HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"232330","AccentColor":"426e87","BackgroundColor":"1d1b26","OutlineColor":"27232f"}') },
	}

	function ThemeManager:ApplyTheme(Theme)
		local CustomThemeData 			= self:GetCustomTheme(Theme)
		local Data 						= CustomThemeData or self.BuiltInThemes[Theme]

		if not Data then return end

		local Scheme 					= Data[2]

		for Index, Color in next, CustomThemeData or Scheme do
			self.Library[Index] 		= Color3.fromHex(Color)

			if Options[Index] then Options[Index]:SetValueRGB(Color3.fromHex(Color)) end
		end

		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		local Indexes 					= { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }

		for Index, Field in next, Indexes do
			if not Options or not Options[Field] then continue end

			self.Library[Field] 		= Options[Field].Value
		end

		self.Library.AccentColorDark 	= self.Library:GetDarkerColor(self.Library.AccentColor);
		self.Library:UpdateColorsUsingRegistry()
	end

	function ThemeManager:LoadDefault()		
		local Theme 					= "Default"
		local Content 					= isfile(string.format("%s/Default.txt", self.Folder)) and readfile(string.format("%s/Default.txt", self.Folder))
		local IsDefault 				= true

		if Content then
			if self.BuiltInThemes[Content] then
				Theme 					= Content
			elseif self:GetCustomTheme(Content) then
				Theme 					= Content
				IsDefault 				= false
			end
		elseif self.BuiltInThemes[self.DefaultTheme] then
			Theme = self.DefaultTheme
		end

		if IsDefault then
			Options.ThemeManager_ThemeList:SetValue(Theme)
		else
			self:ApplyTheme(Theme)
		end
	end

	function ThemeManager:SaveDefault(Theme)
		writefile(string.format("%s/Default.txt", self.Folder), Theme)
	end

	function ThemeManager:RemoveDefault()
		delfile(string.format("%s/Default.txt", self.Folder), Theme)
	end

	function ThemeManager:GetCustomTheme(Name)
		local Path 						= string.format("%s/%s.json", self.Folder, Name)

		if not isfile(Path) then return nil end

		local Data 						= readfile(Path)
		local Success, Decoded 			= pcall(Fondra.Services.HttpService.JSONDecode, Fondra.Services.HttpService, Data)
		
		if not Success then return nil end

		return Decoded
	end

	function ThemeManager:SaveCustomTheme(Name)
		if Name:gsub(" ", "") == "" then return self.Library:Notify("Invalid file name for theme. [Empty]", 3) end

		local Theme 					= {}
		local Fields 					= { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }

		for _, Field in next, Fields do
			Theme[Field] 				= Options[Field].Value:ToHex()
		end

		writefile(string.format("%s/%s.json", self.Folder, Name), Fondra.Services.HttpService:JSONEncode(Theme))
	end

	function ThemeManager:RemoveCustomTheme(Name)
		if Name:gsub(" ", "") == "" then return self.Library:Notify("Invalid file name for theme. [Empty]", 3) end

		if not isfile(string.format("%s/%s.json", self.Folder, Name)) then return self.Library:Notify("Invalid file. [Does not exist]", 3) end

		delfile(string.format("%s/%s.json", self.Folder, Name))
	end

	function ThemeManager:ReloadCustomThemes()
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

	function ThemeManager:SetLibrary(Library)
		self.Library 					= Library
	end

	function ThemeManager:BuildFolderTree()
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

	function ThemeManager:SetFolder(Folder)
		self.Folder 					= Folder
		self:BuildFolderTree()
	end

	function ThemeManager:BuildThemeSection(Tab)
		assert(self.Library, "Must set ThemeManager.Library first!")

		local Groupbox 					= Tab:AddLeftGroupbox("Themes")
		
		Groupbox:AddLabel("Background color"):AddColorPicker("BackgroundColor", { Default = self.Library.BackgroundColor });
		Groupbox:AddLabel("Main color")	:AddColorPicker("MainColor", { Default = self.Library.MainColor });
		Groupbox:AddLabel("Accent color"):AddColorPicker("AccentColor", { Default = self.Library.AccentColor });
		Groupbox:AddLabel("Outline color"):AddColorPicker("OutlineColor", { Default = self.Library.OutlineColor });
		Groupbox:AddLabel("Font color")	:AddColorPicker("FontColor", { Default = self.Library.FontColor });

		local ThemesArray 				= {}

		for Name, Theme in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name)
		end

		table.sort(ThemesArray, function(A, B) return self.BuiltInThemes[A][1] < self.BuiltInThemes[B][1] end)

		Groupbox:AddDivider()
		Groupbox:AddDropdown("ThemeManager_ThemeList", { Text = "Theme list", Values = ThemesArray, Default = 1 })

		Groupbox:AddButton("Set as default", function()
			self:SaveDefault(Options.ThemeManager_ThemeList.Value)
			self.Library:Notify(string.format("Set default theme to %q", Options.ThemeManager_ThemeList.Value))
		end)

		Options.ThemeManager_ThemeList:OnChanged(function()
			self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
		end)

		Groupbox:AddDivider()
		Groupbox:AddInput("ThemeManager_CustomThemeName", { Text = "Custom theme name" })
		Groupbox:AddDropdown("ThemeManager_CustomThemeList", { Text = "Custom themes", Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
		Groupbox:AddDivider()
		
		Groupbox:AddButton("Save theme", function() 
			self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value)

			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end):AddButton("Load theme", function() 
			self:ApplyTheme(Options.ThemeManager_CustomThemeList.Value) 
		end)

		Groupbox:AddButton("Refresh list", function()
			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
			self.Library:Notify("Refreshed the list.")
		end)

		Groupbox:AddButton("Set as default", function()
			if Options.ThemeManager_CustomThemeList.Value ~= nil and Options.ThemeManager_CustomThemeList.Value ~= "" then
				self:SaveDefault(Options.ThemeManager_CustomThemeList.Value)
				self.Library:Notify(string.format("Set default theme to %q", Options.ThemeManager_CustomThemeList.Value))
			end
		end):AddButton("Remove default", function()
			self:RemoveDefault()
			self.Library:Notify("Removed the default theme.")
		end)

		Groupbox:AddButton("Delete theme", function() 
			self:RemoveCustomTheme(Options.ThemeManager_CustomThemeList.Value) 
		end)

		ThemeManager:LoadDefault()

		local function UpdateTheme()
			self:ThemeUpdate()
		end

		Options.BackgroundColor:OnChanged(UpdateTheme)
		Options.MainColor:OnChanged(UpdateTheme)
		Options.AccentColor:OnChanged(UpdateTheme)
		Options.OutlineColor:OnChanged(UpdateTheme)
		Options.FontColor:OnChanged(UpdateTheme)
	end
end

return ThemeManager
