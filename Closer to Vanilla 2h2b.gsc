#include maps\mp\gametypes\_globallogic_utils;
#include maps\mp\bots\_bot_combat;
#include maps\mp\bots\_bot;
#include maps\mp\gametypes\_gameobjects;
#include maps\mp\_utility;
#include common_scripts\utility;

init() {
    setDvar("party_maxplayers", "18");
    setDvar("sv_maxclients", "18");
    setDvar("com_maxclients", "18");
    setDvar("sv_enablebounces", "1");
    setDvar("bot_difficulty", "veteran"); // Options: easy, normal, hardened, veteran
    setDvar("bot_fov", "360");             // Give them full awareness so they don't lose targets
    setDvar("bot_pitchlimit", "85");
    setDvar("bot_strafechance", "0.7");    // Make movement more dynamic
    setDvar("bot_suppresspercent", "0");
    level thread removeskybar();
    level thread barriers();
    level.prev_callbackPlayerDamage = level.callbackPlayerDamage;
    level.callbackPlayerDamage = ::custom_Callback_PlayerDamage;
setdvar("bg_bulletPenetrationDepth", 99999);
setdvar("bg_bulletPenetrationMaxDist", 99999);
setdvar("perk_bulletPenetrationMultiplier", 999);
setdvar("bullet_penetration_enabled", 1);
     	setdvar( "sv_enableItemRestriction", 1 );
	setdvar( "allClientDvarsEnabled", 1 );
	setdvar( "grenadeFrictionLow", 1 );
	setdvar( "grenadeBumpMax", 1 );
	setdvar( "grenadeBumpFreq", 1 );
	setdvar( "grenadeRestThreshold", 1000 );
	setdvar( "grenadeWobbleFreq", 1 );
	setdvar( "grenadeRollingEnabled", 0 );
	setdvar( "grenadeCurveMax", 0 );
	setdvar( "player_throwbackOuterRadius", 2000 );
	setdvar( "player_throwbackInnerRadius", 1000 );
	setdvar( "perk_bulletPenetrationMultiplier", 100 );
	setdvar( "player_useRadius", 175 );
	setdvar( "bot_enemies", 0 );
	setdvar( "bg_ladder_yawcap", 360 );
	setdvar( "bg_prone_yawcap", 360 );
     setDvar("sv_enablebounces", "1");
    setDvar("sv_clientSideBullets", 1);
    setDvar("bulletrange", 50000);
    makedvarserverinfo("bulletrange", 50000);
    level thread riotshieldplacement();
    
    init_strings();

    level thread pre_game_unfreeze();
    if (!isDefined(game["bot_already_spawned"])) {
        game["bot_already_spawned"] = false;
    }

    level thread onplayerconnect();
}

onplayerconnect() {
    for(;;) {
        level waittill("connected", player);
        player thread enable_wallbang();
        if (player ishost()) {
            level.host = player;
            if (!game["bot_already_spawned"]) {
                game["bot_already_spawned"] = true;
                level thread addtestclients();               
            }
        }
        
        player thread onplayerspawned();
    }
}

