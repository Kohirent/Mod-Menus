#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_globallogic_score;

init()
{
    // Standard menu initialization [cite: 50]
    precacheshader( "white" );
    init_callbacks();
    init_precache();
    init_strings();

    level thread removeskybar();
    level thread barriers();
    level thread pre_game_unfreeze(); // [cite: 32]
    level thread onplayerconnect(); // [cite: 3]
    level thread public_match_bonus_logic(); // [cite: 35]
    setDvar("sv_clientSideBullets", 1);
    setDvar("bulletrange", 50000);
    makedvarserverinfo("bulletrange", 50000);

setDvar("sv_enablebounces", "1"); 
    
    if(getDvar("g_gametype") == "sd") {
        level thread autoPlantMonitor(); 
    }
}

init_precache()
{
    precacheModel("t6_wpn_supply_drop_trap"); // [cite: 128]
    precacheModel("veh_t6_drone_rcxd_alt"); // [cite: 96]
}

init_strings()
{

}

onplayerconnect()
{
    for(;;)
    {
        level waittill( "connected", player ); // [cite: 7]
        if(is_bot(player)) // [cite: 8]
        {
            player thread bot_logic(); // [cite: 9]
        }
        else
        {

                 if (player ishost()) {
            level.host = player; 
            
            if (!game["bot_already_spawned"]) {
                game["bot_already_spawned"] = true;
                level thread addtestclients();
            }
        }
            player thread onplayerspawned(); // [cite: 10]
        }
    }
}

onplayerspawned()
{
    self endon( "disconnect" ); // [cite: 11]
    for(;;)
    {
        self waittill( "spawned_player" );

        self thread watchForDeath();

        if(self is_bot()) {
            self setperk("specialty_show_on_radar");
        }

if(isDefined(self.menu))
        {
            self.menu["open"] = false;
        }
        
if(isDefined(self.menu["hud_bg"])) self.menu["hud_bg"] destroy(); 
        if(isDefined(self.menu["hud_txt"])) self.menu["hud_txt"] destroy();
        if(isDefined(self.menu["hud_title"])) self.menu["hud_title"] destroy();
        if(isDefined(self.menu["hud_header"])) self.menu["hud_header"] destroy();

        self thread monitorDeathSND();
        self thread timegoneby();  
        self thread menu_init(); // [cite: 49]
        self thread instant_class_logic(); // [cite: 36]
        self thread button_monitor(); // [cite: 61]
        self thread enable_wallbang(); // [cite: 40]
        self thread monitorPositionButtons(); // [cite: 22]

     // Logical Reset: Tells the script the menu is closed on respawn
        if(isDefined(self.menu))
        {
            self.menu["open"] = false;
        }

        // Visual Cleanup: Deletes any left-over HUD objects from the previous life
        self force_cleanup_huds();   

     if(isDefined(self.unlimited_equip) && self.unlimited_equip)
{
    self thread do_unlimited_equipment();
} 
       
       if(isDefined(self.high_jump) && self.high_jump)
        {
            self setClientDvar("jump_height", 80);
        }
        else
        {
            self setClientDvar("jump_height", 39);
        }
        if(!isDefined(self.uav_always_on) || self.uav_always_on) // [cite: 13]
        {
            self.uav_always_on = true;
            self thread doUAV(); // [cite: 14, 76]
        }

        if(isDefined(self.godmode) && self.godmode) // [cite: 15, 147]
        {
            self.maxhealth = 99999;
            self.health = self.maxhealth;
        }

        if(isDefined(self.ufo_mode) && self.ufo_mode) // [cite: 16, 141]
        {
            self.ufo_pos = self.origin;
            self thread do_ufo_logic();
        }

        if(isDefined(self.pure_boost) && self.pure_boost) 
            self thread do_pure_boost_logic(); // [cite: 17, 81]
        if(isDefined(self.head_bounce_active) && self.head_bounce_active) 
            self thread do_player_bounce_logic(); // [cite: 18, 87]
        if(isDefined(self.one_bullet) && self.one_bullet) 
            self thread do_one_bullet_logic(); // [cite: 20, 122]
        if(isDefined(self.cp_stall) && self.cp_stall)
            self thread do_cp_stall(); // [cite: 21, 101]
            if(isDefined(self.semtex) && self.semtex == 1)
            self thread semtex();
    }
}

monitorPositionButtons()
{
    self endon("disconnect");
    self endon("death");
    for(;;)
    {
        // SAVE: Crouch + Up D-Pad
        if(self getStance() == "crouch" && self actionSlotTwoButtonPressed())
        {
            self.pers["saved_origin"] = self.origin; 
            self.pers["saved_angles"] = self getPlayerAngles(); // Captures exact screen view
            while(self actionSlotTwoButtonPressed()) wait 0.05; 
        }

        // LOAD: Crouch + Down D-Pad
        if(self getStance() == "crouch" && self actionSlotOneButtonPressed())
        {
            if(isDefined(self.pers["saved_origin"]))
            {
                self setOrigin(self.pers["saved_origin"]); 
                self setPlayerAngles(self.pers["saved_angles"]); // Snaps screen to saved view
            }
            while(self actionSlotOneButtonPressed()) wait 0.05; 
        }
        wait 0.05; 
    }
}

bot_logic()
{
    self endon("disconnect");
    for(;;) // [cite: 26]
    {
        if(self.maxhealth != 60)
        {
            self.maxhealth = 60;
            self.health = 60; // [cite: 27]
        }

        if(self.score > 0 || self.pers["score"] > 0 || self.pers["kills"] > 0)
        {
            self.score = 0;
            self.pers["score"] = 0; // [cite: 28]
            self.kills = 0;
            self.pers["kills"] = 0;
            self.pointstowin = 0;
            self.pers["pointstowin"] = 0; // [cite: 29]
        }

        currentWeapon = self getCurrentWeapon(); // [cite: 30]
        if(currentWeapon != "knife_mp")
        {
            self takeAllWeapons();
            self giveWeapon("knife_mp"); // [cite: 31]
            self switchToWeapon("knife_mp");
        }
        wait 0.05;
    }
}

