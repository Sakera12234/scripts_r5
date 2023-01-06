#if SERVER
global function ShSdkTools_Init
global function DEV_ToggleAkimboWeapon
global function DEV_ToggleAkimboWeaponAlt
global function BecomeLoba
global function BecomeRampart
global function BecomeRevenant
global function BecomeAsh
global function BecomeCatalyst
global function BecomeNova
global function BecomeValk
global function TestAnimation

global const asset TEST_MODEL = $"mdl/Humans/class/medium/combat_dummie_medium.rmdl"
global const string TEST_ANIM= "Walldeath"

//////////////////////////

void function ShSdkTools_Init()
{
	Precache_Sdk_Weapons()
	Precache_Sdk_Models()
	Precache_Lobby_Models()
	Precache_R5_Weapons()
}

void function Precache_Sdk_Weapons()
{
	PrecacheWeapon( $"melee_bolo_sword" )
	PrecacheWeapon( $"mp_weapon_bolo_sword_primary" )
	PrecacheWeapon( $"melee_mjolnir" )
	PrecacheWeapon( $"mp_weapon_mjolnir_primary" )
	PrecacheWeapon( $"mp_weapon_melee_boxing_ring")
	PrecacheWeapon( $"melee_boxing_ring")
	PrecacheWeapon( $"mp_weapon_dataknife_kunai_primary")
	PrecacheWeapon( $"melee_dataknife_kunai")
	PrecacheWeapon( $"melee_data_knife" )
	//////////////////////////////////////////////////
	PrecacheWeapon( $"mp_ability_sniper_ult" )
	PrecacheWeapon( $"mp_weapon_defender_sustained" )
	PrecacheWeapon( $"weapon_cubemap" )
	//////////////////////////////////////////////////
	PrecacheWeapon( $"mp_weapon_droneplasma" )//NPC Weapon
	PrecacheWeapon( $"mp_weapon_dronerocket" )//NPC Weapon
	PrecacheWeapon( $"npc_weapon_energy_shotgun" )//NPC Weapon
	PrecacheWeapon( $"npc_weapon_hemlok" )//NPC Weapon
	PrecacheWeapon( $"npc_weapon_lstar" )//NPC Weapon
	//////////////////////////////////////////////////
	PrecacheWeapon( $"mp_weapon_satchel" )
	PrecacheWeapon( $"mp_titanweapon_flightcore_rockets" )
	//////////////////////////////////////////////////
	PrecacheWeapon( $"mp_weapon_grenade_electric_smoke" )
	PrecacheWeapon( $"mp_weapon_deployable_cover" )
	PrecacheWeapon( $"mp_weapon_grenade_gravity" )
	PrecacheWeapon( $"mp_weapon_clickweaponauto")
	PrecacheWeapon( $"mp_weapon_grenade_sonar" )
	PrecacheWeapon( $"mp_weapon_smart_pistol" )
	PrecacheWeapon( $"mp_weapon_frag_drone" )
	PrecacheWeapon( $"mp_weapon_clickweapon")
	PrecacheWeapon( $"mp_weapon_mdlspawner" )
	PrecacheWeapon( $"sp_weapon_arc_tool" )
	PrecacheWeapon( $"mp_ability_3dash" )
	PrecacheWeapon( $"mp_weapon_spectre_spawner" )
	PrecacheWeapon( $"mp_weapon_super_spectre" )
}

void function Precache_Sdk_Models()
{
	PrecacheModel( $"mdl/humans/class/heavy/pilot_heavy_revenant.rmdl" )
	PrecacheModel( $"mdl/Weapons/arms/pov_pilot_heavy_revenant.rmdl" )
	PrecacheModel( $"mdl/Humans/class/medium/pilot_medium_loba.rmdl" )
	PrecacheModel( $"mdl/Weapons/arms/pov_pilot_medium_loba.rmdl" )
	PrecacheModel( $"mdl/Humans/class/medium/pilot_medium_rampart.rmdl" )
	PrecacheModel( $"mdl/Weapons/arms/pov_pilot_medium_rampart.rmdl" )
	PrecacheModel( $"mdl/props/rampart_gum/rampart_bubblegum.rmdl" )
	PrecacheModel( $"mdl/props/loba_loot_stick/loba_loot_stick.rmdl" )
	PrecacheModel( $"mdl/techart/mshop/characters/legends/ash/ash_base_w.rmdl" )
	PrecacheModel( $"mdl/techart/mshop/characters/legends/ash/ash_base_v.rmdl" )
	PrecacheModel( $"mdl/vehicle/olympus_hovercraft/olympus_hovercraft_v2.rmdl" )
	PrecacheModel( $"mdl/techart/mshop/characters/legends/catalyst/catalyst_base_w.rmdl" )
	PrecacheModel( $"mdl/techart/mshop/characters/legends/catalyst/catalyst_base_v.rmdl" )
	PrecacheModel( $"mdl/Weapons/arms/pov_pilot_medium_valkyrie.rmdl" )
	PrecacheModel( $"mdl/Humans/class/medium/pilot_medium_valkyrie.rmdl" )
	PrecacheModel( $"mdl/Weapons/arms/pov_pilot_medium_nova_base_01.rmdl" )
	PrecacheModel( $"mdl/Humans/class/medium/pilot_medium_nova_01.rmdl" )
}