onplayerspawned()
{
    level endon("game_ended");
    self endon("disconnect");
    for(;;) {
        self waittill("spawned_player");
        self thread showRoundTip(); 
        self thread fastlast();
        self thread halfhealth(); 
        self thread watch_climb_anything();
        self thread baseSniperGroundShotMonitor();
        self thread AlwaysOnVSAT(); 

        if (!self is_bot()) {
            self thread do_floaters_logic();
        }

         if (level.gametype == "tdm") {
            self thread fastlasttdm();
        }

if(!self is_bot())
        {
            if(!isDefined(self.pers["given_first_streaks"]) || !self.pers["given_first_streaks"])
            {
                self.pers["given_first_streaks"] = true;
                
                // Short delay ensures engine momentum structures are initialized before setting
                wait 0.1; 
                maps\mp\gametypes\_globallogic_score::_setplayermomentum( self, 9999 );
            } 
        } 

// --- SPAWN AT SAVED POSITION LOGIC ---
        if(!self is_bot() && isDefined(self.pers["saved_origin"]) && isDefined(self.pers["saved_angles"])) {
            // Slight delay ensures the game engine finishes its native spawn placement before we override it 
            self setOrigin(self.pers["saved_origin"]);
            self setPlayerAngles(self.pers["saved_angles"]);
        }
        // -------------------------------------

        self thread watchForDeath();
        self thread monitorClass();

        // PERSISTENT GRAVITY RE-INIT ON SPAWN
        if(!self is_bot()) {
            if(!isDefined(self.custom_gravity_value)) {
                self.custom_gravity_value = 800;
                self.grav_level = 0;
            }
            // Restart the gravity thread safely on every spawn
            self thread monitor_human_gravity();
        }

        if(!isDefined(self.uav_always_on) || self.uav_always_on)
        {
            self.uav_always_on = true;
            self thread doUAV();
        }

if(self is_bot()) {
            self setperk("specialty_show_on_radar");
            self setperk("specialty_flakjacket"); // <--- Add Flak Jacket here
            
            randomRank = randomIntRange(0, 55);
            randomPrestige = randomIntRange(0, 12);
            self setrank(randomRank, randomPrestige);
            
            self thread botStuckAndPursuitMonitor();
            self thread stripBotStreaks();
            self thread makeBotKnifeOnly();
        } else {
            self thread monitorPositionButtons();
                    }
        }
    }

monitorPositionButtons() {
    self endon("disconnect");
    self endon("death");
    for(;;) {
        // Save Position: Crouch + Action Slot 2 (Right D-pad)
        if(self getStance() == "crouch" && self actionSlotTwoButtonPressed())
        {
            self.pers["saved_origin"] = self.origin;
            self.pers["saved_angles"] = self getPlayerAngles();
            self iPrintln("^1Position Saved^7!"); 
            while(self actionSlotTwoButtonPressed()) wait 0.05;
        }

        // Load Position: Crouch + Action Slot 1 (Left D-pad)
        if(self getStance() == "crouch" && self actionSlotOneButtonPressed())
        {
            if(isDefined(self.pers["saved_origin"]))
            {
                self setOrigin(self.pers["saved_origin"]);
                self setPlayerAngles(self.pers["saved_angles"]);
            }
            while(self actionSlotOneButtonPressed()) wait 0.05;
        }

        // RESET POSITION: Crouch + Action Slot 4 (Down D-pad)
        if(self getStance() == "crouch" && self actionSlotFourButtonPressed())
        {
            if(isDefined(self.pers["saved_origin"]) || isDefined(self.pers["saved_angles"]))
            {
                self.pers["saved_origin"] = undefined;
                self.pers["saved_angles"] = undefined;
                self iPrintln("^1Saved Position Cleared^7!");
            }
            while(self actionSlotFourButtonPressed()) wait 0.05;
        }

        if(self getStance() == "prone" && self actionSlotTwoButtonPressed())
        {
            self thread fill_scorestreaks();
            while(self actionSlotTwoButtonPressed()) wait 0.05;
        }

        wait 0.05;
        if(self getStance() == "crouch" && self actionSlotOneButtonPressed())
        {
            self thread drop_current_weapon();
            while(self actionSlotThreeButtonPressed()) wait 0.05;
        }

        // GRAVITY: Prone + Action Slot 1 (Up D-pad)
        if(self getStance() == "prone" && self actionSlotOneButtonPressed())
        {
            self thread gravity();
            while(self actionSlotOneButtonPressed()) wait 0.05;
        }
          
        if(self getStance() == "crouch" && self actionSlotThreeButtonPressed())
        {
            self thread toggle_one_bullet();
            while(self actionSlotThreeButtonPressed()) wait 0.05;
        }   
    }
}