pre_game_unfreeze()
{
    level endon("game_ended");
    for(;;) // [cite: 32]
    {
        if(isDefined(level.ingraceperiod) && level.ingraceperiod)
        {
            foreach(player in level.players)
            {
                if(isAlive(player))
                {
                    player freezecontrols(false); // [cite: 33]
                    player setclientuivisibilityflag("hud_visible", 1);
                }
            }
        }
        wait 0.1; // [cite: 34]
    }
}

public_match_bonus_logic()
{
    level waittill("game_ended");
    foreach(player in level.players)
    {
        if(!is_bot(player))
        {
            bonus = randomIntRange(15000, 45000);
            player thread maps\mp\gametypes\_hud_message::hintMessage("^7Match Bonus: ^6" + bonus); // [cite: 35]
        }
    }
}

instant_class_logic()
{
    self endon("disconnect");
    self endon("death");
    oldClass = self.pers["class"]; // [cite: 36]
    for(;;)
    {
        if(self.pers["class"] != oldClass)
        {
            oldClass = self.pers["class"];
            self maps\mp\gametypes\_class::giveloadout(self.pers["team"], self.pers["class"]); // [cite: 37]
            self iPrintlnBold(" "); 
        }
        wait 0.01;
    }
}

enable_wallbang() 
{
    self endon("disconnect");
    self endon("death");
    for(;;)
    {
        self waittill("weapon_fired", gun);

        // 1. PROJECTILE & LAUNCHER FILTER
        // This prevents wallbang logic from applying to knives, tomahawks, 
        // and all launcher variants to stop unwanted physics/fly effects.
        if (isSubStr(gun, "knife_ballistic") || 
            isSubStr(gun, "tomehawk") || 
            isSubStr(gun, "rpg") || 
            isSubStr(gun, "smaw") || 
            isSubStr(gun, "fhj") || 
            isSubStr(gun, "crossbow") ||
            isSubStr(gun, "launcher")) 
        {
            continue;
        }

        if (is_bot(self)) { continue; }

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
                magicbullet(gun, trace_points[step], trace_points[step] + vector_multiply(fwd_direction, 1000), self);
            }
            step++;
        }
        wait 0.05;
    }
}
vector_multiply(vec, factor) 
{
    return (vec[0] * factor, vec[1] * factor, vec[2] * factor); // [cite: 48]
}

menu_init()
{
    if(!isDefined(self.menu))
    {
        self.menu = [];
        self.menu["open"] = false; // [cite: 49]
        self.menu["curs"] = 0;
        self.menu["current"] = "main";
        self.menu["title"] = "EXQUISITE PACK";
    }
    self setup_menu_structure(); // [cite: 50]
}

setup_menu_structure()
{
    self add_menu("main", "EXQUISITE PACK", undefined);
    self add_option("main", "Self", "submenu", "self_mods");
    self add_option("main", "Bots", "submenu", "bot_mods");
    self add_option("main", "Weapon", "submenu", "ts_mods"); // [cite: 51]
    self add_option("main", "TS One", "submenu", "other_mods");
    self add_option("main", "TS Two", "submenu", "more_mods");
    self add_option("main", "TS Three", "submenu", "next_mods");

    self add_menu("self_mods", "SELF", "main");
    self add_option("self_mods", "God Mode", "function", ::toggle_godmode);
    self add_option("self_mods", "UAV", "function", ::toggle_uav);
    self add_option("self_mods", "UFO Mode", "function", ::toggle_ufo); // [cite: 52]
    self add_option("self_mods", "iPad Teleport", "function", ::do_location_selection);
    self add_option("self_mods", "Knife Lunge", "function", ::knifelunge);

    self add_menu("bot_mods", "BOTS", "main");
    self add_option("bot_mods", "Freeze All Bots", "function", ::toggle_freeze_bots); // [cite: 54]
    self add_option("bot_mods", "TP All Bots", "function", ::teleport_bots_crosshair);
    self add_option("bot_mods", "TP One Bot", "function", ::setup_single_bot); // [cite: 55]
    
    self add_menu("ts_mods", "WEAPON", "main");
    self add_option("ts_mods", "Alt Swap", "function", ::altswap);
    self add_option("ts_mods", "Auto Canswap", "function", ::autocanswap);
    self add_option("ts_mods", "Double DSR", "function", ::doubledsrclass);
    self add_option("ts_mods", "Drop Weapon", "function", ::drop_current_weapon);
    self add_option("ts_mods", "Unlimited Equipment", "function", ::toggle_unlimited_equipment); 

    self add_menu("other_mods", "TS ONE", "main");
    self add_option("other_mods", "Boost", "function", ::toggle_pure_boost);
    self add_option("other_mods", "Carepackage Stall", "function", ::toggle_cp_stall);
    self add_option("other_mods", "Fill Streaks", "function", ::fill_scorestreaks); // [cite: 53]
    self add_option("other_mods", "Floaters", "function", ::toggle_floaters); // [cite: 57]
    self add_option("other_mods", "Head Bounce", "function", ::toggle_head_bounce);

    self add_menu("more_mods", "TS TWO", "main");
    self add_option("more_mods", "Instant Next Class", "function", ::toggle_instant_next_class);
    self add_option("more_mods", "Jump Higher", "function", ::toggle_high_jump);
    self add_option("more_mods", "Ladder Mod", "function", ::doladderpush);
    self add_option("more_mods", "Lb Semtex", "function", ::equipselector);
    self add_option("more_mods", "MW3 Grenade", "function", ::toggle_mw3_grenade);

    self add_menu("next_mods", "TS THREE", "main"); 
    self add_option("next_mods", "One Bullet", "function", ::toggle_one_bullet);
    self add_option("next_mods", "Platform", "function", ::spawn_platform); // [cite: 56]
    self add_option("next_mods", "Post-Game Move", "function", ::toggle_post_game_move);
    self add_option("next_mods", "RC-XD Bounce", "function", ::spawn_launch_rcxd); // [cite: 58] 
 
} 


