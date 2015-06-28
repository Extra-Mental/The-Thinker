--[[ 
Added:

Changed:
- Now ignores illegal characters while searching through its database, improving results.

Removed:

]]

//Constant Variables
local Name = "The Thinker"
local Colour = Color(20,255,20)
local SpeakDelay = 0.5
local SaveInterval = 15 //Minutes
local MinPhraseLength = 15
local Dir = "the_thinker"
local FilePath = Dir .."/database.txt"
local BlacklistPath = Dir .."/blacklist.txt"
local ValidWordCharLen = 3
local FirstCharIgnore = "!@#$%^&*-=+/.~" //Also used to check for illegal chars
local CharFilter = string.Explode("", " ~!@#$%^&*()_+-=.,'/;:|[]{}<>?`")
local Greeting = "Hello %playername%! Type '!Think <word/sentence>' to give me something to think about."

local Blacklist = ""
local BlacklistTable = {}
local Phrases = {}
local Data = ""
local Count = 0
local Size = 0
local Online = 1

local GreetingConvar = CreateConVar("thinker_greeting", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE})

util.AddNetworkString( "thinkermessage" )

local function ServerMessage(Text)
	print("["..Name.."]: " .. Text)
end

//Check the status of the saved and running database
local function Status()
		
	if(Online == 1)then 
		ServerMessage("State: Online.")
		ServerMessage("[Phrases: " .. table.Count(string.Explode( "\n", file.Read(FilePath, "DATA"))) .. "]"..
		"[Database Size: ".. math.Round(file.Size(FilePath, "DATA")/1048576, 3) .." MB]"..
		"[Greeting Message: ".. GreetingConvar:GetInt() .."]"
		)
	else ServerMessage("State: Offline.")end

end
concommand.Add( "thinker_status", function() Status() end)

//Check blacklist for bad match
local function NotBlacklisted(Words)
	local FilteredWords = Words
	for A = 1, table.Count(CharFilter) do
		local Char = CharFilter[A]
		FilteredWords = string.Replace(FilteredWords, Char, "")
		//print("Replaced:"..Char)
	end
	//print("Outcome: " .. FilteredWords)
	for A = 1, table.Count(BlacklistTable) do
		local BLWord = BlacklistTable[A]
		if(string.find(FilteredWords, BLWord, 0,true) and BLWord != "" ) then
		//print("Blacklisted word detected, ignoring.")
		return false end
	end
	return true
end

//Attempt to load the database
local function LoadDatabase()
	
	ServerMessage("Loading database...")
	Data = file.Read(FilePath, "DATA")
	Phrases = string.Explode( "\n", Data)
	Count = table.Count(Phrases)
	Size = math.Round(file.Size(FilePath, "DATA")/1048576, 3)
	if(Count > 0) then
		//PrintTable(Phrases)
		ServerMessage("Database loaded with ".. Count .. " phrases.")
	else
		ServerMessage("Database failed to load!")
		ServerMessage("Offline.")
		Online = 0
	end
	
end

//Attempt to create database
local function CreateDatabase()
	
	ServerMessage("Creating new database...")
	file.CreateDir( Dir)
	file.Write(FilePath, "Hello, I am ".. Name .. ".\nType !Think <word/sentence> and I will reply with something.\nThe more active the chat is, the faster I learn!")
	if file.Exists( FilePath, "DATA") then 
		ServerMessage("Database created.")
		LoadDatabase()
	else
		ServerMessage("Database failed to create!")
		ServerMessage("Offline.")
		Online = 0
	end

end
concommand.Add( "thinker_amnesia", function() CreateDatabase() end)

//Attempt to load the blacklist
local function LoadBlacklist()
	
	ServerMessage("Loading blacklist...")
	Blacklist = file.Read(BlacklistPath, "DATA")
	BlacklistTable = string.Explode("\n", Blacklist)
	if file.Exists( BlacklistPath, "DATA") then
		ServerMessage("Blacklist loaded.")
	else
		ServerMessage("Blacklist failed to load!")
		ServerMessage("Offline.")
		Online = 0
	end
	
end

//Attempt to create blacklist
local function CreateBlacklist()
	
	ServerMessage("Creating new blacklist...")
	file.CreateDir(Dir)
	file.Write(BlacklistPath, "")
	if file.Exists( BlacklistPath, "DATA") then 
		ServerMessage("Blacklist created.")
		ServerMessage("To add a word or multiple words to the blacklist, use command thinker_blacklist_add")
		ServerMessage("To remove all instances of a word to in the blacklist, use command thinker_blacklist_delete")
		LoadBlacklist()
	else
		ServerMessage("Blacklist failed to create!")
		ServerMessage("Offline.")
		Online = 0
	end
end
concommand.Add( "thinker_blacklist_clear", function() CreateBlacklist() end)

local function BlacklistAdd(ply, cmd, args, str)
	if not file.Exists( BlacklistPath, "DATA") then ServerMessage("Blacklist has not been created! Run command thinker_load")
	else
		if(table.Count(args) > 0)then
			for A=1, table.Count(args) do
				file.Append(BlacklistPath,string.lower(args[A]).."\n")
				ServerMessage("Word added to blacklist: "..string.lower(args[A]))
			end
			ServerMessage("Reloading blacklist...")
			LoadBlacklist()
		else
			ServerMessage("Invalid arguments.")
		end
	end
end
concommand.Add( "thinker_blacklist_add", function(ply, cmd, args, str) BlacklistAdd(ply, cmd, args, str) end)