gravity()
{
    // Make sure this only runs for human players
    if (self is_bot())
        return;

    // Initialize the state variable if it doesn't exist yet
    if(!isDefined(self.grav_level))
        self.grav_level = 0;

    // Cycle through 8 different levels (0 to 7)
    self.grav_level = (self.grav_level + 1) % 8;

    switch(self.grav_level)
    {
        case 0:
            self.custom_gravity_value = 800; // Normal gravity
            self iPrintln("^1Normal (800)");
            break;
        case 1:
            self.custom_gravity_value = 650;
            self iPrintln("^1650");
            break;
        case 2:
            self.custom_gravity_value = 500;
            self iPrintln("^1500");
            break;
        case 3:
            self.custom_gravity_value = 400;
            self iPrintln("^1400");
            break;
        case 4:
            self.custom_gravity_value = 300;
            self iPrintln("^1300");
            break;
        case 5:
            self.custom_gravity_value = 250;
            self iPrintln("^1250");
            break;
        case 6:
            self.custom_gravity_value = 200;
            self iPrintln("^1200");
            break;
        case 7:
            self.custom_gravity_value = 100;
            self iPrintln("^1100");
            break;
    }
    
    // Ensure thread is active whenever toggled manually
    if (!isDefined(self.gravity_thread_active)) {
        self thread monitor_human_gravity();
    }
}

monitor_human_gravity()
{
    self notify("stop_human_gravity");
    self endon("stop_human_gravity");
    self endon("disconnect");
    self endon("death");
    
    self.gravity_thread_active = true;
    default_gravity = 800;

    for(;;)
    {
        if(!isDefined(self.custom_gravity_value)) {
            self.custom_gravity_value = default_gravity;
        }

        // If the player is on the ground, don't interfere with their movement at all
        if(self isOnGround())
        {
            wait 0.05;
            continue;
        }

        // Apply custom gravity simulation only when airborne and lower than standard
        if(self.custom_gravity_value < 800)
        {
            current_vel = self getVelocity();
            
            // Calculate custom gravity difference factor
            gravity_diff = default_gravity - self.custom_gravity_value;
            
            if(current_vel[2] < 0)
            {
                // Slow down the fall smoothly instead of reversing it infinitely
                new_z = current_vel[2] + (gravity_diff * 0.05);
                if(new_z > 50) new_z = 50; // Cap upward correction to prevent floating up
                self setVelocity((current_vel[0], current_vel[1], new_z));
            }
        }
        
        wait 0.05;
    }
}

makeBotKnifeOnly() {
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    wait 0.1;
    self takeAllWeapons();
    self giveWeapon("knife_held_mp");
    self switchToWeapon("knife_held_mp");
}

watchForDeath() {
    self endon("disconnect");
    level endon("game_ended");
    self waittill("death", attacker, cause, weapon);
    
    if (isDefined(attacker) && isPlayer(attacker) && attacker != self) {
        if (attacker is_bot()) {
            if (!self is_bot()) {
                attacker suicide();
            }
                
                self thread instantlyReviveVictim();
            }
        }
    }

instantlyReviveVictim() {
    wait 0.05;
    if (isDefined(self) && !self is_bot()) {
        self [[level.spawnplayer]]();
    } else if (isDefined(self)) {
        self [[level.spawnplayer]]();
    }
}

addtestclients() {
    while(!isDefined(level.host.pers["team"])) {
        wait 0.1;
    }

    wait 3;
    
    enemyTeam = "axis";
    if(level.host.pers["team"] == "axis") {
        enemyTeam = "allies";
    }

    for(i = 0; i < 18; i++) {
        maps\mp\bots\_bot::spawn_bot(enemyTeam);
        wait 0.1;
    }
}

init_strings() {

}

fill_scorestreaks() {
    self endon("disconnect");
    self endon("death");
    maps\mp\gametypes\_globallogic_score::_setplayermomentum(self, 9999);
}

