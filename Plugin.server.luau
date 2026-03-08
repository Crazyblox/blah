--!strict
--This script is for making use of 'blah' as a data import method in Roblox Studio.
--This script is not required if you are not running Luau in Roblox.
if not plugin then return end
local StudioService, ScriptEditorService, Selection = game:GetService("StudioService"), game:GetService("ScriptEditorService"), game:GetService("Selection")
local blah = require(`./blah`)
plugin:CreateToolbar("Import Data")
	:CreateButton(
		"DataImporter",
		"Import data as self-decoding buffer modules",
		"http://www.roblox.com/asset/?id=93378805661867",
		"Import Data"
	).Click:Connect(function()
		local dir = assert(
			assert(
				Selection:Get(),
				`File Loader: Select an instance to load files into!`
			)[1],
			`File Loader: There are no valid selections!`
		)
		for i, data: File in StudioService:PromptImportFilesAsync({"*"}) or {} do
			local module_out: ModuleScript = Instance.new("ModuleScript")
			module_out.Name = data.Name
			ScriptEditorService:UpdateSourceAsync(module_out, function()
				return blah.export(
					blah.encode.buffer(
						buffer.fromstring(data:GetBinaryContents() or "")
					)
				)
			end)
			module_out.Parent = dir
			print(`Loaded & encoded file {i} '{data.Name}'`)
		end    
	end)
