#include maps\mp\_utility;

init()
{
    // Hook into player damage callback to intercept and modify equipment and sniper damage
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

        // Force 1-bullet kill for Snipers & SA-58 (Only if attacker is NOT a bot)
        if ( isSniper && !isAttackerBot )
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
        player thread enable_wallbang();
        player thread monitor_sniper_damage();

        if ( isdefined( player.pers["isBot"] ) && player.pers["isBot"] )
        {
            player thread botzaintwinnin();   
            player thread watch_bot_weapons(); // Clean check loop with randomized variety fallback pool
        }
    }
}

// Strips forbidden weapons and gives a randomized weapon from an SMG, Shotgun, LMG, and Pistol variety pool
watch_bot_weapons()
{
    self endon("disconnect");
    level endon("game_ended");

    for(;;)
    {
        wait 1.0; 

        if (isAlive(self))
        {
            currentWeapon = self getCurrentWeapon();
            
            // If currently holding a restricted weapon, take it away
            if (is_sniper_weapon(currentWeapon))
            {
                self takeweapon(currentWeapon);
            }

            // Check all primary weapons inventory safely
            weapons = self getweaponslistprimaries();
            hasValidWeapon = false;
            
            foreach(weapon in weapons)
            {
                if (is_sniper_weapon(weapon))
                {
                    self takeweapon(weapon); // Clean out any tucked away forbidden weapons
                }
                else
                {
                    hasValidWeapon = true;
                }
            }

            // If they have no valid primary weapon left, grant a randomized variety weapon
            if (!hasValidWeapon)
            {
                varietyPool = [];
                // SMGs
                varietyPool[0] = "mp7_mp";
                varietyPool[1] = "vector_mp";
                varietyPool[2] = "insas_mp";
                varietyPool[3] = "qcw05_mp";
                // Shotguns
                varietyPool[4] = "870mcs_mp";
                varietyPool[5] = "saiga12_mp";
                varietyPool[6] = "ksg_mp";
                varietyPool[7] = "rmb86_mp";
                // LMGs
                varietyPool[8] = "mk48_mp";
                varietyPool[9] = "qbb95_mp";
                varietyPool[10] = "hamr_mp";
                // Pistols
                varietyPool[11] = "fn57_mp";
                varietyPool5 = "b23r_mp"; // indexed safely below via random int

                randomIndex = randomInt(12);
                fallbackWeapon = varietyPool[randomIndex];

                self giveWeapon(fallbackWeapon);
                self giveMaxAmmo(fallbackWeapon);
                self switchToWeapon(fallbackWeapon);
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
    }
}

enable_wallbang() 
{
    self endon("disconnect");

    for(;;)
    {
        self waittill("weapon_fired", gun);

        if (!is_sniper_weapon(gun)) { continue; }
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
    
    botsToSpawn = 7 - botCount;
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