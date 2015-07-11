AddCSLuaFile()
if not CLIENT then return end

local Name = "The Thinker"

local function ClientMessage(Text)
	print("["..Name.."]: " .. Text)
end

ClientMessage("Message handler loaded.")

net.Receive("thinkermessage", function( len )
	local Data = net.ReadTable()
	chat.AddText(Data[3],Data[2],Color(255,255,255),": " .. Data[1])
end)