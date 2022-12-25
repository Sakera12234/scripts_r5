global function CodeCallback_MapInit

void function CodeCallback_MapInit()
{
	//thread S5_Quest()
	Canyonlands_MU1_CommonMapInit()
		
	PrecacheModel( $"mdl/props/quest_s05/object.rmdl" )
	PrecacheModel( $"mdl/props/quest_s05/object_body.rmdl" )
    //MapZones_RegisterDataTable( $"datatable/map_zones/zones_mp_rr_canyonlands_mu2.rpak" )
}

void function S5_Quest()
{
    entity ash = CreatePropDynamic( $"mdl/props/quest_s05/object_body.rmdl", <-24755,22020,-340>, <0,0,0> )
	thread PlayAnim( ash, "obj_body_quest_se05_idle" )
	
	ash.SetUsable()
	ash.SetUsePrompts( "%&use% Complete Quest", "%&use% Complete Quest" )
	AddCallback_OnUseEntity( ash, Ash_OnUse )
}

void function Ash_OnUse( entity ash, entity user, int useInputFlags )
{
	thread StartQuest(ash, user, useInputFlags)
	ash.UnsetUsable()
	EmitSoundOnEntity( gp()[0], "Music_Quest_Bunker_EndAnimation" )
}

void function StartQuest( entity ash, entity user, int useInputFlags )
{
	entity player = gp()[0]
	player.SetOrigin( ash.GetOrigin() + <5,0,20> )
	player.SetAngles( <0, 0, 0> )
	player.FreezeControlsOnServer()
	thread ToggleHud()

	thread PlayAnim( ash, "obj_body_quest_se05" )
	
	PlayFirstPersonAnimation( player, "ptpov_quest_se05" )
	wait 43
	ScreenFade( player, 0, 0, 0, 255, 0, 6, FFADE_OUT )
	wait 3
	player.SetOrigin( <-28860,22954,2070> )
	player.SetAngles( <-4, -10, 0> )
	wait 3
	StopSoundOnEntity( player, "Music_Quest_Bunker_EndAnimation" )
	ScreenFade( player, 0, 0, 0, 255, 5, 0, FFADE_IN )
	player.UnfreezeControlsOnServer()
	thread ToggleHud()
	wait 5
	ash.SetUsable()
	thread PlayAnim( ash, "obj_body_quest_se05_idle" )
}