void function Precache_Lobby_Models()
{
	//Charms
	PrecacheModel( $"mdl/props/charm/charm_fireball.rmdl" )
	PrecacheModel( $"mdl/props/charm/charm_yeti.rmdl" )
	PrecacheModel( $"mdl/props/charm/charm_crow.rmdl" )
	PrecacheModel( $"mdl/props/charm/charm_rank_gold.rmdl" )
	PrecacheModel( $"mdl/props/charm/charm_rank_diamond.rmdl" )
	PrecacheModel( $"mdl/props/charm/charm_rank_predator.rmdl" )
	PrecacheModel( $"mdl/props/charm/charm_nessy.rmdl" )
	PrecacheModel( $"mdl/props/charm/charm_lifeline_drone.rmdl" )
	PrecacheModel( $"mdl/props/charm/charm_rank_platinum.rmdl" )
	PrecacheModel( $"mdl/props/charm/charm_pumpkin.rmdl" )
	PrecacheModel( $"mdl/props/charm/charm_gas_canister.rmdl" )
	PrecacheModel( $"mdl/props/charm/charm_jester.rmdl" )
	PrecacheModel( $"mdl/props/charm/charm_nessy_ghost.rmdl" )
	PrecacheModel( $"mdl/props/charm/charm_clown.rmdl" )
	PrecacheModel( $"mdl/props/charm/charm_witch.rmdl" )

	//Lobby Models
	PrecacheModel( $"mdl/robots/drone_frag/drone_frag.rmdl" )
	PrecacheModel( $"mdl/vehicle/droppod_loot/droppod_loot_LL_holo.rmdl" )
	PrecacheModel( $"mdl/menu/xp_badge.rmdl" )
	PrecacheModel( $"mdl/menu/coin.rmdl" )
	PrecacheModel( $"mdl/currency/crafting/currency_crafting_epic.rmdl" )
}

void function Precache_R5_Weapons()
{
	PrecacheWeapon( $"mp_ability_holopilot" )
	PrecacheWeapon( $"mp_ability_grapple" )
	PrecacheWeapon( $"mp_ability_phase_walk" )
	PrecacheWeapon( $"mp_ability_area_sonar_scan" )
	PrecacheWeapon( $"mp_ability_consumable" )
	PrecacheWeapon( $"mp_ability_care_package" )
	PrecacheWeapon( $"mp_ability_hunt_mode" )
	PrecacheWeapon( $"mp_weapon_melee_survival" )
	PrecacheWeapon( $"mp_weapon_bubble_bunker" )
	PrecacheWeapon( $"mp_weapon_deployable_medic" )
	PrecacheWeapon( $"mp_weapon_phase_tunnel" )
	PrecacheWeapon( $"mp_weapon_zipline" )
	PrecacheWeapon( $"mp_weapon_grenade_bangalore" )
	PrecacheWeapon( $"mp_weapon_incap_shield" )
	PrecacheWeapon( $"mp_weapon_dirty_bomb" )
	PrecacheWeapon( $"mp_weapon_jump_pad" )
	PrecacheWeapon( $"mp_weapon_grenade_creeping_bombardment" )
	PrecacheWeapon( $"mp_weapon_grenade_defensive_bombardment" )
	PrecacheWeapon( $"melee_shadowsquad_hands" )
	PrecacheWeapon( $"mp_weapon_shadow_squad_hands_primary" )
	PrecacheParticleSystem( $"P_sparks_beacon_dish" )
}