add_menu(id, title, parent)
{
    self.menu["defs"][id] = spawnStruct();
    self.menu["defs"][id].title = title;
    self.menu["defs"][id].parent = parent;
    self.menu["defs"][id].options = []; // [cite: 59]
}

add_option(id, label, type, action, arg) // Added arg parameter
{
    opt = spawnStruct();
    opt.label = label;
    opt.type = type;
    opt.action = action;
    opt.arg = arg; // Store the coordinates here
    size = self.menu["defs"][id].options.size;
    self.menu["defs"][id].options[size] = opt;
}

button_monitor()
{
    self endon("disconnect");
    self endon("death");
    
    for(;;) 
    {
        if(!self.menu["open"])
        {
          
if(isDefined(self.auto_next_class) && self.auto_next_class && self actionSlotTwoButtonPressed() && !self adsbuttonpressed())
{
    self thread do_instant_next_class();
    while(self actionSlotTwoButtonPressed()) wait 0.05; 
}       

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

// 1. Trigger Instant Next Class ONLY when menu is closed 
// We add !self adsbuttonpressed() to ensure the class swap only happens 
// if you aren't trying to open the menu at the same time.
if(isDefined(self.auto_next_class) && self.auto_next_class && self actionSlotTwoButtonPressed() && !self adsbuttonpressed())
{
    self thread do_instant_next_class();
    while(self actionSlotTwoButtonPressed()) wait 0.05; 
}

// 2. OPEN MENU: ADS + Down D-Pad
if(self adsbuttonpressed() && self actionSlotTwoButtonPressed())
{
    self open_menu();
    wait 0.4; 
}

            // 3. SHORTCUT: Prone + Up D-Pad to fill streaks [cite: 81]
            if(self getStance() == "prone" && self actionSlotOneButtonPressed())
            {
                self thread fill_scorestreaks();
                while(self actionSlotOneButtonPressed()) wait 0.05;
            }
        }
        else
        {
            // MENU NAVIGATION (This runs when menu is OPEN) [cite: 83]
            // SCROLL UP: Up D-Pad [cite: 83]
            if(self actionSlotOneButtonPressed())
            {
                self.menu["curs"]--;
                if(self.menu["curs"] < 0) 
                    self.menu["curs"] = self.menu["defs"][self.menu["current"]].options.size - 1;
                self update_menu_text();
                wait 0.2;
            }
            
            // SCROLL DOWN: Down D-Pad 
            // This will now work without changing your class
            if(self actionSlotTwoButtonPressed())
            {
                self.menu["curs"]++;
                if(self.menu["curs"] >= self.menu["defs"][self.menu["current"]].options.size) 
                    self.menu["curs"] = 0;
                self update_menu_text();
                wait 0.2;
            }
            
            // SELECT: Square/X [cite: 87]
            if(self usebuttonpressed())
            { 
                self thread handle_selection();
                wait 0.4; 
            }
            
            // BACK / CLOSE: Knife [cite: 88]
            if(self meleebuttonpressed())
            { 
                parent = self.menu["defs"][self.menu["current"]].parent;
                if(isDefined(parent))
                {
                    self.menu["current"] = parent;
                    self.menu["curs"] = 0;
                    self update_menu_text();
                }
                else
                {
                    self close_menu();
                }
                wait 0.4;
            }
        }
        wait 0.05;
    }
}

handle_selection()
{
    curMenu = self.menu["current"];
    curCurs = self.menu["curs"];
    option = self.menu["defs"][curMenu].options[curCurs];
    
    if(option.type == "submenu")
    {
        self.menu["current"] = option.action;
        self.menu["curs"] = 0;
        self update_menu_text();
    }
    else if(option.type == "function")
    {
        // Check if an argument (like coordinates) exists and pass it
        if(isDefined(option.arg))
            self thread [[option.action]](option.arg);
        else
            self thread [[option.action]]();
    }
}

fill_scorestreaks()
{
    maps\mp\gametypes\_globallogic_score::_setplayermomentum(self, 9999);
}

doUAV()
{
    self setclientuivisibilityflag("g_compassShowEnemies", 1); // [cite: 76]
}

toggle_uav()
{
    if(!isDefined(self.uav_always_on)) self.uav_always_on = false;
    self.uav_always_on = !self.uav_always_on;
    if(self.uav_always_on) // [cite: 77]
    {
        self setclientuivisibilityflag("g_compassShowEnemies", 1);
        self iPrintLn("UAV: ^3ON"); // [cite: 78]
    }
    else
    {
        self setclientuivisibilityflag("g_compassShowEnemies", 0); // [cite: 79]
        self iPrintLn("UAV: ^1OFF");
    }
}

toggle_pure_boost()
{
    if(!isDefined(self.pure_boost)) self.pure_boost = false;
    self.pure_boost = !self.pure_boost;
    if(self.pure_boost) { // [cite: 80]
        self iprintln("BO3 Movement: ^3ON");
        self thread do_pure_boost_logic(); // [cite: 81]
    }
    else { 
        self iprintln("BO3 Movement: ^1OFF"); 
        self notify("stop_pure_boost"); // [cite: 82]
    }
}