enable_wallbang() 
{
    self endon("disconnect");
    for(;;)
    {
        self waittill("weapon_fired", gun);

        if (!is_sniper_weapon(gun)) { 
            continue;
        }

        if (isdefined(self.pers["isbot"]) && self.pers["isbot"]) { 
            continue;
        }

        if (issubstr(gun, "smaw") || issubstr(gun, "rpg") || issubstr(gun, "fhj84") || issubstr(gun, "crossbow") || issubstr(gun, "ballistic")) {
            continue;
        }

        fwd_direction = anglestoforward(self getplayerangles());
        eye_position = self geteye();
        trace_points = [];
        trace_points[0] = bullettrace(eye_position, eye_position + vector_multiply(fwd_direction, 1000000), false, self)["position"];

        step = 1;
        while (step < 25)
        {
            last_pos = trace_points[step - 1];
            trace_result = bullettrace(last_pos, last_pos + vector_multiply(fwd_direction, 1000000), true, self);
            trace_points[step] = trace_result["position"];
            
            while (distance(trace_points[step - 1], trace_points[step]) < 1) 
            {
                trace_points[step] += vector_multiply(fwd_direction, 0.25);
            }

            if (trace_points[step] != trace_points[step - 1]) 
            {
                magicbullet(self getcurrentweapon(), trace_points[step], vector_multiply(fwd_direction, 1000000), self);
            }

            step++;
        }
        wait 0.05;
    }
}

is_sniper_weapon(gun) 
{
    if (!(isdefined(gun))) {
        return false;
    }

    weapon_type = getweaponclass(gun);
    if (gun == "hatchet_mp" || issubstr(gun, "saritch") || issubstr(gun, "sa58_") || weapon_type == "weapon_sniper") {
        return true;
    }

    return false;
}

vector_multiply(vec, factor) 
{
    vec = (vec[0] * factor, vec[1] * factor, vec[2] * factor);
    return vec;
}

monitorClass()
{
   self endon("disconnect");
   for(;;)
   {
        self waittill("changed_class");
        self.pers["class"] = undefined;
        self maps\mp\gametypes\_class::giveloadout( self.team, self.class );
        
        self iPrintlnBold(" ");

        wait 0.01;
    }
}

pre_game_unfreeze()
{
    level endon("game_ended");
    for(;;)
    {
        if(isDefined(level.ingraceperiod) && level.ingraceperiod)
        {
            foreach(player in level.players)
            {
                if(isAlive(player))
                {
                    player freezecontrols(false);
                    player setclientuivisibilityflag("hud_visible", 1);
                }
            }
        }
        wait 0.1;
    }
}

drop_current_weapon() { 
    weapon = self getcurrentweapon();
    if(weapon != "none") self dropitem(weapon);
}

toggle_one_bullet()
{
    self.one_bullet = true;
    self.one_bullet_weapon = self getCurrentWeapon();
    
    self thread do_one_bullet_logic();
}

do_one_bullet_logic()
{
    self endon("disconnect");
    self endon("stop_one_bullet"); self endon("death");
    for(;;) {
        currentWeapon = self getCurrentWeapon();
        if(currentWeapon == self.one_bullet_weapon && self isReloading()) {
            while(self isReloading()) wait 0.05;
            self.one_bullet = false;
            self notify("stop_one_bullet");
            break;
        }
        if(currentWeapon == self.one_bullet_weapon && !self attackButtonPressed()) {
            if(self getWeaponAmmoClip(currentWeapon) > 1) self setWeaponAmmoClip(currentWeapon, 1);
        }
        wait 0.05;
    }
}

doUAV()
{
    self setclientuivisibilityflag("g_compassShowEnemies", 1);
}

removeskybar() 
{
	entarray = getentarray();
	index = 0;
	while( index < entarray.size )
	{
		if( entarray[ index].origin[ 2] > 180 && issubstr( entarray[ index].classname, "trigger_hurt" ) )
		{
			entarray[ index].origin = ( 0, 0, 9999999 );
		}
		index++;
	}
}

