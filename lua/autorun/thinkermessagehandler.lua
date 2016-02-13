AddCSLuaFile()
if SERVER then return end

local function ClientMessage(Text)
	print("[The Thinker]: " .. Text)
end

ClientMessage("Message handler loaded.")

net.Receive("ThinkerMessage", function( len )
	local NameCol = net.ReadColor()
	local Name = net.ReadString()
	local Message = net.ReadString()
	chat.AddText(NameCol,Name,Color(255,255,255),": ",Message)
end)
