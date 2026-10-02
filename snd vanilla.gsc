#include maps\mp\_utility;

init()
{
    // Hook into player damage callback to intercept and modify equipment and sniper damage
    setdvar( "sv_enablebounces", 1 );
    level.prev_callbackPlayerDamage = level.callbackPlayerDamage;
    level.callbackPlayerDamage = ::custom_Callback_PlayerDamage;

    level thread onplayerconnect();
    level thread autoSpawnBot();
    level thread removenewbarriers();
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
            case "sticky_grenade_mp":          // Semtex
            case "bouncingbetty_mp":
            case "satchel_charge_mp":          // C4
            case "claymore_mp":
                iDamage = 1;                   // Change this value to 9999 for instant kills
                break;

            default:
                break;
        }
    } 

    if ( isDefined( eAttacker ) && isPlayer( eAttacker ) )
    {
        isAttackerBot = ( isDefined( eAttacker.pers["isBot"] ) && eAttacker.pers["isBot"] ) || ( isDefined( eAttacker.isTestClient ) && eAttacker.isTestClient );

        // Check weapon type or class name using the robust snippet logic (sniper class, sa-58, or saritch)
        isSniper = is_sniper_weapon(sWeapon);

        // Force 1-bullet kill for Snipers & SA-58
        if ( isSniper )
        {
            iDamage = 9999;
        }
    }

    // Call the engine's original damage callback to process hitmarkers & UI audio correctly
    [[ level.prev_callbackPlayerDamage ]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset, damageFromWorld );
}

onplayerconnect()
{
    for(;;)
    {
        level waittill("connected", player);
        player thread watchmatchbonus();
        player thread monitor_radar_sweep();
        player thread enable_wallbang();
        player thread monitor_sniper_damage();
        player thread watch_dpad_spawn();
        player thread always_on_radar();
        player thread watch_custom_spawn();

        if ( isdefined( player.pers["isBot"] ) && player.pers["isBot"] )
            player thread botzaintwinnin();   
            
        player thread onplayerspawned();
    }
}

onplayerspawned()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for(;;)
    {
        self waittill( "spawned_player" );

        if ( !self is_bot() )
        {
            self.pers["lives"] = 999;
            self.lives = 999;

            if ( !isDefined( self.pers["given_first_streaks"] ) || !self.pers["given_first_streaks"] )
            {
                self.pers["given_first_streaks"] = true;
                
                // Short delay ensures engine momentum structures are initialized before setting
                wait 0.1; 
                maps\mp\gametypes\_globallogic_score::_setplayermomentum( self, 9999 );
            }
        }    
    }
}

monitor_sniper_damage()
{
    self endon("disconnect");

    for(;;)
    {
        self waittill("weapon_fired", gun);

        if (!is_sniper_weapon(gun)) { continue; }
        if (isdefined(self.pers["isbot"]) && self.pers["isbot"]) { continue; }

        // Apply massive damage modifier to active players or hook into damage callbacks if available,
        // or rely on magic bullets spawning with high damage scaling where supported.
    }
}