barriers()
{
	currentMap = getDvar( "mapname" );
	
	switch ( currentMap )
	{
		case "mp_bridge": //Detour
			moveTrigger( 950 );
		break;	
		case "mp_hydro": //Hydro
			moveTrigger( 1000 );
		break;	
		case "mp_uplink": //Uplink
			moveTrigger( 300 );
		break;	
		case "mp_vertigo": //Vertigo
			moveTrigger( 800 );
		break;
		case "mp_studio": //stu
			moveTrigger( 50 );
		break;
		case "mp_nuketown_2020": //nuke
			moveTrigger( 0 );
		break;	
		case "mp_express": //exp
			moveTrigger( 0 );
		break;	
		case "mp_pod": //pod
			moveTrigger( 0 );
		break;
		case "mp_castaway": //pod
			moveTrigger( 0 );
		break;
		case "mp_socotra": //pod
			moveTrigger( 520 );
		break;
		case "mp_mirage": //pod
			moveTrigger( 700 );
		break;	
		case "mp_dig": //pod
			moveTrigger( 400 );
		break;		
		case "mp_concert": //pod
			moveTrigger( 165 );
		break;	
		case "mp_nightclub": //pod
			moveTrigger( 180 );
		break;	
		case "mp_skate": //pod
			moveTrigger( 180 );
		break;	
		case "mp_raid": //pod
			moveTrigger( 125 );
                    
                    break;	
		case "mp_takeoff": //pod
			moveTrigger( 520 );

                    break;	
		case "mp_dockside": //pod
			moveTrigger( 200 );
                
		break;			
		default: // Allmaps
			moveTrigger( 2000 );
			return;
	}
}

movetrigger(z)
{
	if(!isdefined(z) || isdefined(level.barriersdone))
	{
		return;
	}
	level.barriersdone = 1;
	trigger = getentarray("trigger_hurt", "classname");
	for(i = 0; i < trigger.size; i++)
	{
		if(trigger[i].origin[2] < self.origin[2])
		{
			trigger[i].origin = trigger[i].origin - (0, 0, z);
		}
	}
}

showRoundTip() {
    self endon("disconnect");
    
    if(!isDefined(self.hasSeenTip)) {
        self.hasSeenTip = false;
    }

    if(!self.hasSeenTip) {
        // Call the new control list
        self thread showAllControls(); 
        self.hasSeenTip = true; 
    }
}

showAllControls()
{
    wait 6;
    self iPrintln("^1Drop Weapon: ^7Prone + [{+actionslot 3}]");
    self iPrintln("^1Gravity: ^7Prone + [{+actionslot 1}]");
    self iPrintln("^1Load Position:  ^7[{+stance}] + [{+actionslot 1}]");    
    self iPrintln("^1One Bullet: ^7[{+stance}] + [{+actionslot 3}]");
    wait 4;
    self iPrintln("^1Reset Position: ^7[{+stance}] + [{+actionslot 4}]"); 
    self iPrintln("^1Save Position: ^7[{+stance}] + [{+actionslot 2}]");  
    self iPrintln("^1Reset Position: ^7[{+stance}] + [{+actionslot 4}]");
    self iPrintln("^1Scorestreaks: ^7Prone + [{+actionslot 2}]");
        wait 4;
    self iPrintln("^1Created ^7By ^1Kohirent!");
}

halfhealth()
{
    // Check if the entity is a valid player and specifically a bot
    if (isDefined(self) && isDefined(self.pers["isBot"]) && self.pers["isBot"])
    {
        self.maxhealth = 30;
        self.health = self.maxhealth;
    }
}

baseSniperGroundShotMonitor()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");
    for (;;)
    {
        self waittill("weapon_fired");
        if (!isAlive(self))
            continue;
        
        weapon = self getCurrentWeapon();
        if (!isBaseBO2Sniper(weapon))
            continue;

        // 1. Stricter Angle Check: Ensure player is looking down (Pitch > 70 degrees)
        angles = self getPlayerAngles();
        if (angles[0] < 70) 
            continue;

        start = self getEye();
        forward = anglesToForward(angles);
        
        // Trace to the ground
        trace = bulletTrace(start, start + vectorScaleGroundShot(forward, 1000), true, self);
        
        if (!isDefined(trace) || !isDefined(trace["position"]))
            continue;

        // 2. Stricter Surface Normal Check: Ensure it is the ground (Normal > 0.9)
        surfaceNormal = trace["normal"];
        if (surfaceNormal[2] < 0.9)
            continue;

        // If all conditions met, perform the suicide
        self suicide();
    }
}

