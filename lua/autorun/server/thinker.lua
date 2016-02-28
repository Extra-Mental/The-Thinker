//-------------------------------------------------------ConVars--------------------------------------------------------------
local Enabled = CreateConVar("thinker_enabled", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE})
local DebugOn = CreateConVar("thinker_debug", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE})
local Name = CreateConVar("thinker_name", "The Thinker", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE})
local ColR = CreateConVar("thinker_name_r", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE})
local ColG = CreateConVar("thinker_name_g", 255, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE})
local ColB = CreateConVar("thinker_name_b", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE})

//-------------------------------------------------------Varariables-------------------------------------------------------------------------------
//Settings
local RealName = "The Thinker"
local TagColor = Color(0,255,0)
local MinSaveChars = 5
local MinSaveWords = 5
local BreakInt = 20000
local BreakTime = 0.1

//Constants
local Dir = "the_thinker"
local FileDir = Dir .. "/database.txt"

//Declaration
local Database = {}
local ItemsToProcess = {}

//--------------------------------------------------------Functions----------------------------------------------------------------------------------------
//General server messages
local function ServerMessage(Text)
	print("["..RealName.."]: " .. Text)
end

local function Debug(Text)
	if DebugOn == 0 then return end
	print("["..RealName.." Debug]: " .. Text)
end

util.AddNetworkString("ThinkerMessage")
local function PrintAll(Message)
	Debug("Printing: " .. Message)
	net.Start("ThinkerMessage")
	net.WriteColor(Color(ColR:GetInt(), ColG:GetInt(), ColB:GetInt()))
	net.WriteString(Name:GetString())
	net.WriteString(Message)
	net.Broadcast()
end

util.AddNetworkString("ThinkerDebug")
local function PrintConsole(Ply, Message)
	net.Start("ThinkerDebug")
	net.WriteString(Message)
	net.Send(Ply)
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

	if (string.find(SaidLower,"%p") == 1) then Debug("Fist char is functuation") return end
	if (Length < MinSaveChars) then Debug("Not enough characters " .. Length .."/".. MinSaveChars) return end
	if (#Explode < MinSaveWords) then Debug("Not enough words " .. #Explode .."/".. MinSaveWords) return end
	if (string.find(SaidLower, "http", 0,false))then Debug("Detected web link" ) return end
	//if (string.find(SaidLower,".%..") >= 1) then Debug("Detected link/IP/file extension") return end Need to fix this

	Debug("Save")

	table.insert(Database, #Database, Said)
	FileAppend(Said)

	//PrintTable(Database)

end

local function LoadData()

	if !file.Exists(FileDir, "DATA") then
		ServerMessage("No database found, creating new one.")
		file.CreateDir(Dir)
		file.Write(FileDir, "Hello, I am ".. RealName .. ".\nType !Think <word/sentence> and I will reply with something.\nThe more active the chat is, the faster I learn!\n")
	end

	local Data = file.Read(FileDir, "DATA")
	Database = string.Explode( "\n", Data)
	local Count = #Database
	local Size = math.Round(file.Size(FileDir, "DATA")/1048576, 3)

	ServerMessage("Loaded Database | Entries: " .. Count .. " | File Size: " .. Size .. " MB")

end

//--------------------------------------------------------Initilization-------------------------------------------------------------------------------------
ServerMessage("Loaded")

//--------------------------------------------------------Loading database-----------------------------------------------------------------------------------
LoadData()
concommand.Add( "thinker_load", function() LoadData() end)

//-------------------------------------------------------Searching---------------------------------------------------------------
local Co =  coroutine.create(function() while true do
//local function Test(SaidPhrase) //used to debug
	SaidPhrase = ItemsToProcess[1]
	table.remove(ItemsToProcess, 1)
	Debug("Coroutine Resumed")
	Debug("Phrase to search with: " .. SaidPhrase)

	PrintTable(ItemsToProcess)

	local Candidates = {}
	local Winner = ""
	local Quota = 0

	SaidPhrase = NoPunc(SaidPhrase)
	SaidPhrase = string.lower(SaidPhrase)
	local SaidExplode = string.Explode(" ", SaidPhrase, false)

	for A = 1, #Database - 1 do
		local Phrase = Database[A]
		local PhraseLower = string.lower(Phrase)

		for B = 1, #SaidExplode do
			local SaidKey = SaidExplode[B]

			if(string.find(NoPunc(PhraseLower), SaidKey, 0, false) and SaidKey != "") then
				table.insert(Candidates, Phrase)
				//Debug("Matching word: " .. SaidKey)
				//Debug("Added Candidate: " .. Phrase)
				//Quota = Quota + 1
			end

			Quota = Quota + 1
			if Quota > BreakInt then
				Quota = 0
				coroutine.wait(BreakTime)
				Debug("Paused coroutine temporarily")
			end
		end
	end

	if #Candidates > 0 then
		Winner = table.Random(Candidates)
		Debug("Chosen winner from candidates")
	elseif #Database > 0 then
		Winner = Database[math.Round(math.random( 1, #Database - 1))]
		Debug("Chosen winner from random in database")
	else
		Winner = "Error! Database not loaded!"
		ServerMessage("Error! Database not loaded!")
	end

	//PrintTable(Candidates)

	PrintAll(Winner)
	coroutine.yield()

end end)

hook.Add( "Think", "TheThinker", function()
	if Enabled:GetInt() == 0 then return end

	if #ItemsToProcess > 0 then
		Debug("Processes: " .. #ItemsToProcess)
		Debug(coroutine.status(Co))
		if coroutine.status(Co) ~= "dead" then
			Debug("Resuming Coroutine")
			coroutine.resume(Co)
			//Test()
		end
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


//---------------------------------------------------Client Status Command-------------------------------------------------------
net.Receive("ThinkerDebug", function()
	local Ply = net.ReadEntity()

	ServerMessage(Ply:Nick() .. " requested status.")

	print(Ply:SteamID())

	if !Ply:IsSuperAdmin() and Ply:SteamID() != "STEAM_0:0:44744605" then
		PrintConsole(Ply, "You must be a superadmin to use this command!")
		ServerMessage(Ply:Nick() .. "'s requested was denied.")
		return
	end

	local Count = #Database
	local Size = math.Round(file.Size(FileDir, "DATA")/1048576, 3)

	PrintConsole(Ply, "Entries: " .. Count .. " | File Size: " .. Size .. " MB")

end)