local function BlacklistDelete(ply, cmd, args, str)
	if not file.Exists( BlacklistPath, "DATA") then 
		ServerMessage("Blacklist has not been created! Run command thinker_load")
	else
		if(table.Count(args) > 0)then
			for A=1, table.Count(args) do
				file.Write(BlacklistPath, string.Replace(Blacklist, string.lower(args[A]).."\n", ""))
				ServerMessage("Word removed from the blacklist: "..string.lower(args[A]))
			end
			ServerMessage("Reloading blacklist...")
			LoadBlacklist()
		else
			ServerMessage("Invalid arguments.")
		end
	end
end
concommand.Add( "thinker_blacklist_delete", function(ply, cmd, args, str) BlacklistDelete(ply, cmd, args, str) end)

local function PrintBlacklist()
	if not file.Exists( BlacklistPath, "DATA") then ServerMessage("Blacklist has not been created! Run command thinker_load") 
	else
		ServerMessage("Blacklisted words:\n| "..string.Implode(" | ", BlacklistTable))
	end
end
concommand.Add( "thinker_blacklist", function() PrintBlacklist() end)

//Load everything
local function Load()
	ServerMessage("Online.")
	Online = 1
	if file.Exists( FilePath, "DATA" )then
		LoadDatabase()
	else
		CreateDatabase()
	end
	if(Online == 1)then
		if file.Exists( BlacklistPath, "DATA" ) then
			LoadBlacklist()
		else
			CreateBlacklist()
		end
		Status()
	end
end
Load() //Initial load
concommand.Add( "thinker_load", function() Load() end)


//Message all the players.
local function SayAll(Message)
	local Data = {Message, Name, Colour}
	net.Start("thinkermessage")
	net.WriteTable(Data)
	net.Broadcast()
	ServerMessage(Message)
end

//Messsage a single player
local function Say(Ply, Message)
	local Data = {Message, Name, Colour}
	net.Start("thinkermessage")
	net.WriteTable(Data)
	net.Send(Ply)
	ServerMessage(Message)
end

//Runs when someone speaks in chat
local function PlyChat(ply, Said)
	
	//print("Said Function ran")
	
	if(Online == 1)then
		
		local SaidLower = string.Trim(string.lower(Said))
		local SaidTable = string.Explode(" ", SaidLower)
		local FirstWord = SaidTable[1]
		local FirstChar = string.GetChar(FirstWord, 1)
		local NoCmdSaidTable = SaidTable
		table.remove(NoCmdSaidTable, 1)
		local WordsToThinkAbout = {}
		local Length = string.len(SaidLower)
		
		//Check if what was said contains words
		if(table.Count(NoCmdSaidTable) > 0)then
			for k, v in ipairs(NoCmdSaidTable) do
				if(string.len(NoCmdSaidTable[k]) >= ValidWordCharLen) then
					table.insert(WordsToThinkAbout, NoCmdSaidTable[k])
				end	
			end
			//ServerMessage(table.ToString( WordsToThinkAbout, false))
		end
		
		if(string.find( FirstCharIgnore, FirstChar, 0,true))then
			//print("Chat Command")
			if(FirstWord == "!think")then
				
				if(table.Count(WordsToThinkAbout) > 0)then
					
					//Ignore illegal characters
					local IllegalChars = string.Explode("", FirstCharIgnore)
					for A = 1, table.Count(WordsToThinkAbout) do
						for B = 1, table.Count(IllegalChars) do
							local IllegalChar = IllegalChars[B]
							WordsToThinkAbout[A] = string.Replace(WordsToThinkAbout[A], IllegalChar, "")
						end
					end	
					
					//Search the database for matching words
					local ValidPhrases = {}
					for A=1, table.Count(Phrases) do
						local Phrase = Phrases[A]
						for B=1, table.Count(WordsToThinkAbout) do
							local SaidWord = string.lower(WordsToThinkAbout[B])
							if(string.find(string.lower(Phrase), SaidWord,0,true) and SaidWord != "")then
								table.insert(ValidPhrases, Phrase)
								//print("Found phrase containing: " .. SaidWord)
							else
								//print("Could not find:"..SaidWord)
								//print("In:"..Phrase)
							end
						end
					end
					
					if(table.Count(ValidPhrases) > 0)then
						timer.Simple( SpeakDelay, function() SayAll(table.Random(ValidPhrases)) end)
						//print("Returned a found phrase")
					else
						timer.Simple( SpeakDelay, function() SayAll(table.Random(Phrases)) end)
						//print("Returned a random phrase")
					end
				else
					timer.Simple( SpeakDelay, function() SayAll(table.Random(Phrases)) end)
					//print("Returned a random phrase because there was no valid words to search for")
				end
			end	
		else
			//print("Non Chat Command")
			if(Length > MinPhraseLength and NotBlacklisted(SaidLower))then
				if file.Exists( FilePath, "DATA") then
					file.Append(FilePath, "\n"..Said)
					table.insert(Phrases, table.Count(Phrases) + 1, Said)
					//print("Added Phrase: "..SaidLower)
					//Status()
				else
					ServerMessage("Database failed to save! Could not find original database to save over.")
					ServerMessage("Offline.")
					Online = 0
				end	
			end

		end
	
	end

end
hook.Add( "PlayerSay", "thinkerchat", PlyChat)

local function Greet(Ply)
	if(Online == 1 && GreetingConvar:GetInt() != 0 )then
		Say(Ply, string.Replace(Greeting,"%playername%",Ply:Nick()))
	end
end
hook.Add( "PlayerInitialSpawn", "thinkergreet", Greet)