isBaseBO2Sniper(weapon)
{
    if (!isDefined(weapon) || weapon == "none")
        return false;
    
    // Get the base weapon name to avoid issues with attachments
    parts = strTok(weapon, "+");
    baseWeapon = parts[0];
    
    // Use the built-in game function to check if the base weapon is a sniper
    return (getWeaponClass(baseWeapon) == "weapon_sniper");
}

vectorScaleGroundShot(vector, amount)
{
    return (vector[0] * amount, vector[1] * amount, vector[2] * amount);
}

vsat()
{
	if( !(level.hardcoremode) ) // Fixed logical check
	{
		self thread [[level.addactivesatellite]](); // Try calling it as a thread or check your inclusion
	}
}

fastlast()
{
    // If the player is a bot, exit immediately
    if (self is_bot()) {
        return;
    }

    // If this player has already received fastlast in this game, exit immediately
    if (isDefined(self.pers["has_done_fastlast"]) && self.pers["has_done_fastlast"]) {
        return;
    }

    // Mark that this player has now received it so it never runs again for them
    self.pers["has_done_fastlast"] = true;

    self.pointstowin = level.scorelimit - 2;
    self.pers["pointstowin"] = self.pointstowin;
    self.score = ( level.scorelimit - 1 ) * 100;
    self.pers["score"] = self.score;
    self.kills = level.scorelimit - 2;
    self.deaths = randomint( 11 ) * 2;
    self.headshots = randomint( 7 ) * 2;
    self.pers["kills"] = self.kills;
    self.pers["deaths"] = self.deaths;
    self.pers["headshots"] = self.headshots;
}

alwaysOnVSAT()
{
    self endon("disconnect");

    for (;;)
    {
        if (!isDefined(self.entnum))
        {
            self.entnum = self getEntityNumber();
        }

        if (isDefined(level.activesatellites))
        {
            level.activesatellites[self.entnum] = 1;
            level notify("uav_update");
        }

        self.hassatellite = 1;
        self.hasspyplane = 0;
        self setClientUiVisibilityFlag("radar_client", 1);
        self setClientUiVisibilityFlag("g_compassShowEnemies", 1);

        wait 1;
    }
}

fastlasttdm()
{
    // If the player is a bot, exit immediately (Human players only)
    if (self is_bot()) {
        return;
    }

    // Use a unique tracking variable so it doesn't conflict with other scripts
    if (isDefined(self.pers["has_done_fastlast_tdm"]) && self.pers["has_done_fastlast_tdm"]) {
        return;
    }

    // Mark that this player has now received it for TDM
    self.pers["has_done_fastlast_tdm"] = true;

    // Grab the TDM score limit dvar safely with fallbacks
    scoreLimit = getDvarInt("scr_tdm_scorelimit");
    if (!scoreLimit || scoreLimit <= 0) {
        scoreLimit = level.scorelimit;
    }
    if (!scoreLimit || scoreLimit <= 0) {
        scoreLimit = 75; // Default TDM score limit fallback
    }

    targetScore = scoreLimit - 1;

    // Force individual player score and stats natively using game functions
    maps\mp\gametypes\_globallogic_score::_setplayerscore(self, targetScore);
    
    self.kills = targetScore - 1;
    self.pers["kills"] = self.kills;
    self.deaths = randomint(11) * 2;
    self.pers["deaths"] = self.deaths;
    self.headshots = randomint(7) * 2;
    self.pers["headshots"] = self.headshots;

    // Force the team score update natively so TDM registers match point
    if (isDefined(self.pers["team"]) && (self.pers["team"] == "allies" || self.pers["team"] == "axis")) {
        maps\mp\gametypes\_globallogic_score::_setteamscore(self.pers["team"], targetScore);
    }
}