void function BecomeValk(entity player)
{
	if(!IsValid(player))
		return

	player.SetBodyModelOverride($"mdl/Humans/class/medium/pilot_medium_valkyrie.rmdl" )
	player.SetArmsModelOverride($"mdl/Weapons/arms/pov_pilot_medium_valkyrie.rmdl" )
}

void function BecomeNova(entity player)
{
	if(!IsValid(player))
		return

	player.SetBodyModelOverride($"mdl/Humans/class/medium/pilot_medium_nova_01.rmdl" )
	player.SetArmsModelOverride($"mdl/Weapons/arms/pov_pilot_medium_nova_base_01.rmdl" )
}

void function BecomeAsh(entity player)
{
	if(!IsValid(player))
		return

	player.SetBodyModelOverride($"mdl/techart/mshop/characters/legends/ash/ash_base_w.rmdl" )
	player.SetArmsModelOverride($"mdl/techart/mshop/characters/legends/ash/ash_base_v.rmdl" )
}

void function BecomeLoba(entity player)
{
	if(!IsValid(player))
		return

	player.SetBodyModelOverride($"mdl/Humans/class/medium/pilot_medium_loba.rmdl" )
	player.SetArmsModelOverride($"mdl/Weapons/arms/pov_pilot_medium_loba.rmdl" )
}

void function BecomeRampart(entity player)
{
	if(!IsValid(player))
		return

	player.SetBodyModelOverride($"mdl/Humans/class/medium/pilot_medium_rampart.rmdl" )
	player.SetArmsModelOverride($"mdl/Weapons/arms/pov_pilot_medium_rampart.rmdl" )
}

void function BecomeRevenant(entity player)
{
	if(!IsValid(player))
		return

	player.SetBodyModelOverride($"mdl/humans/class/heavy/pilot_heavy_revenant.rmdl" )
	player.SetArmsModelOverride($"mdl/Weapons/arms/pov_pilot_heavy_revenant.rmdl" )
}

void function BecomeCatalyst(entity player)
{
	if(!IsValid(player))
		return

	player.SetBodyModelOverride($"mdl/techart/mshop/characters/legends/catalyst/catalyst_base_w.rmdl" )
	player.SetArmsModelOverride($"mdl/techart/mshop/characters/legends/catalyst/catalyst_base_v.rmdl" )
}

void function DEV_ToggleAkimboWeapon(entity player)
{
	if(!IsValid(player))
		return

	entity weapon = player.GetActiveWeapon( eActiveInventorySlot.mainHand )

	if(!IsValid(weapon))
		return

	if(player.GetNormalWeapon( GetDualPrimarySlotForWeapon( weapon ) ))
		TakeMatchingAkimboWeapon(weapon)
	else
		GiveMatchingAkimboWeapon(weapon, weapon.GetMods())
}

void function DEV_ToggleAkimboWeaponAlt(entity player)
{
	if(!IsValid(player))
		return

	array<entity> weapons = player.GetMainWeapons()

	if(weapons.len() < 2)
		return

	entity currentWeapon = player.GetActiveWeapon( eActiveInventorySlot.mainHand )
	entity otherWeapon = weapons[0] == currentWeapon ? weapons[1] : weapons[0]

	if(otherWeapon.GetWeaponClassName().find("melee") > 0)
		return

	if(currentWeapon.GetWeaponClassName().find("melee") > 0)
		return

	int dualslot = GetDualPrimarySlotForWeapon( currentWeapon )

	if(player.GetNormalWeapon( GetDualPrimarySlotForWeapon( currentWeapon ) ))
		player.TakeNormalWeaponByIndex( dualslot )
		else
		player.GiveWeapon( otherWeapon.GetWeaponClassName(), dualslot, otherWeapon.GetMods() )
}

void function TestAnimation( asset model = TEST_MODEL, string animation = TEST_ANIM )
{
    entity player = gp()[0]
    entity prop = CreatePropDynamic(model, player.GetOrigin(), <0,0,0> )

	wait 5
    thread PlayAnim( prop, animation )

    thread function( entity prop ) : (animation)
    {
        if( IsValid( prop ) )
        {
            wait prop.GetSequenceDuration( animation )
			wait 3

            if( IsValid(prop) )
                prop.Destroy()
        }
    }( prop )
}
#endif
