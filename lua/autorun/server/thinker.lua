//-------------------------------------------------------ConVars--------------------------------------------------------------
local Enabled = CreateConVar("thinker_enabled", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE})
local DebugOn = CreateConVar("thinker_debug", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE})


//-------------------------------------------------------Varariables-------------------------------------------------------------------------------
//Settings
local Name = "The Thinker"
local TagColor = Color(0,255,0)
local MinSaveChars = 5
local MinSaveWords = 5
local BreakInt = 5000

//Constants
local Dir = "the_thinker"
local FileDir = Dir .. "/database.txt"

//Declaration
local Database = {}
local ItemsToProcess = {}

//--------------------------------------------------------Functions----------------------------------------------------------------------------------------
//General server messages
local function ServerMessage(Text)
	print("["..Name.."]: " .. Text)
end

local function Debug(Text)
	if DebugOn == 0 then return end
	print("["..Name.." Debug]: " .. Text)
end

util.AddNetworkString("ThinkerMessage")
local function PrintAll(Message)
	Debug("Printing: " .. Message)
	net.Start("ThinkerMessage")
	net.WriteColor(TagColor)
	net.WriteString(Name)
	net.WriteString(Message)
	net.Broadcast()
end

local function FileAppend(String)
	file.Append(FileDir,String.."\n")
end

local function NoPunc(String)
	return string.gsub(String,"%p","")
end

local function SavePhrase(Said)

	local SaidLower = string.lower(Said)
	local Explode = string.Explode(" ", SaidLower)
	local Length = #Said


	if (string.find(SaidLower,"%p") == 1) then Debug("Punctuation") return end
	if (Length < MinSaveChars) then Debug("Not enough characters " .. Length .."/".. MinSaveChars) return end
	if (#Explode < MinSaveWords) then Debug("Not enough words " .. #Explode .."/".. MinSaveWords) return end
	if (string.find(SaidLower, "http", 0,false))then Debug("Detected web link" ) return end

	Debug("Save")

	table.insert(Database, Said)
	FileAppend(Said)

	PrintTable(Database)

end

local function LoadData()

	if !file.Exists(FileDir, "DATA") then
		ServerMessage("No database found, creating new one.")
		file.CreateDir(Dir)
		file.Write(FilePath, "Hello, I am ".. Name .. ".\nType !Think <word/sentence> and I will reply with something.\nThe more active the chat is, the faster I learn!")
	end

	local Data = file.Read(FileDir, "DATA")
	local Database = string.Explode( "\n", Data)
	local Count = #Database
	local Size = math.Round(file.Size(FileDir, "DATA")/1048576, 3)

	ServerMessage("Loaded Database | Entries: " .. Count .. " | File Size: " .. Size .. " MB" )

end

//--------------------------------------------------------Initilization-------------------------------------------------------------------------------------
ServerMessage("Loaded")

//--------------------------------------------------------Loading database-----------------------------------------------------------------------------------
LoadData()

//-------------------------------------------------------Searching---------------------------------------------------------------
//local Co =  coroutine.create(function(SaidPhrase) while true do
local function Test(SaidPhrase) //used to debug
	table.remove(ItemsToProcess, 1)
	Debug("Coroutine Resumed")

	local Candidates = {}
	local Winner = ""

	SaidPhrase = NoPunc(SaidPhrase)
	SaidPhrase = string.lower(SaidPhrase)
	local SaidExplode = string.Explode(" ", SaidPhrase, false)

	for A = 1, #Database - 1 do
		local Phrase = Database[A]
		local PhraseLower = string.lower(Phrase)

		for B = 1, #SaidExplode do
			local SaidKey = SaidExplode[B]

			if(string.find(PhraseLower, SaidKey, 0, false) and SaidKey != "") then
				table.insert(Candidates, Phrase)
				Debug("Added Candidate: " .. Phrase)
			end
		end
	end

	if #Candidates > 0 then
		Winner = table.Random(Candidates)
	else
		Winner = Database[math.Round(math.random( 1, #Database - 1))]
	end

	PrintTable(Candidates)

	if Winner == nil then Debug("Winner is nil") end

	PrintAll(Winner)
	//coroutine.yield()

end //end)

hook.Add( "Think", "TheThinker", function()
	if Enabled:GetInt() == 0 then return end

	if #ItemsToProcess > 0 then
		//Debug("Processes: " .. #ItemsToProcess)
		//Debug(coroutine.status(Co))
		//if coroutine.status(Co) ~= "dead" then
			//Debug("Resuming Coroutine")
			//coroutine.resume(Co, ItemsToProcess[1])
			Test(ItemsToProcess[1])
		//end
	end

end)

//------------------------------------------------------Chat Handling----------------------------------------------------------------------
hook.Add( "PlayerSay", "TheThinker", function( Ply, Said, Team )
	if Enabled:GetInt() == 0 then return end
	Said = string.Trim(Said)

	SavePhrase(Said)

	local SaidExplode = string.Explode(" ", Said, false)
	local Command = SaidExplode[1]
	local NoCmdSaidTable = SaidExplode; table.remove(NoCmdSaidTable, 1)
	local SaidNoCmd = table.concat( NoCmdSaidTable, " " )

	if string.lower(Command) == "!think"  and #SaidNoCmd > 0 then
		Debug("Inserted to stack: " .. SaidNoCmd)
		table.insert(ItemsToProcess, SaidNoCmd)
	end

end)