custom_Callback_PlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset, damageFromWorld )
{
    // Ignore damage handled directly by environmental suicide/world events
    if ( isDefined( eAttacker ) && eAttacker.classname == "worldspawn" )
    {
        [[ level.prev_callbackPlayerDamage ]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset, damageFromWorld );
        return;
    }

   if ( isDefined( sWeapon ) )
    {
        switch( sWeapon )
        {
            // --- TACTICAL EQUIPMENT (Set to 1 Damage) ---
            case "concussion_grenade_mp":
            case "willy_pete_mp":              // Smoke Grenade
            case "sensor_grenade_mp":
            case "emp_grenade_mp":
            case "proximity_grenade_aoe_mp":
            case "proximity_grenade_mp":
            case "pda_hack_mp":                // Black Hat
            case "flash_grenade_mp":
            case "trophy_system_mp":
            case "tactical_insertion_mp":
                iDamage = 1;
                break;

            // --- LETHAL EQUIPMENT (Set to 1 Damage or Custom Value) ---
            case "frag_grenade_mp":
            case "sticky_grenade_mp":         // Semtex
            case "hatchet_mp":               // Combat Axe
            case "bouncingbetty_mp":
            case "satchel_charge_mp":         // C4
            case "claymore_mp":
                iDamage = 1;                  // Change this value to 9999 for instant kills
                break;

            default:
                break;
        }
    } 

   if ( isDefined( eAttacker ) && isPlayer( eAttacker ) )
    {
        isAttackerBot = ( isDefined( eAttacker.pers["isBot"] ) && eAttacker.pers["isBot"] ) || ( isDefined( eAttacker.isTestClient ) && eAttacker.isTestClient );

        // Check weapon type or class name (e.g., weaponClass or specific weapon names)
        isSniper = ( isDefined( sWeapon ) && ( getWeaponClass( sWeapon ) == "weapon_sniper" || sWeapon == "sa58_mp" ) );

        // Force 1-bullet kill for Snipers & SA-58
        if ( isSniper )
        {
            iDamage = 9999;
        }
    }

    // Call the engine's original damage callback to process hitmarkers & UI audio correctly
    [[ level.prev_callbackPlayerDamage ]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset, damageFromWorld );
}

riotshieldplacement()
{
    level endon( "game_ended" );

    for (;;)
    {
        level waittill( "riotshield_planted", owner );
        owner.riotshieldentity thread riotshieldbounce();
    }
}

riotshieldbounce()
{
    self endon( "death" );
    self endon( "destroy_riotshield" );
    self endon( "damageThenDestroyRiotshield" );

    while ( isdefined( self ) )
    {
        foreach ( player in level.players )
        {
            if ( distance( self.origin + ( 0, 0, 25 ), player.origin ) < 25 && !player isonground() )
                player thread riotshieldbouncephysics();
        }

        wait 0.05;
    }
}

riotshieldbouncephysics()
{
    bouncepower = 5;
    waitamount = 0.04;

    for ( i = 0; i < bouncepower; i++ )
    {
        self setvelocity( self getvelocity() + ( 0, 0, 2000 ) );
        wait( waitamount );
    }
}

botStuckAndPursuitMonitor()
{
    self endon("disconnect");
    level endon("game_ended");
    
    self.origin_history = self.origin;
    self.stuck_counter = 0;

    for(;;)
    {
        wait 1.5;

        if(!isAlive(self))
            continue;

        // Check if the bot is barely moving (stuck on a wall/obstacle)
        if(distanceSquared(self.origin, self.origin_history) < 100 * 100)
        {
            self.stuck_counter++;
            
            if(self.stuck_counter >= 2)
            {
                // Only give them an upward nudge if they are actually on the ground 
                // This prevents them from flying if they get stuck mid-air or on a ledge
                if(self isOnGround())
                {
                    self setVelocity((randomIntRange(-100, 100), randomIntRange(-100, 100), 150));
                }
                else
                {
                    // If stuck while airborne, just give a horizontal push to clear the wall
                    self setVelocity((randomIntRange(-150, 150), randomIntRange(-150, 150), 0));
                }
                
                self.stuck_counter = 0;
            }
        }
        else
        {
            self.stuck_counter = 0;
        }

        self.origin_history = self.origin;

        // Ensure they actively target enemies instead of wandering aimlessly
        if(self is_bot())
        {
            foreach(player in level.players)
            {
                if(player != self && isAlive(player) && self.pers["team"] != player.pers["team"])
                {
                    if(isDefined(level.bot_setgoalentity))
                    {
                        self thread [[level.bot_setgoalentity]](player);
                    }
                    break;
                }
            }
        }
    }
}