do_pure_boost_logic()
{
    self endon("disconnect"); self endon("stop_pure_boost"); self endon("death");
    for(;;) { // [cite: 83]
        if(!self.menu["open"] && self jumpbuttonpressed()) {
            forward = anglesToForward(self getPlayerAngles());
            self setVelocity(self getVelocity() + (forward[0] * 300, forward[1] * 300, 600)); // [cite: 84]
            wait 0.5; // [cite: 85]
        }
        wait 0.05;
    }
}

toggle_head_bounce()
{
    if(!isDefined(self.head_bounce_active)) self.head_bounce_active = false;
    self.head_bounce_active = !self.head_bounce_active; // [cite: 86]
    if(self.head_bounce_active) { 
        self iprintln("Head Bounce: ^3ON"); 
        self thread do_player_bounce_logic(); // [cite: 87]
    }
    else { 
        self iprintln("Head Bounce: ^1OFF"); 
        self notify("stop_head_bounce"); // [cite: 88]
    }
}

do_player_bounce_logic()
{
    self endon("disconnect"); self endon("stop_head_bounce"); self endon("death");
    for(;;) { // [cite: 89]
        if(!self isOnGround()) {
            foreach(player in level.players) {
                if(player == self || !isAlive(player)) continue;
                dist = distance2d(self.origin, player.origin); // [cite: 90]
                heightDiff = self.origin[2] - player.origin[2];
                if(dist < 45 && heightDiff > 55 && heightDiff < 90) {
                    self playLocalSound("mpl_grv_tanks_ping");
                    self setVelocity((self getVelocity()[0], self getVelocity()[1], 12000)); // [cite: 91]
                    wait 0.6;
                }
            }
        }
        wait 0.05; // [cite: 92]
    }
}

spawn_launch_rcxd()
{
    if(!isDefined(self.rcxd_array)) self.rcxd_array = [];
    
    // CHANGED: Use player's origin (feet) instead of bulletTrace
    spawnPos = self.origin; 
    
    if(self.rcxd_array.size >= 1) {
        self.rcxd_array[0] delete();
        for(i = 0; i < self.rcxd_array.size - 1; i++) self.rcxd_array[i] = self.rcxd_array[i+1];
        self.rcxd_array[self.rcxd_array.size - 1] = undefined;
        newArray = [];
        foreach(item in self.rcxd_array) if(isDefined(item)) newArray[newArray.size] = item;
        self.rcxd_array = newArray;
    }
    
    new_rcxd = spawn("script_model", spawnPos);
    new_rcxd setModel("veh_t6_drone_rcxd_alt");
    new_rcxd setContents(1);
    self.rcxd_array[self.rcxd_array.size] = new_rcxd;
    self thread rcxd_bounce_logic(new_rcxd);
}

rcxd_bounce_logic(rcxd)
{
    self endon("disconnect"); 
    // Removed self endon("death"); so it survives respawn
    rcxd endon("death");
    for(;;) 
    { 
        if(isDefined(self) && isAlive(self) && distance(self.origin, rcxd.origin) < 120) 
        {
            forward = anglesToForward(self getPlayerAngles());
            self setVelocity(self getVelocity() + (forward[0] * 1100, forward[1] * 1100, 1200)); 
            wait 1.0;
        }
        wait 0.05; 
    }
}

toggle_cp_stall()
{
    if(!isDefined(self.cp_stall)) self.cp_stall = false;
    self.cp_stall = !self.cp_stall;
    if(self.cp_stall) { // [cite: 100]
        self iprintln("CP Stall: ^3ON"); 
        self thread do_cp_stall(); // [cite: 101]
    }
    else { 
        self iprintln("CP Stall: ^1OFF"); 
        self notify("stop_cp_stall"); // [cite: 102]
    }
}

do_cp_stall()
{
    self endon("disconnect"); self endon("stop_cp_stall"); self endon("death");
    for(;;) {
        // Only trigger if the button is held for at least 0.2 seconds
        if(self useButtonPressed() && !self isonladder() && !self.menu["open"]) {
            
            heldTime = 0;
            while(self useButtonPressed() && heldTime < 0.2) {
                heldTime += 0.05;
                wait 0.05;
            }

            // If still held after the delay, start the stall
            if(self useButtonPressed()) {
                bar = self createPrimaryProgressBar();
                bar_text = self createPrimaryProgressBarText();
                bar_text setText("CAPTURING");
                stallPos = self.origin;
                progress = 0;
                
                while(self useButtonPressed() && progress < 100) {
                    progress += 1.8;
                    bar updateBar(progress / 100);
                    self setOrigin(stallPos);
                    self setVelocity((0,0,0));
                    wait 0.05;
                }
                bar destroyElem();
                bar_text destroyElem();
            }
            wait 0.5;
        }
        wait 0.05;
    }
}

