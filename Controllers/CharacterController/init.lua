local LocalCharacter = require(script.LocalCharacter)
local RemoteCharacters = require(script.RemoteCharacters)
return {
	Initialize = function()
		LocalCharacter.Initialize()
		RemoteCharacters.Initialize()
	end,
	Start = LocalCharacter.Start,
	getCurrentCharacter = LocalCharacter.getCurrentCharacter,
	GetWalkState = LocalCharacter.GetWalkState,
	GetCrouchState = LocalCharacter.GetCrouchState,
	walk = LocalCharacter.walk,
	crouch = LocalCharacter.crouch,
	jump = LocalCharacter.jump,
	PredictDoorUse = LocalCharacter.PredictDoorUse,
	IsDoorInUseRange = LocalCharacter.IsDoorInUseRange,
	TrackCharacter = RemoteCharacters.Track,
	UntrackCharacter = RemoteCharacters.Untrack
}