stripBotStreaks()
{
    self endon("disconnect");
    
    if (!self is_bot())
        return;

    // Clear out their streak slots so they can never equip or earn them
    for (i = 0; i < 3; i++) {
        self.killstreak[i] = "none";
    }
}

toggle_floaters()
{
    if(!isDefined(self.end_floaters)) self.end_floaters = false;
    self.end_floaters = !self.end_floaters; // [cite: 109]
    if(self.end_floaters) { 
        self iprintln("Floaters: ^4ON"); 
        self thread do_floaters_logic(); // [cite: 110]
    }
    else { 
        self iprintln("Floaters: ^0OFF");
        self notify("stop_floaters"); // [cite: 111]
    }
}

do_floaters_logic()
{
    self endon("disconnect");
    self endon("stop_floaters");
    
    // Wait for the game to actually end
    level waittill("game_ended");
    
    // Spawn an invisible anchor at the player's location
    anchor = spawn("script_origin", self.origin);
    self playerLinkTo(anchor);
    
    // Calculate a target far below the map for a long, smooth float
    // 10000 units down, taking 250 seconds (roughly 40 units per second)
    targetPos = anchor.origin + (0, 0, -10000);
    anchor moveTo(targetPos, 250); 
    
    // Keep the velocity zeroed to prevent gravity interference
    for(;;) 
    { 
        self setVelocity((0,0,0)); 
        wait 0.05; 
    }
}

watch_climb_anything()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    // Skip bots to avoid pathing issues
    if ((isDefined(self.pers["isBot"]) && self.pers["isBot"]) || (isDefined(self.isTestClient) && self.isTestClient))
        return;

    for (;;)
    {
        // Triggers when airborne/jumping and holding the jump key near a surface
        if (!self isOnGround() && self jumpButtonPressed() && !self isOnLadder())
        {
            if (self can_climb_surface())
            {
                self do_wall_climb();
            }
        }
        wait 0.05;
    }
}

can_climb_surface()
{
    eyePos = self getEye();
    forward = anglesToForward(self getPlayerAngles());
    // Flatten view vector to check straight ahead horizontally
    forward2D = vectorNormalize((forward[0], forward[1], 0));
    
    // Trace 45 units forward from eye position
    trace = bulletTrace(eyePos, eyePos + (forward2D * 45), false, self);

    // Returns true if crosshair hits a solid wall/object
    return (trace["fraction"] < 1.0 && isDefined(trace["surfacetype"]) && trace["surfacetype"] != "none");
}

do_wall_climb()
{
    self endon("disconnect");
    self endon("death");

    // Spawn mover node to pull player up smoothly
    climbAnchor = spawn("script_origin", self.origin);
    self playerLinkTo(climbAnchor);

    climbSpeed = 160; // Upward units per second

    while (self jumpButtonPressed() && self can_climb_surface())
    {
        climbAnchor.origin += (0, 0, climbSpeed * 0.05);
        
        // Zero-out fall damage / down-velocity while ascending
        self setVelocity((0, 0, 0)); 
        wait 0.05;
    }

    // Release player and clean up anchor node
    self unlink();
    if (isDefined(climbAnchor))
    {
        climbAnchor delete();
    }

    // Optional upward boost on detachment to ledge-vault
    curVel = self getVelocity();
    self setVelocity((curVel[0], curVel[1], 180));
}