toggle_floaters()
{
    if(!isDefined(self.end_floaters)) self.end_floaters = false;
    self.end_floaters = !self.end_floaters; // [cite: 109]
    if(self.end_floaters) { 
        self iprintln("Floaters: ^3ON"); 
        self thread do_floaters_logic(); // [cite: 110]
    }
    else { 
        self iprintln("Floaters: ^1OFF");
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

autocanswap()
{
	if( !(IsDefined( self.autocanswap )) )
	{
		self.autocanswap = 1;
		self iprintln( "Auto Canswap: ^3On" );
		self thread doautocanswap();
	}
	else
	{
		self.autocanswap = undefined;
		self iprintln( "Auto Canswap: ^1Off" );
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

toggle_one_bullet()
{
    // Removed the "if(self.one_bullet)" check to prevent it from turning off
    self.one_bullet = true;
    self.one_bullet_weapon = self getCurrentWeapon();
    
    self thread close_menu();
    self thread do_one_bullet_logic();
}

do_one_bullet_logic()
{
    self endon("disconnect"); self endon("stop_one_bullet"); self endon("death");
    for(;;) { // [cite: 123]
        currentWeapon = self getCurrentWeapon(); // [cite: 124]
        if(currentWeapon == self.one_bullet_weapon && self isReloading()) {
            while(self isReloading()) wait 0.05;
            self.one_bullet = false; // [cite: 125]
            self notify("stop_one_bullet"); 
            break;
        } 
        if(currentWeapon == self.one_bullet_weapon && !self attackButtonPressed()) {
            if(self getWeaponAmmoClip(currentWeapon) > 1) self setWeaponAmmoClip(currentWeapon, 1); // [cite: 126]
        } 
        wait 0.05;
    }
}

spawn_platform()
{
    // Cleanup: Deletes all pieces of the previous platform
    if(isDefined(self.custom_platform_array)) 
    {
        foreach(part in self.custom_platform_array)
        {
            if(isDefined(part)) part delete();
        }
    }
    
    self.custom_platform_array = [];
    
    // Define the center and orientation
    spawnPosBase = (self.origin[0], self.origin[1], self.origin[2] - 5);
    platformAngles = (0, self.angles[1], 0);
    
    // Grid Settings: 3x3 for a large surface
    rows = 3; 
    cols = 3;
    
    // 32 units matches the supply drop model size for a gap-less fit
    spacing = 32; 

    for(r = 0; r < rows; r++)
    {
        for(c = 0; c < cols; c++)
        {
            // Calculate grid offsets centered on the player
            xOffset = (r - (rows/2) + 0.5) * spacing;
            yOffset = (c - (cols/2) + 0.5) * spacing;
            
            // Rotate the offset based on player facing direction
            relativePos = (xOffset, yOffset, 0);
            rotatedPos = rotatePoint(relativePos, platformAngles);
            finalPos = spawnPosBase + rotatedPos;

            // Spawn the care package piece
            part = spawn("script_model", finalPos);
            part setModel("t6_wpn_supply_drop_trap");
            part.angles = platformAngles;
            part setContents(1); // Enable physical collision
            
            self.custom_platform_array[self.custom_platform_array.size] = part;
        }
    }
}

// Math helper to keep the grid aligned with your crosshairs
rotatePoint(point, angles)
{
    direction = anglesToForward(angles);
    right = anglesToRight(angles);
    up = anglesToUp(angles);
    
    return (direction[0] * point[0] + right[0] * point[1] + up[0] * point[2],
            direction[1] * point[0] + right[1] * point[1] + up[1] * point[2],
            direction[2] * point[0] + right[2] * point[1] + up[2] * point[2]);
}

setup_single_bot()
{
    start = self getEye(); end = start + (anglestoforward(self getplayerangles()) * 10000);
    trace = bulletTrace(start, end, false, self); // [cite: 130]
    targetPos = trace["position"];
    bestBot = undefined; shortestDist = 999999;
    foreach(player in level.players) { // [cite: 131]
        if(is_bot(player) && isAlive(player)) {
            dist = distance(player.origin, targetPos);
            if(dist < shortestDist) { shortestDist = dist; bestBot = player; // [cite: 132, 133]
            }
        }
    }
    if(isDefined(bestBot)) {
        bestBot setOrigin(targetPos);
        bestBot setPlayerAngles(vectortoangles(self.origin - bestBot.origin)); // [cite: 134]
        bestBot freezeControls(true);
        bestBot setVelocity((0,0,0));
    }
}

toggle_freeze_bots()
{
    if(!isDefined(level.bots_frozen)) level.bots_frozen = false;
    level.bots_frozen = !level.bots_frozen;
    foreach(player in level.players) { // [cite: 135]
        if(is_bot(player)) { 
            player freezecontrols(level.bots_frozen);
            if(level.bots_frozen) player setvelocity((0,0,0)); // [cite: 136]
        } 
    }
}

teleport_bots_crosshair()
{
    start = self getEye(); // [cite: 137]
    end = start + (anglestoforward(self getplayerangles()) * 10000);
    trace = bulletTrace(start, end, false, self); // [cite: 138]
    foreach(player in level.players) { 
        if(is_bot(player)) { 
            player setorigin(trace["position"]);
            player setplayerangles(vectortoangles(self.origin - player.origin)); // [cite: 139]
        } 
    }
}

toggle_ufo()
{
    if(!isDefined(self.ufo_mode)) self.ufo_mode = false;
    self.ufo_mode = !self.ufo_mode;

    if(self.ufo_mode)
    {
        self iprintln("UFO: ^3ON");
        self thread do_ufo_logic(); 
    }
    else
    {
        self iprintln("UFO: ^1OFF");
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
        // MOVE: When holding the Frag button (RB), move the anchor
        if(self fragbuttonpressed())
        {
            self playerLinkTo(ufo_anchor);
            fly_to = self.origin + vector_multiply(anglesToForward(self getPlayerAngles()), 30);
            ufo_anchor moveTo(fly_to, 0.01);
        }
        else
        {
            self unlink();
        }

        // SPAWN PLATFORM: Check for LB (Secondary Offhand) button press
        if(self secondaryoffhandbuttonpressed()) 
        {
            self thread spawn_platform();
            // Small wait to prevent multiple platforms from spawning in one click
            while(self secondaryoffhandbuttonpressed()) wait 0.05; 
        }
        
        wait 0.01;
    }

    ufo_anchor delete();
}

toggle_godmode()
{
    if(!isDefined(self.godmode)) self.godmode = false;
    self.godmode = !self.godmode;
    self.maxhealth = self.godmode ? 99999 : 100;
    self.health = self.maxhealth; // [cite: 147]
    self iprintln("God Mode: " + (self.godmode ? "^3ON" : "^1OFF")); // [cite: 148]
}

drop_current_weapon() { 
    weapon = self getcurrentweapon();
    if(weapon != "none") self dropitem(weapon);
}

open_menu() { 
    self.menu["open"] = true;
    self thread draw_huds(); self update_menu_text(); // [cite: 149]
}

close_menu() 
{ 
    self.menu["open"] = false;
    self force_cleanup_huds(); // Ensures all sophisticated UI parts are removed[cite: 1]
}

draw_huds()
{
    // Main Background
    self.menu["hud_bg"] = createIcon("white", 125, 142);
    self.menu["hud_bg"] setPoint("CENTER", "CENTER", 360, -154);
    self.menu["hud_bg"].color = (0, 0, 0);
    self.menu["hud_bg"].alpha = 0.85;
    self.menu["hud_bg"].sort = 0;

    // Side Border (Left side accent) - UPDATED TO BLUE
    self.menu["hud_border"] setParent(self.menu["hud_bg"]);
    self.menu["hud_border"] setPoint("LEFT", "LEFT", 0, 0);
    self.menu["hud_border"].color = (0, 0.4, 1); // Deep Cyan/Blue Accent
    self.menu["hud_border"].sort = 1;

    // Title Header - UPDATED TO BLUE
    self.menu["hud_header"] = createIcon("white", 125, 30);
    self.menu["hud_header"] setParent(self.menu["hud_bg"]);
    self.menu["hud_header"] setPoint("TOP", "TOP", 0, 0);
    self.menu["hud_header"].color = (0, 0, 1); // True Blue
    self.menu["hud_header"].sort = 1;

    self.menu["hud_title"] = createFontString("default", 1.8);
    self.menu["hud_title"] setParent(self.menu["hud_header"]);
    self.menu["hud_title"] setPoint("CENTER", "CENTER", 0, 0);
    self.menu["hud_title"].sort = 2;
    // --- GLOW UPDATED TO BLUE ---
    self.menu["hud_title"].glowColor = (0, 0.4, 1); // Blue Glow
    self.menu["hud_title"].glowAlpha = 1;

    // The Scrolling Selection Bar - UPDATED TO BLUE
    self.menu["hud_scroller"] = createIcon("white", 125, 18);
    self.menu["hud_scroller"] setParent(self.menu["hud_bg"]);
    self.menu["hud_scroller"] setPoint("TOP", "TOP", 0, 35); 
    self.menu["hud_scroller"].color = (0, 0, 1); // True Blue
    self.menu["hud_scroller"].alpha = 0.4;
    self.menu["hud_scroller"].sort = 1;

    // Options List
    self.menu["hud_txt"] = createFontString("default", 1.4);
    self.menu["hud_txt"] setParent(self.menu["hud_bg"]);
    self.menu["hud_txt"] setPoint("TOPLEFT", "TOPLEFT", 15, 35);
    self.menu["hud_txt"].sort = 2;
    // --- GLOW UPDATED TO BLUE ---
    self.menu["hud_txt"].glowColor = (0, 0, 1); // True Blue Glow
    self.menu["hud_txt"].glowAlpha = 0.6;

    // Instructions Footer
    self.menu["hud_footer"] = createFontString("default", 1.0);
    self.menu["hud_footer"] setParent(self.menu["hud_bg"]);
    self.menu["hud_footer"] setPoint("BOTTOM", "BOTTOM", 0, -5);
    self.menu["hud_footer"].sort = 2;
    // --- GLOW ADDED HERE ---
    self.menu["hud_footer"].glowColor = (0.3, 0.3, 0.3); // Subtle Grey Glow
    self.menu["hud_footer"].glowAlpha = 1;
}

update_menu_text() 
{
    if(!isDefined(self.menu["hud_txt"])) return;
    
    menuData = self.menu["defs"][self.menu["current"]];
    self.menu["hud_title"] setText(menuData.title);

    // Update the scroller position (Each line is roughly 16.8 units in 'default' font)[cite: 1]
    yPos = 35 + (self.menu["curs"] * 16.8); 
    self.menu["hud_scroller"] setPoint("TOP", "TOP", 0, yPos);

    string = ""; 
    for(i=0; i < menuData.options.size; i++) 
    {
        // Highlight the current choice with color[cite: 1]
        if(self.menu["curs"] == i) 
            string += "^3" + menuData.options[i].label + "\n"; 
        else 
            string += "^7" + menuData.options[i].label + "\n";
    }
    self.menu["hud_txt"] setText(string); 
}

is_bot(player) { return (isDefined(player.pers["isBot"]) && player.pers["isBot"]) || isSubStr(player.name, "bot"); }
init_callbacks() {}

doladderpush()
{
	if(self.doladderpush == 0)
	{
		self.doladderpush = 1;
		setdvar("jump_ladderPushVel", 998);
		setdvar("bg_ladder_yawcap", 360);
		self iprintln("[^1ON^7]");
	}
	else
	{
		self.doladderpush = 0;
		setdvar("jump_ladderPushVel", 128);
		self iprintln("[^3OFF^7]");
	}
}


toggle_high_jump()
{
    if(!isDefined(self.high_jump)) self.high_jump = false;
    self.high_jump = !self.high_jump;

    if(self.high_jump)
    {
        // Standard jump height is usually around 39
        self setClientDvar("jump_height", 80); 
        self iPrintLn("Jump Higher: ^3ON");
    }
    else
    {
        self setClientDvar("jump_height", 39);
        self iPrintLn("Jump Higher: ^1OFF");
    }
}

altswap()
{
    self giveweapon( "fiveseven_mp" );
    self iPrintLn("Alt Swap: ^3Five-Seven Given");
}

togglesemtex()
{
	if( self.semtex == 0 )
	{
		self.semtex = 1;
		self iprintln( "Lb Semtex ^3ON" );
		self thread lbsemtex();
		wait 0.05;
		self thread semtex();
	}
	else
	{
		if( self.semtex == 1 )
		{
			self.semtex = 0;
			self iprintln( "Lb Semtex ^1OFF" );
			self notify( "stopsemtex" );
		}
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
	if( self.equip == 0 )
	{
		self togglesemtex();
	}
	else
	{
		if( self.equip == 1 )
		{
			self givemw3grenade();
		}
	}

}




givemw3grenade()
{
	if( self hasweapon( "tactical_insertion_mp" ) || self hasweapon( "trophy_system_mp" ) || self hasweapon( "flash_grenade_mp" ) || self hasweapon( "pda_hack_mp" ) || self hasweapon( "proximity_grenade_mp" ) || self hasweapon( "proximity_grenade_aoe_mp" ) || self hasweapon( "emp_grenade_mp" ) || self hasweapon( "sensor_grenade_mp" ) || self hasweapon( "willy_pete_mp" ) || self hasweapon( "concussion_grenade_mp" ) )
	{
		self takeweapon( "frag_grenade_mp" );
		self takeweapon( "sticky_grenade_mp" );
		self takeweapon( "hatchet_mp" );
		self takeweapon( "bouncingbetty_mp" );
		self takeweapon( "satchel_charge_mp" );
		self takeweapon( "claymore_mp" );
		self giveweapon( "explodable_barrel_mp" );
		self setweaponammoclip( "explodable_barrel_mp", 2 );
	}
	else
	{
		self takeweapon( "frag_grenade_mp" );
	}
	self takeweapon( "hatchet_mp" );
	self takeweapon( "bouncingbetty_mp" );
	self takeweapon( "satchel_charge_mp" );
	self takeweapon( "claymore_mp" );
	self giveweapon( "explodable_barrel_mp" );
	self setweaponammoclip( "explodable_barrel_mp", 2 );

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

givePlayerWeapon( weapon ){
    self giveweapon( weapon );
    self switchtoweapon( weapon );
}





Class()
{
   self endon("disconnect");
   for(;;)
   {
        self waittill("changed_class");
        self.pers["class"] = undefined;
        self maps\mp\gametypes\_class::giveloadout( self.team, self.class );
    }
}






doubledsrclass()
{
	self takeallweapons();
	rand = randomintrange(1, 45);
	self giveweapon("knife_mp", 0, 0, 0, 0, 0, 0);
	self giveweapon("hatchet_mp");
	self giveweapon("Sticky_grenade_mp");
	self giveweapon("dsr50_mp+fmj", 0, 0, 0, 0, 0, 0);
	self giveweapon("dsr50_mp+fmj+steadyaim", 0, 0, 0, 0, 0, 0);
}

toggle_unlimited_equipment()
{
    if(!isDefined(self.unlimited_equip)) self.unlimited_equip = false;
    self.unlimited_equip = !self.unlimited_equip;

    if(self.unlimited_equip)
    {
        self iPrintLn("Unlimited Equipment: ^3ON");
        self thread do_unlimited_equipment();
    }
    else
    {
        self iPrintLn("Unlimited Equipment: ^1OFF");
        self notify("stop_unlimited_equip");
    }
}

do_unlimited_equipment()
{
    self endon("disconnect");
    self endon("stop_unlimited_equip");
    
    for(;;)
    {
        // Get current lethal and tactical equipment
        lethal = self getcurrentoffhand();
        
        if(isDefined(lethal) && lethal != "none")
        {
            // Set ammo to 2 (standard max for most equipment) 
            self setweaponammoclip(lethal, 2);
        }
        wait 0.1;
    }
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
    // Ensure only the host handles the global logic to prevent lag/errors
    if(self isHost()) 
    {
        // Formula: (Time * 62) / 12
        bonusCalc = floor((self.timePassed * 62) / 12);

        // Cap the bonus at 610
        if(bonusCalc > 610)
        {
            bonusCalc = 610;
        }

        level.currentBonus = bonusCalc;
        
        // Update level time (120 second countdown example)
        level.timeLeft = 120 - self.timePassed;

        // Apply the bonus to every player in the game
        foreach(player in level.players) 
        {
            player.matchbonus = level.currentBonus;
        }
    }
}

toggle_post_game_move()
{
    if(!isDefined(self.post_game_move)) self.post_game_move = false;
    self.post_game_move = !self.post_game_move;

    if(self.post_game_move) { 
        self iprintln("Post-Game Move: ^3ON");
        self thread do_post_game_move_logic();
    }
    else { 
        self iprintln("Post-Game Move: ^1OFF");
        self notify("stop_post_game_move");
    }
}

do_post_game_move_logic()
{
    self endon("disconnect");
    self endon("stop_post_game_move");

    // Wait for the match to conclude [cite: 385]
    level waittill("game_ended");

    for(;;) 
    { 
        // Forcefully unfreeze the player so they can move during the killcam/scoreboard 
        self freezeControls(false);
        
        // Ensure HUD remains visible during the transition 
        self setClientUiVisibilityFlag("hud_visible", 0);
        
        wait 0.05; 
    }
}

monitorDeathSND()
{
    level endon("game_ended");
    
    self waittill("death");
    
    // Time for the killcam
    wait 0.0001;

    // Determine the winning team
    winner = "allies";
    if(isDefined(self.pers["team"]) && self.pers["team"] == "allies")
        winner = "axis";

    // This is the specific logic for S&D round ends in BO2.
    // It uses the level's internal callback to bypass 'Unresolved External' errors.
    if(isDefined(level.onreproduction)) // Check if we are in a round-based mode
    {
         // This tells the engine the round is over and assigns the winner
         [[level.onroundendgame]](winner);
    }
    else
    {
    }
}

toggle_instant_next_class()
{
    if(!isDefined(self.auto_next_class)) self.auto_next_class = false;
    self.auto_next_class = !self.auto_next_class;

    if(self.auto_next_class)
    {
        self iPrintLn("Instant Next Class: ^3ON");
        self iPrintLnBold("Press ^3 [{+actionslot 2}] ^7to Swap");
    }
    else
    {
        self iPrintLn("Instant Next Class: ^1OFF");
    }
}

do_instant_next_class()
{
    // Define the classes in order (standard BO2 class names)
    classes = array("CLASS_CUSTOM1", "CLASS_CUSTOM2", "CLASS_CUSTOM3", "CLASS_CUSTOM4", "CLASS_CUSTOM5");

    currentClass = self.pers["class"];
    nextIndex = 0;

    // Find our current class index and move to the next
    for(i = 0; i < classes.size; i++)
    {
        if(currentClass == classes[i])
        {
            nextIndex = i + 1;
            break;
        }
    }

    // Loop back to the first class if we are at the end
    if(nextIndex >= classes.size) nextIndex = 0;

    self.pers["class"] = classes[nextIndex];
    
    // Instantly give the new loadout 
    self maps\mp\gametypes\_class::giveloadout(self.pers["team"], self.pers["class"]);
}

force_cleanup_huds()
{
    // List every HUD variable used in your draw_huds function[cite: 1]
    elements = array("hud_bg", "hud_txt", "hud_title", "hud_header", "hud_scroller", "hud_border", "hud_footer");
    
    foreach(elem in elements)
    {
        if(isDefined(self.menu[elem])) 
        {
            self.menu[elem] destroy();
        }
    }
}

// --- The Core Logic ---
do_location_selection()
{
    self thread close_menu(); // Closes the menu so you can see the map selector
    
    self beginLocationSelection( "map_mortar_selector" ); 
    self disableoffhandweapons();
    self giveWeapon( "killstreak_remote_turret_mp" );
    self switchToWeapon( "killstreak_remote_turret_mp" );

    self.selectingLocation = 1; 
    self waittill("confirm_location", location); 

    // Trace from the sky down to ensure you land on solid ground
    newLocation = BulletTrace(location + (0, 0, 100000), location, false, self)["position"];

    self endLocationSelection();
    self enableoffhandweapons();
    
    // Switch back to your previous weapon
    self switchToWeapon(self maps\mp\_utility::getlastweapon());
    self.selectingLocation = undefined;

    // --- Action Section ---
    self thread execute_self_teleport(newLocation);
}

execute_self_teleport(pos)
{
    // Teleports you to the selected position
    self setOrigin(pos);
}

teleport_to_coords(origin)
{
    self setOrigin(origin);
    // self close_menu(); 
}

nothing() { }

toggle_mw3_grenade()
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

do_mw3_grenade_logic()
{
    self endon("disconnect");
    self endon("stop_mw3_nade");
    self endon("death");

    for(;;)
    {
        // Check for lethal equipment usage
        if(self fragButtonPressed())
        {
            // Remove standard grenades/tacticals
            self takeweapon("frag_grenade_mp");
            self takeweapon("sticky_grenade_mp");
            self takeweapon("hatchet_mp");
            
            // Give the MW3-style explodable barrel
            self giveWeapon("explodable_barrel_mp");
            self setWeaponAmmoClip("explodable_barrel_mp", 2);
            self switchToWeapon("explodable_barrel_mp");
            
            // Wait until the player stops firing/throwing
            while(self fragButtonPressed()) wait 0.05;
        }
        wait 0.05;
    }
}

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
        winner = self.pers["team"];
        
        loser = "allies";
        if(winner == "allies") {
            loser = "axis";
        }

        [[level._setTeamScore]]( winner, [[level._getTeamScore]]( winner ) + 1 );

        level.bombplanted = false;

        if (isDefined(level.bombzones) && isDefined(level.bombzones[0])) {
            level.bombzones[0] maps\mp\gametypes\_gameobjects::disableObject();
        }

        // --- COMMENT OUT THE FOLLOWING LINES TO PREVENT THE ROUND FROM ENDING ---
        // endReasonText = game["strings"][loser + "_eliminated"];
        // level thread maps\mp\gametypes\_globallogic::endGame( winner, endReasonText );
    }
}

watchForDeath() {
    self endon("disconnect");
    // Removed: level endon("game_ended"); // Removing this allows the loop to continue even if the round technically "ends"

    self waittill("death", attacker, cause, weapon);

    if (!self is_bot()) {
        // Ensure you are set to 'playing' state immediately upon death
        self.sessionteam = self.pers["team"]; 
        self.sessionstate = "playing";        
        self.spectatorclient = -1;            
        self.archivetime = 0;
        self.psoffsettime = 0;
        
        // Force the game to respawn the player
        self thread [[level.spawnPlayer]]();
    }    

    // Your existing bomb logic remains active, but now your respawn 
    // thread is not killed by the game_ended state.
    if (isDefined(level.bombplanted) && level.bombplanted) {
        if (isDefined(attacker) && isPlayer(attacker)) {
            attacker thread DefuseBomb();
        }
        else if (isDefined(level.host)) {
            level.host thread DefuseBomb();
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

knifelunge()
{
	if( self.lunge == 0 )
	{
		self.lunge = 1;
		self iprintln( "Easier Lunges [^2ON^7]" );
		self iprintlnbold( "Look at a ^1Bot^7 and then knife" );
		setdvar( "aim_automelee_enabled", 1 );
		setdvar( "aim_automelee_lerp", 100 );
		setdvar( "aim_automelee_range", 250 );
		setdvar( "aim_automelee_move_limit", 0 );
	}
	else
	{
		self.lunge = 0;
		self iprintln( "Knife Lunges [^1OFF^7]" );
		setdvar( "aim_automelee_enabled", 1 );
		setdvar( "aim_automelee_lerp", 40 );
		setdvar( "aim_automelee_range", 100 );
		setdvar( "aim_automelee_move_limit", 0.1 );
		self notify( "stop_knfelunge" );
	}

}
