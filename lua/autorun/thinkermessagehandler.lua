AddCSLuaFile()
if SERVER then return end

local function ClientMessage(Text)
	print("[The Thinker]: " .. Text)
end

ClientMessage("Message handler loaded.")

net.Receive("ThinkerMessage", function()
	local NameCol = net.ReadColor()
	local Name = net.ReadString()
	local Message = net.ReadString()
	chat.AddText(NameCol,Name,Color(255,255,255),": ",Message)
end)

concommand.Add( "thinker_status", function()

	ClientMessage("Fetching The Thinker's status...")

	net.Start("ThinkerDebug")
	net.WriteEntity(LocalPlayer())
	net.SendToServer()

end)

net.Receive("ThinkerDebug", function()
	local Status = net.ReadString()
	ClientMessage(Status)
end)
