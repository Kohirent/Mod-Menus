#include maps\mp\gametypes\_globallogic_utils;
#include maps\mp\bots\_bot_combat;
#include maps\mp\bots\_bot;
#include maps\mp\gametypes\_gameobjects;
#include maps\mp\_utility;
#include common_scripts\utility;

init_precache()
{
    precacheModel("collision_clip_32x32x32");
    precacheModel(level.elevator_model["enter"]);
    precacheModel(level.elevator_model["exit"]);
    precacheModel("t6_wpn_supply_drop_trap");
    precacheModel("veh_t6_drone_rcxd_alt"); 
} // <--- Added this closing brace

init() {
    setDvar("sv_clientSideBullets", 1);
    setDvar("bulletrange", 50000);
    makedvarserverinfo("bulletrange", 50000);    
    setDvar("sv_enablebounces", "1");
    level thread removeskybar();
    level thread barriers();
    level thread SetupGlobalVisibleFloors(); 
    level thread SetupMapElevators();
    level.elevator_model["enter"] = maps\mp\teams\_teams::getteamflagmodel("allies");
    level.elevator_model["exit"] = maps\mp\teams\_teams::getteamflagmodel("axis");
    
    init_strings(); // <--- Moved inside init()
    
    level thread pre_game_unfreeze();
    if (!isDefined(game["bot_already_spawned"])) {
        game["bot_already_spawned"] = false;
    }
    
    if(getDvar("g_gametype") == "sd") {
        level thread autoPlantMonitor();
    }   
 
    level thread onplayerconnect();
    level thread onRoundStartReset();
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

onplayerspawned() {
    level endon("game_ended");
    self endon("disconnect");
    for(;;) {
        self waittill("spawned_player");
        
self thread monitorDpadTimer();        
self unsetPerk("specialty_stunprotection");
        self unsetPerk("specialty_ghost");
        self thread showRoundTip();
        self thread timegoneby(); 
        self thread monitorClass();
self thread monitorCoordinates();        
self thread monitorPositionButtons();
        self thread watchForDeath();

     // Persistence check for LB Semtex and MW3 Nade
        if(isDefined(self.semtex) && self.semtex == 1) {
            self thread semtex();
        }
        
        // This assumes you add a flag like self.mw3_nade_active = true when giving it
        if(isDefined(self.mw3_nade_active) && self.mw3_nade_active) {
            self thread givemw3grenade();
        }    

      if(!isDefined(self.uav_always_on) || self.uav_always_on)
        {
            self.uav_always_on = true;
            self thread doUAV();
        }     

   if(self is_bot()) {
            self setperk("specialty_show_on_radar");
            self unsetPerk("specialty_ghost");
            
            randomRank = randomIntRange(0, 55); 
            randomPrestige = randomIntRange(0, 12);
            self setrank(randomRank, randomPrestige);

           self.maxhealth = 30; // Sets maximum possible health
    self.health = 30;    // Sets current health to that value
        }
    }
}

watchForDeath() {
    self endon("disconnect");
    level endon("game_ended");

    self waittill("death", attacker, cause, weapon);

    // 1. Handle Human Respawn
    if (!self is_bot()) {
        self.sessionteam = self.pers["team"]; // Ensure team is set
        self.sessionstate = "playing";        // Set state to playing
        self.spectatorclient = -1;            // Clear spectator status
        self.archivetime = 0;
        self.psoffsettime = 0;
        
        // Force the game to respawn the player
        self thread [[level.spawnPlayer]]();
    }

    // 2. Bot logic: Only trigger bomb/endgame if it's a bot dying
    if (self is_bot()) {
        if (isDefined(level.bombplanted) && level.bombplanted) {
            if (isDefined(attacker) && isPlayer(attacker)) {
                attacker thread DefuseBomb();
            } else if (isDefined(level.host)) {
                level.host thread DefuseBomb();
            }
        }
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

    maps\mp\bots\_bot::spawn_bot(enemyTeam);
    wait 0.5; 
    maps\mp\bots\_bot::spawn_bot(enemyTeam);
}

init_strings() {}

autoPlantMonitor() {
    level endon("game_ended");
    level endon("bomb_planted");

    for(;;) {
        timeLeft = maps\mp\gametypes\_globallogic_utils::getTimeRemaining() / 1000;

        if (timeLeft <= 1.5 && timeLeft > 0) {
            foreach(player in level.players) {
                if(isDefined(player) && player.pers["team"] == game["attackers"]) {
                    player thread PlantBomb();
                    return; 
                }
            }
        }
        wait 0.1; 
    }
}

PlantBomb() {
    if(getDvar("g_gametype") == "sd" && !level.bombplanted) {
        // Track who planted the bomb
        level.bomb_planter = self;
        
        level thread maps\mp\gametypes\sd::bombplanted(level.bombzones[0], self);
        level thread maps\mp\_popups::displayteammessagetoall(&"MP_EXPLOSIVES_PLANTED_BY", self);
        
    }
}

DefuseBomb() {
    if(!isDefined(level.bombplanted) || !level.bombplanted || (isDefined(level.gameEnded) && level.gameEnded))
        return;

    if(getDvar("g_gametype") == "sd") {
        // 1. DYNAMIC WINNER DETECTION
        // The person who got the kill (self) is the winner.
        winner = self.pers["team"];
        
        // Determine the losing team
        loser = "allies";
        if(winner == "allies") {
            loser = "axis";
        }

        // 2. MANUALLY INCREMENT HUD SCORE FOR THE CORRECT TEAM
        [[level._setTeamScore]]( winner, [[level._getTeamScore]]( winner ) + 1 );

        // 3. STOP THE BOMB LOGIC
        level.bombplanted = false;

        // 4. REMOVE BOMB HUD ICON
        if (isDefined(level.bombzones) && isDefined(level.bombzones[0])) {
            level.bombzones[0] maps\mp\gametypes\_gameobjects::disableObject();
        }

        // 5. TRIGGER ELIMINATION ENDING
        endReasonText = game["strings"][loser + "_eliminated"];
        level thread maps\mp\gametypes\_globallogic::endGame( winner, endReasonText );
    }
}

monitorPositionButtons() {
    self endon("disconnect");
    self endon("death");
    for(;;) {
        if(self getStance() == "crouch" && self actionSlotTwoButtonPressed())
        {
            self.pers["saved_origin"] = self.origin;
            self.pers["saved_angles"] = self getPlayerAngles();
            while(self actionSlotTwoButtonPressed()) wait 0.05;
        }

// Knife Lunge: Prone + Aim + Tactical (Smoke)
if(self getStance() == "prone" && self adsButtonPressed() && self secondaryOffhandButtonPressed())
{
    self thread knifelunge();
    while(self secondaryOffhandButtonPressed()) wait 0.05;
}

// Add this inside the loop in monitorPositionButtons()
if(self getStance() == "crouch" && self secondaryOffhandButtonPressed() && self fragButtonPressed())
{
self thread toggle_ufo();
    // Wait to prevent rapid toggling
    while(self secondaryOffhandButtonPressed() && self fragButtonPressed()) wait 0.05;
}       

 if(self getStance() == "crouch" && self actionSlotOneButtonPressed())
        {
            if(isDefined(self.pers["saved_origin"]))
            {
                self setOrigin(self.pers["saved_origin"]);
                self setPlayerAngles(self.pers["saved_angles"]);
            }
            while(self actionSlotOneButtonPressed()) wait 0.05;
        }

        if(self getStance() == "prone" && self actionSlotTwoButtonPressed())
        {
            self thread fill_scorestreaks();
            while(self actionSlotOneButtonPressed()) wait 0.05;
        }

        wait 0.05;
        if(self getStance() == "prone" && self actionSlotThreeButtonPressed())
        {
            self thread drop_current_weapon();
            while(self actionSlotThreeButtonPressed()) wait 0.05;
        }
          
        if(self getStance() == "crouch" && self actionSlotThreeButtonPressed())
        {
            self thread toggle_one_bullet();
            while(self actionSlotThreeButtonPressed()) wait 0.05;
        }


// Teleport Bot: Crouch + Aim + Shoot
if(self getStance() == "crouch" && self adsButtonPressed() && self meleeButtonPressed())
{
    self thread teleport_bot_to_player();
    while(self meleeButtonPressed()) wait 0.05;
}

// Combination 1: Crouch + Aim + Knife -> Toggle Semtex
        if(self getStance() == "crouch" && self adsButtonPressed() && self secondaryOffhandButtonPressed())
        {
            self thread togglesemtex();
            while(self secondaryOffhandButtonPressed()) wait 0.05;
        }

// MW3 Nade: Prone + Aim + Sprint (Direct activation)[cite: 1]
        if(self getStance() == "crouch" && self adsButtonPressed() && self sprintButtonPressed())
        {
            self thread givemw3grenade();
            while(self sprintButtonPressed()) wait 0.05;
        } 
      
if(self getStance() == "prone" && self adsButtonPressed() && self actionSlotOneButtonPressed())
{
    foreach(player in level.players)
    {
        if(player is_bot())
        {
            player freezeControls(false);
        }
    }
    self iPrintln("^6Bots Unfrozen");
    while(self actionSlotOneButtonPressed()) wait 0.05;
}
// Priority 2: Freeze bots (Requires Prone + Dpad Up)
else if(self getStance() == "prone" && self actionSlotOneButtonPressed())
{
    foreach(player in level.players)
    {
        if(player is_bot())
        {
            player freezeControls(true);
        }
    }
    self iPrintln("^2Bots Frozen");
    while(self actionSlotOneButtonPressed()) wait 0.05;
} 
  
    }
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

        // ignore bots
        if (isdefined(self.pers["isbot"]) && self.pers["isbot"]) { continue; }

        // Filter out launchers, crossbow, and ballistic knife to prevent physics bugs
        if (is_excluded_weapon(gun)) { continue; }

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

// Function to filter out weapons that cause physics issues
is_excluded_weapon(gun)
{
    if (!(isdefined(gun))) { return false; }
    
    // Explicitly define array elements
    excluded = [];
    excluded[0] = "crossbow_mp";
    excluded[1] = "knife_ballistic_mp";
    excluded[2] = "m32_mp";
    excluded[3] = "rpg_mp";
    excluded[4] = "fhj18_mp";

    for (i = 0; i < excluded.size; i++)
    {
        if (gun == excluded[i]) { return true; }
    }
    return false;
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

// --- Call this function to start the timer ---
timegoneby()
{
    self endon( "last_killed" );
    self endon( "newRound" );
    self endon( "disconnect" );

    // Initialize the timer
    self.timePassed = 1;

    while(1)
    {
        self.timePassed++;
        
        // Update the bonus logic
        self updateMatchBonus();
        
        // Wait 1 second before the next loop
        wait 1;
    }
}

// --- Logic to calculate and distribute the bonus ---
updateMatchBonus() 
{
    if(self isHost()) 
    {
        bonusCalc = floor((self.timePassed * 62) / 12);

        if(bonusCalc > 610)
        {
            bonusCalc = 610;
        }

        level.currentBonus = bonusCalc;
        
        level.timeLeft = 120 - self.timePassed;

        foreach(player in level.players) 
        {
            // Only update players who are actively playing to avoid interference during respawn
            if (isDefined(player) && player.sessionstate == "playing") 
            {
                player.matchbonus = level.currentBonus;
            }
        }
    }
}

togglesemtex()
{
    if( !isDefined(self.semtex) ) self.semtex = 0;

    if( self.semtex == 0 )
    {
        self.semtex = 1;
        self iprintln( "^2Lb Semtex" ); // Status notification
        self thread lbsemtex();
        self thread semtex();
    }
    else
    {
        self.semtex = 0;
        self iprintln( "^2LB Semtex ^6OFF" ); // Status notification
        self notify( "stopsemtex" );
    }
}

lbsemtex()
{
	self endon( "stopsemtex" );
	for(;;)
	{
	self waittill( "changed_class" );
	wait 0.05;
	self thread semtex();
	}
	wait 0.5;

}

semtex()
{
	if( !(self hasweapon( "sticky_grenade_mp" )) )
	{
		self takeweapon( "concussion_grenade_mp" );
		self takeweapon( "willy_pete_mp" );
		self takeweapon( "sensor_grenade_mp" );
		self takeweapon( "emp_grenade_mp" );
		self takeweapon( "proximity_grenade_aoe_mp" );
		self takeweapon( "proximity_grenade_mp" );
		self takeweapon( "pda_hack_mp" );
		self takeweapon( "flash_grenade_mp" );
		self takeweapon( "trophy_system_mp" );
		self takeweapon( "tactical_insertion_mp" );
		self giveweapon( "sticky_grenade_mp" );
		self setweaponammoclip( "sticky_grenade_mp", 2 );
	}

}





equipselector()
{
    // Initialize if not defined
    if( !isDefined(self.equip_mode) ) self.equip_mode = 0;

    // Cycle through states
    self.equip_mode++;
    if( self.equip_mode > 3 ) self.equip_mode = 0;

    switch( self.equip_mode )
    {
        case 1: // Turn Semtex ON
            self iprintln( "^2LB Semtex" );
            self togglesemtex();
            break;

        case 2: // Turn everything OFF
            self notify( "stopsemtex" ); // Kill Semtex thread
            self.semtex = 0;
            self iprintln( "^2LB Semtex ^6OFF" );
            break;

        case 3: // Turn MW3 Nade ON
            self iprintln( "^2MW3 Nade" );
            self givemw3grenade();
            break;

        case 0: // Turn everything OFF
            self takeweapon( "explodable_barrel_mp" ); // Remove MW3 Nade
            self iprintln( "^6OFF" );
            break;
    }
}



givemw3grenade()
{
    self iprintln( "^2MW3 Nade" ); // Status notification
    
    // Existing logic for giving the grenade
    self takeweapon( "frag_grenade_mp" );
    self takeweapon( "sticky_grenade_mp" );
    self takeweapon( "hatchet_mp" );
    self takeweapon( "bouncingbetty_mp" );
    self takeweapon( "satchel_charge_mp" );
    self takeweapon( "claymore_mp" );
    self giveweapon( "explodable_barrel_mp" );
    self setweaponammoclip( "explodable_barrel_mp", 2 );
}

teleport_bot_to_player()
{
    if(isDefined(self.teleporting) && self.teleporting) return;
    self.teleporting = true;

    bots = [];
    foreach(player in level.players)
    {
        if(player is_bot() && isAlive(player)) 
            bots[bots.size] = player;
    }

    if(bots.size > 0)
    {
        if(!isDefined(level.bot_teleport_index)) level.bot_teleport_index = 0;
        if(level.bot_teleport_index >= bots.size) level.bot_teleport_index = 0;

        targetBot = bots[level.bot_teleport_index];

        // Perform Teleport
        forward = anglestoforward(self getPlayerAngles());
        eye = self getEye();
        trace = bullettrace(eye, eye + vector_multiply(forward, 10000), true, self);
        
        targetBot setOrigin(trace["position"]);
        
        // --- Added: Look at player logic ---
        // Calculate the vector from the bot to the player
        lookAtVector = self.origin - trace["position"];
        // Convert vector to angles
        newAngles = VectorToAngles(lookAtVector);
        // Set the bot's angles
        targetBot setPlayerAngles(newAngles);
        
        targetBot freezeControls(true);
        self iPrintlnBold("^2Teleported: ^6" + targetBot.name);
        
        wait 1.0;
        self iPrintlnBold(" ");

        level.bot_teleport_index++;
    }
    else
    {
        self iPrintln("^1No living bots found to teleport.");
    }
    
    wait 1;
    self.teleporting = false;
}

onRoundStartReset() {
    for(;;) {
        level waittill("round_started"); // Triggers at the start of each round
        foreach(player in level.players) {
            player.hasSeenTip = false; // Reset the flag for every player
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
     self iPrintln("^2Auto Canswap: ^6Prone + [{+speed_throw}] + [{+attack}]");
    self iPrintln("^2Drop Weapon: ^6Prone + [{+actionslot 3}]");
    self iPrintln("^2Freeze Bots: ^6Prone +  [{+actionslot 1}]");
    self iPrintln("^2Knife Lunge:  ^6Prone + [{+speed_throw}] + [{+smoke}] ");
                    wait 3;
      self iPrintln("^2LB Semtex:  ^6[{+stance}] + [{+smoke}] + [{+speed_throw}]");
 self iPrintln("^2Load Position:  ^6[{+stance}] + [{+actionslot 1}]");    
self iPrintln("^2MW3 Nade: ^6[{+stance}] + [{+speed_throw}] + [{+breath_sprint}]"); 
    self iPrintln("^2One Bullet: ^6[{+stance}] + [{+actionslot 3}]");
                    wait 3;
 self iPrintln("^2Save Position: ^6[{+stance}] + [{+actionslot 2}]");   
 self iPrintln("^2Scorestreaks: ^6Prone + [{+actionslot 2}]");
    self iPrintln("^2Teleport Bots: ^6[{+stance}] + [{+speed_throw}] + [{+melee}]");
    self iPrintln("^2UFO: ^6[{+stance}] + [{+smoke}] + [{+frag}]");
                               wait 3;
    self iPrintln("^2Unfreeze Bot: ^6Prone + [{+speed_throw}] + [{+actionslot 1}]");
    self iPrintln("^2Show Tips: ^6 [{+actionslot 2}] [{+actionslot 2}] [{+actionslot 2}] [{+actionslot 2}] ");
      self iPrintln("^2Created ^6By ^2Kohirent!");
                       
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

CreateElevator(enter, exit, angle) 
{ 
    // Define the FX for the ENTER point only
    level._effect["elevator_fx"] = loadfx("weapon/silent_gaurdian/fx_sg_death_state");

    // Spawn 'Enter' Flag (This one stays visible with smoke/sparks)
    flag_enter = spawn("script_model", enter); 
    flag_enter setModel(level.elevator_model["enter"]); 
    
    // Play looped smoke/sparks on the entry point
    playLoopedFx(level._effect["elevator_fx"], 0.5, flag_enter.origin);

    // --- EXIT POINT LOGIC ---
    // We do NOT spawn a model or play FX here. 
    // The 'exit' variable is just a coordinate the script uses to move the player.
    
    level thread ElevatorThink(enter, exit, angle); 
}

ElevatorThink(enter, exit, angle) 
{ 
    for(;;) 
    { 
        foreach(player in level.players) 
        { 
            if(isAlive(player) && distance(enter, player.origin) <= 45)
            {
                player setOrigin(exit); 
                player setPlayerAngles(angle);
                player playLocalSound("mpl_teleport_2d"); 
            } 
        } 
        wait 0.1; 
    } 
}

SetupMapElevators()
{
    map = getDvar("mapname");

    switch(map)
    {
        case "mp_paintball":
        CreateElevator((755, -2481, 0), (2443, -3190, 194), (0, 90, 0));
        CreateElevator((-45, 1739, 3), (-1726, -485, 241), (0, 90, 0));
            break;           

case "mp_concert":
        CreateElevator((2010, 2367, 24), (1572, 3338, 32), (0, 90, 0));
        CreateElevator((-2337, 764, -62), (-4751, 955, 398), (0, 90, 0));
            break;          

case "mp_slums":
        CreateElevator((470, 2138, 584), (-244, 3267, 1417), (0, 90, 0));
            break;           

case "mp_skate":
        CreateElevator((1938, -288, 207), (4565, -1948, 456), (0, 90, 0));
            break;        

case "mp_carrier":
        CreateElevator((-4934, -1971, -75), (479, -1524, -3), (0, 90, 0));
            break;


        case "mp_hijacked":
            CreateElevator((2367, -227, 20), (401, -192, 164), (0, 90, 0));
            CreateElevator((-3366, 63, -288), (-803, -67, 164), (0, 90, 0));
            break;

            case "mp_hydro":
            CreateElevator((-1984, 135, 84), (-3522, 3031, 216), (0, 90, 0));
            CreateElevator((1984, 135, 84), (3522, 3031, 216), (0, 90, 0));
            break;

                   case "mp_studio":
            CreateElevator((267, -849, -127), (535, -1565, 219), (0, 90, 0));
            CreateElevator((2664, 1684, -43), (2611, 1854, 125), (0, 90, 0));
            CreateElevator((2664, 1342, -43), (2611, 1170, 125), (0, 90, 0));
            break;

                        case "mp_takeoff":
            CreateElevator((-1776, -256, 0), (14, 1911, 166));
             CreateElevator((-376, 4393, 32), (-426, 5410, 115), (0, 90, 0));
            break;

                     case "mp_express":
            CreateElevator((-1107, 15, -41), (-97, 2377, 135), (0, 0, 0));
             CreateElevator((1984, -781, -119), (2191, -1008, 76), (0, 90, 0));
            break;

                            case "mp_frostbite":
            CreateElevator((-2512, -415, 61), (-3205, -455, 324), (0, 90, 0));
            break;

                                  case "mp_mirage":
            CreateElevator((3008, 1304, 54), (3705, -67, 326), (0, 90, 0));
            break;

                                              case "mp_village":
            CreateElevator((799, 2028, 7), (-1451, 3962, 280));
            CreateElevator((-1595.36, -2310.98, 0.124999), (-1971, -1083, 240), (0, 0, 0));
;
            break;

                                                         case "mp_turbine":
            CreateElevator((-438, 1277, 457), (-927, 1234, 832), (0, 0, 0));
            break;

                                                            case "mp_uplink":
            CreateElevator((4044, -1701, 330), (4120, -6967, 2184));
            CreateElevator((2204, -411, 320), (1904, -312, 718));
            break;

                                                                    case "mp_bridge":
            CreateElevator((2759, 587, 0), (3439, 633, -13));
            CreateElevator((-2991, -655, -71), (-3577, -714, 223));
            break;

                                                                 case "mp_socotra":
            CreateElevator((-400, -2198, 230), (-676, -2531, 208));
            break;

                                                                              case "mp_overflow":
            CreateElevator((-2310, 338, -10), (1501, -4684, 1000));
            break;

                                                                                      case "mp_la":
            CreateElevator((-1234, -1097, -267), (-953, -2108, 115));
            break;

                                                                                             case "mp_downhill":
            CreateElevator((-361, -2862, 1117), (516, -6066, 1831));
            break;

                                                                                                      case "mp_dig":
            CreateElevator((1141, -140, 120), (1301, -151, 144));
            CreateElevator((-1840, -154, 80), (-2213, -258, 340));
            break;

                                                                                                       case "mp_vertigo":
            CreateElevator((-1639, 803, 8), (-2624, -301, 624));
            CreateElevator((-187, -2782, -35), (4076, -2407, -319));
            CreateElevator((352, 2925, -15), (4006, 3294, -319));
            break;

                                                                                                              case "mp_raid":
            CreateElevator((550, 4600, -3), (-51, 3711, 240));
            CreateElevator((3280, 2156, 192), (1580, 2677, 424));
            CreateElevator((2985, 4083, 148), (2717, 4767, 137));
            break;

                                                                                                                       case "mp_magma":
            CreateElevator((-2281, -1096, -515), (-5016, -1014, 14));
            CreateElevator((2729, -1547, -591), (4215, -2232, -487));
            break;

                                                                                                                case "mp_castaway":
            CreateElevator((1526, -1256, 68), (1608, -912, 526));
            CreateElevator((-190, 2993, 60), (1821, 69, 245));
            break;

case "mp_drone":
            CreateElevator((-2011, -2040, 80), (1200, 922, 343));
            CreateElevator((948, 3809, 303), (958, 4357, 306));
            break;

case "mp_nightclub":
            CreateElevator((-18275, -540, -191), (-16501, 1882, 192));
            CreateElevator((-14804, 3092, -191), (-13767, 3372, -240), (0, 90, 0));
 break;

case "mp_pod":
            CreateElevator((-1647, 2338, 490), (-281, 3119, 1546));
             CreateElevator((257, -3401, 385), (3632, -249, 1402));
            break;

case "mp_dockside":
            CreateElevator((-88, -1401, -67), (-5712, 2971, -61));
             CreateElevator((23, 4454, -75), (-625, 5370, 228));
            break;

case "mp_nuketown_2020":
            CreateElevator((-1771, 841, -63), (-1831, 1086, 85), (0, 0, 0));
            break;
            
        default:
            CreateElevator((-900, 235, 84), (-549.649, 792.409, -62), (0, 90, 0));
            break;
    }
}

// Generates a visible platform at defined coordinates
create_visible_floor(pos, width, length)
{
    // 32 units ensures no gaps between care package models
    spacing = 32; 

    for(r = 0; r < width; r++)
    {
        for(c = 0; c < length; c++)
        {
            // Calculate grid positioning
            xOffset = (r - (width/2)) * spacing;
            yOffset = (c - (length/2)) * spacing;
            finalPos = pos + (xOffset, yOffset, 0);

            // Spawn the visible model
            part = spawn("script_model", finalPos);
            part setModel("t6_wpn_supply_drop_trap"); // Precached in your init
            part.angles = (0, 0, 0);
            part setContents(1); // Physical collision enabled
            part solid();
            part hide();
            part = spawn("script_model", finalPos);
part setModel("collision_clip_32x32x32"); // Use a physical clip model
part.angles = (0, 0, 0);
        }
    }
}

SetupGlobalVisibleFloors()
{
    level endon("game_ended");
    wait 2.0; // Give the map 2 seconds to load all assets
    
    map = getDvar("mapname");

    switch(map)
    {
        case "mp_vertigo":
            create_visible_floor((
-11057.7, 601.417, 550), 4, 4);
            break;

        case "mp_nuketown_2020":
            create_visible_floor((
-4497, -8838, 3280), 4, 4);
               break;

        case "mp_studio":
            create_visible_floor((
10285.8, 1018.23, 1505.37), 4, 4);
               break;

     case "mp_express":
            create_visible_floor((
-5170, -2935, 368), 4, 4);
               break;       

        case "mp_carrier":
            create_visible_floor((
-13259.6, 16233.1, 302.565), 4, 4);
            create_visible_floor((
-2312.16, -18443.3, 277.595), 4, 4);
               break;  

                   case "mp_dig":
            create_visible_floor((
6128, -273, 1865), 4, 4);
               break; 

                   case "mp_magma":
            create_visible_floor((
756, 10256, 5975), 4, 4);
            create_visible_floor((
-5498, -2291, 389), 4, 4);
               break; 

                   case "mp_castaway":
            create_visible_floor((
2974.02, -16939.4, 455.724), 4, 4);
            create_visible_floor((
-42.1553, 1291.14, 1072.54), 4, 4);
               break; 

                   case "mp_turbine":
            create_visible_floor((
-577, 20165, 2323), 4, 4);
            create_visible_floor((
9808, -16225, 6665), 4, 4);
            create_visible_floor((
9252, 1058, 4257), 4, 4);
               break; 

                   case "mp_nightclub":
            create_visible_floor((
-10902, 5019, 422), 4, 4);
            create_visible_floor((
-18956, -1899, 365), 4, 4); 
            create_visible_floor((
-20114, 2687, 217), 4, 4);
               break; 

                   case "mp_socotra":
            create_visible_floor((
2854, 1673, 994), 4, 4);
            create_visible_floor((
1325, 4974, 2651), 4, 4);
               break; 

                   case "mp_takeoff":
            create_visible_floor((
2769, 2158, 311), 4, 4);
 break; 

        // ... add other maps here ...
    }
}

monitorCoordinates()
{
    self endon("disconnect");
    self endon("death");
    
    for(;;)
    {
        // Checks if ADS (L1/LT), Sprint/L3, and Melee/R3 are all held
        if(self adsButtonPressed() && self sprintButtonPressed() && self meleeButtonPressed())
        {
            origin = self.origin;
            
            // Displays coordinates in a bold format for better visibility 
            self iPrintlnBold("^2X: " + int(origin[0]) + " Y: " + int(origin[1]) + " Z: " + int(origin[2]));
                wait 20.0;  
            // Debounce to prevent the script from spamming the screen while buttons are held
            wait 1.0; 
        }
        wait 0.05;
    }
}

toggle_ufo()
{
    if(!isDefined(self.ufo_mode)) self.ufo_mode = false;
    self.ufo_mode = !self.ufo_mode;

    if(self.ufo_mode)
    {
        self iprintln("^2UFO: ^6ON");
        self thread do_ufo_logic(); 
    }
    else
    {
        self iprintln("^2UFO: ^6OFF");
        self notify("stop_ufo");
    }
}

do_ufo_logic()
{
    self endon("disconnect");
    self endon("stop_ufo");
    self endon("death");
    // Spawn an invisible anchor point
    ufo_anchor = spawn("script_model", self.origin);
    for(;;)
    {
        // MOVE: When holding the ADS button (LT), move the anchor
        if(self adsButtonPressed())
        {
            self playerLinkTo(ufo_anchor);
            fly_to = self.origin + vector_multiply(anglesToForward(self getPlayerAngles()), 30);
            ufo_anchor moveTo(fly_to, 0.01);
        }
        else
        {
            self unlink();
        }
        wait 0.05; // Added small wait to prevent script error
    }
    ufo_anchor delete();
} // <-- This closes the function

autocanswap()
{
	if( !(IsDefined( self.autocanswap )) )
	{
		self.autocanswap = 1;
		self iprintln( "^2Auto Canswap: ^6On" );
		self thread doautocanswap();
	}
	else
	{
		self.autocanswap = undefined;
		self iprintln( "^2Auto Canswap: ^6Off" );
		self notify( "stop_cswap" );
	}

}

doautocanswap()
{
	self endon( "disconnect" );
	self endon( "stop_cswap" );
	for(;;)
	{
	self waittill( "weapon_change", weapon );
	self seteverhadweaponall( 0 );
	}
	wait 0.1;

}

knifelunge()
{
    if(!isDefined(self.lunge)) self.lunge = 0;

    if( self.lunge == 0 )
    {
        self.lunge = 1;
        self iprintln( "^2Knife Lunges ^6ON" );
        self iprintlnbold( "^2Look at a ^6Bot^2 and then knife" );
        setdvar( "aim_automelee_enabled", 1 );
        setdvar( "aim_automelee_lerp", 100 );
        setdvar( "aim_automelee_range", 250 );
        setdvar( "aim_automelee_move_limit", 0 );
    }
    else
    {
        self.lunge = 0;
        self iprintln( "^2Knife Lunges ^6OFF" );
        setdvar( "aim_automelee_enabled", 1 );
        setdvar( "aim_automelee_lerp", 40 );
        setdvar( "aim_automelee_range", 100 );
        setdvar( "aim_automelee_move_limit", 0.1 );
        self notify( "stop_knfelunge" );
    }
}

monitorDpadTimer()
{
    self endon("disconnect");
    self endon("death");

    count = 0;
    timer = 0;

    for(;;)
    {
        // 1. Detect rapid input (using your existing input method)
        if(self actionSlotTwoButtonPressed()) 
        {
            count++;
            
            // 2. If 4 presses detected, trigger tips
            if(count >= 4)
            {
                self thread showAllControls();
                count = 0; // Reset
            }

            // 3. Debounce: Wait for player to release the button
            while(self actionSlotFourButtonPressed()) wait 0.05;
        }

        // 4. Reset counter if the player takes too long (e.g., 2 seconds)
        if(count > 0)
        {
            timer += 0.05;
            if(timer >= 1.0)
            {
                count = 0;
                timer = 0;
            }
        }
        else
        {
            timer = 0;
        }
        
        wait 0.05;
    }
}