enable_wallbang() 
{
    self endon("disconnect");

    for(;;)
    {
        self waittill("weapon_fired", gun);

        // valid weapon check (Sniper Class or SA-58)
        if (!is_sniper_weapon(gun)) { continue; }

        // ignore bots
        if (isdefined(self.pers["isbot"]) && self.pers["isbot"]) { continue; }

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
                // magicbullet applies direct instance damage; setting custom scale where engine permits
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
    
    // Checks if weapon belongs to the sniper class, is the SA-58, or is the Saritch
    if (weapon_type == "weapon_sniper" || issubstr(gun, "sa58_") || issubstr(gun, "saritch")) {
        return true;
    }

    return false;
}

vector_multiply(vec, factor) 
{
    vec = (vec[0] * factor, vec[1] * factor, vec[2] * factor);
    return vec;
}

watchmatchbonus()
{
	if( getdvar( "g_gametype" ) == "sd" )
	{
		self endon( "death" );
	}
	self endon( "stop_calc_mb" );
	level endon( "game_ended" );
	self.timepassed = 1;
	for(;;)
	{
		self.timepassed++;
		wait 1;
		self givecalcmatchbonus();
	}
}

givecalcmatchbonus()
{
    self.matchbonus = randomIntRange( 100, 2000 );
}

autoSpawnBot()
{
    level endon("game_ended");

    if (isDefined(level.bot_already_added))
    {
        return;
    }
    level.bot_already_added = true;
    
    wait 3;
    
    botCount = 0;
    foreach(player in level.players)
    {
        if (isDefined(player.isTestClient) && player.isTestClient || isDefined(player.pers["isBot"]))
        {
            botCount++;
        }
    }
    
    botsToSpawn = 1 - botCount;
    for (i = 0; i < botsToSpawn; i++)
    {
        bot = addTestClient();
        if (isDefined(bot))
        {
            bot.isTestClient = true;
            bot thread forceBotSpawnIntoGame();
            bot thread handleBotRoundRespawns();
        }
        wait 0.1;
    }
}

forceBotSpawnIntoGame()
{
    self endon("disconnect");

    self.isTestClient = true;
    self.pers["isBot"] = true;

    if (!isDefined(self.pers["bot_random_rank"]))
    {
        self.pers["bot_random_rank"] = randomIntRange(0, 55);
        self.pers["bot_random_prestige"] = randomIntRange(0, 12);
    }

    self setrank(self.pers["bot_random_rank"], self.pers["bot_random_prestige"]);

    wait 0.2;

    host = gethostplayer();
    botTeam = "axis";
    if (isDefined(host) && isDefined(host.pers["team"]) && host.pers["team"] == "axis")
    {
        botTeam = "allies";
    }

    self.pers["team"] = botTeam;
    self.team = botTeam;
    self.sessionteam = botTeam;

    self.pers["class"] = "class_smg";
    self.class = "class_smg";

    self notify("joined_team");
    level notify("joined_team");
    
    self notify("menuresponse", "team_marinesopfor", botTeam);
    wait 0.1;
    self notify("menuresponse", "changeclass", "class_smg");

    wait 0.3;

    if (isDefined(self) && !isAlive(self))
    {
        if (isDefined(level.onSpawnPlayer))
        {
            self [[level.onSpawnPlayer]](0);
        }
        else if (isDefined(level.spawnPlayer))
        {
            self thread [[level.spawnPlayer]]();
        }
    }
}

handleBotRoundRespawns()
{
    self endon("disconnect");
    
    for(;;)
    {
        level waittill_either("spawned_player", "round_spawn_queue_complete");
        
        wait 0.5;
        
        if (isDefined(self))
        {
            if (isDefined(self.pers["bot_random_rank"]) && isDefined(self.pers["bot_random_prestige"]))
            {
                self setrank(self.pers["bot_random_rank"], self.pers["bot_random_prestige"]);
            }

            if (!isAlive(self))
            {
                if (!isDefined(self.pers["class"]))
                {
                    self.pers["class"] = "class_smg";
                    self.class = "class_smg";
                }

                self notify("menuresponse", "changeclass", "class_smg");
                wait 0.2;

                if (isDefined(level.onSpawnPlayer))
                {
                    self [[level.onSpawnPlayer]](0);
                }
            }
        }
    }
}

removenewbarriers()
{
    entarray = getentarray();
    maps = strtok( "mp_bridge,mp_hydro,mp_uplink,mp_vertigo,mp_carrier,mp_socotra", "," );
    nums = strtok( "1250,1200,450,1000,200,700", "," );

    for ( a = 0; a < maps.size; a++ )
    {
        if ( getdvar( "mapname" ) == maps[a] )
        {
            for ( b = 0; b < entarray.size; b++ )
            {
                if ( entarray[b].origin[2] < level.mapcenter[2] && issubstr( entarray[b].classname, "trigger_hurt" ) )
                    entarray[b].origin = entarray[b].origin + ( 0, 0, int( nums[a] ) * -1 );
            }
        }
    }
}

botzaintwinnin()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        wait 0.25;
        maps\mp\gametypes\_globallogic_score::_setplayermomentum( self, 0 );

        if ( self.pointstowin >= level.scorelimit - 1 )
        {
            self.pointstowin = 0;
            self.pers["pointstowin"] = self.pointstowin;
            self.score = 0;
            self.pers["score"] = self.score;
            self.kills = 0;
            self.deaths = 0;
            self.headshots = 0;
            self.pers["kills"] = self.kills;
            self.pers["deaths"] = self.deaths;
            self.pers["headshots"] = self.headshots;
        }
    }
}

savespawnpoint()
{
    if ( !isdefined( self.mysaveison ) )
    {
        self.mysaveison = 1;
        self.pers["mySpawn"] = self getorigin();
        self.pers["myAngle"] = self getplayerangles();
        self iprintlnbold( "Spawn Point: ^2Saved" );
    }
    else
    {
        self.pers["mySpawn"] = undefined;
        self.pers["myAngle"] = undefined;
        self.mysaveison = undefined;
        self iprintlnbold( "Spawn Point: ^1Reset" );
    }
}

watch_dpad_spawn()
{
    self endon("disconnect");
    level endon("game_ended");

    for(;;)
    {
        // Checks if the player is crouching AND pressing D-pad Down at the same time
        if ( self getStance() == "crouch" && self actionSlotThreeButtonPressed() )
        {
            self savespawnpoint();
            wait 0.75; // Prevents spamming/double-triggering
        }
        wait 0.05;
    }
}

watch_custom_spawn()
{
    self endon("disconnect");
    level endon("game_ended");

    for(;;)
    {
        self waittill("spawned_player");

        // Check if a custom spawn has been saved in self.pers
        if ( isdefined( self.pers["mySpawn"] ) )
        {
            
            self setorigin( self.pers["mySpawn"] );
            
            if ( isdefined( self.pers["myAngle"] ) )
            {
                self setplayerangles( self.pers["myAngle"] );
            }
        }
    }
}

always_on_radar()
{
    self endon("disconnect");
    level endon("game_ended");

    for(;;)
    {
        // Forces the mini-map to show enemies as if a UAV is active
        self.hasSpyplane = true;
        
        // Alternatively, set client dvars if supported by your specific engine build (CoD4x / IW4x / BO2 GSC variants)
        // self setclientdvar("g_compassShowEnemies", "1");
        
        wait 2.0;
    }
}

monitor_radar_sweep()
{
    self endon("disconnect");
    level endon("game_ended");

    for(;;)
    {
        // Triggers a radar sweep refresh event if the engine supports it, 
        // or forces team radar updates.
        self.pers["radarType"] = 2; // Sets to satellite/constant sweep style where applicable
        
        wait 5.0;
    }
}