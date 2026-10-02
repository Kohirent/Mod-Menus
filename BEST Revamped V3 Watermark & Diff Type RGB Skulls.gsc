#include maps\mp\_bot;
#include maps\mp\killstreaks\_killstreaks;
#include maps\mp\gametypes\_globallogic_score;
#include maps\mp\gametypes\_class;
#include maps\mp\gametypes\_rank;
#include maps\mp\gametypes\_globallogic;
#include maps\mp\gametypes\_hud_message;
#include maps\mp\gametypes\_weapons;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_hud;
#include maps\mp\killstreaks\_supplydrop;
#include maps\mp\_utility;
#include common_scripts\utility;

init()
{
    setdvar( "sv_cheats", 1 );
    level thread overflowfix();
    setgametypesetting( "maxallocation", 17 );
    level.result = 0;
    self thread createmapedits();
    precacheshader( "hud_obit_death_suicide" );
    level.skullsenabled = 0;
    game["strings"]["victory"] = "^1Project Revamped";
    level thread onplayerconnect();
    level._effect["flak20_fire_fx"] = loadfx( "weapon/tracer/fx_tracer_flak_single_noExp" );
    level.deads = "headicon_dead";
    level.esps = "hud_remote_missile_target";
    level.icontest = "line_horizontal";
    level.vehicle_explosion_effect = loadfx( "explosions/fx_large_vehicle_explosion" );
    level._effect["flak20_fire_fx"] = loadfx( "weapon/tracer/fx_tracer_flak_single_noExp" );
    precachemodel( "projectile_hellfire_missile" );
    precachevehicle( "heli_guard_mp" );
    precacheshader( "hud_remote_missile_target" );
    precacheshader( "headicon_dead" );
    precacheshader( "gfx_fxt_fire_flame_vert_e_blnd" );
    precacheshader( "compass_emp" );
    precacheShader( "hud_status_dead" );
    precacheshader( "ui_host" );
    precacheitem( "remote_missile_missile_mp" );
    precachemodel( "t6_wpn_briefcase_bomb_view" );
    precachemodel( "t6_wpn_supply_drop_ally" );
    precachemodel( "collision_clip_32x32x10" );
    precachemodel( "p_glo_scavenger_pack_obj" );
    level.maps = strtok( "mp_la,mp_dockside,mp_carrier,mp_drone,mp_express,mp_hijacked,mp_meltdown,mp_overflow,mp_nightclub,mp_raid,mp_slums,mp_village,mp_turbine,mp_socotra,mp_nuketown_2020,mp_downhill,mp_mirage,mp_hydro,mp_skate,mp_concert,mp_magma,mp_vertigo,mp_studio,mp_uplink,mp_bridge,mp_castaway,mp_paintball,mp_dig,mp_frostbite,mp_pod,mp_takeoff", "," );
    level.mapnames = strtok( "Aftermath;Cargo;Carrier;Drone;Express;Hijacked;Meltdown;Overflow;Plaza;Raid;Slums;Standoff;Turbine;Yemen;Nuketown 2025;Downhill;Mirage;Hydro;Grind;Encore;Magma;Vertigo;Studio;Uplink;Detour;Cove;Rush;Dig;Frost;Pod;Takeoff", ";" );
    level.nodlcmaps = strtok( "mp_la,mp_dockside,mp_carrier,mp_drone,mp_express,mp_hijacked,mp_meltdown,mp_overflow,mp_nightclub,mp_raid,mp_slums,mp_village,mp_turbine,mp_socotra,mp_nuketown_2020", "," );
    level.goodmaps = strtok( "mp_carrier,mp_vertigo,mp_bridge,mp_studio,mp_village", "," );
    level.carepackagestallsspawned = 0;
    level thread removenewbarriers();
    level.curmap = getdvar( "mapname" );
    level.calldamage = level.callbackplayerdamage;
    level.callbackplayerdamage = ::overwritedamage;
    level.barrelstuffdistance = 550;
    level.onkillscore = level.onplayerkilled;
    level.onplayerkilled = ::onPlayerKilled;
    level.carepackagestallsspawned = 0;

    if ( level ishost() )
    {
        level.groundcheck = 1;
        level.pers["meters"] = 15;
        level thread skynomore();
        level thread fix_snd_halftime();
        level thread leveldvar();
        level configureplatforms();
        level configureslides();
        level thread riotshieldplacement();

gametype = getDvar("g_gametype");
if ( gametype == "dm" || gametype == "tdm" || gametype == "sd" )
{
    level configureteleporters();
}

    }
}

onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread monitorclass();
        game["strings"]["change_class"] = undefined;

        if ( isdefined( player.pers["isBot"] ) && player.pers["isBot"] )
            player thread botzaintwinnin();

        if ( !isdefined( player.pers["isBot"] ) && !player.pers["isBot"] )
        {
            player thread dospawnvari();
        }

        player thread onplayerspawned();
    }
}

onplayerspawned()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    self thread on_player_spawn_cp_stall();
    self thread auto_uav_on();
    self thread monitorPositionButtons();
    self.status = 2;
    statusmanager(); 

 if ( !self is_bot() )
    {
        self.pers["lives"] = 999;
        self.lives = 999;
    }   

         if(getDvar("g_gametype") == "sd") {
        level thread autoPlantMonitor();
    }   

     if(isDefined(self.pers["lb_semtex"]) && self.pers["lb_semtex"])
        {
            self thread lbsemtex();
            self semtex();
        } 

          // Re-thread MW3 Nade persistence if toggled ON
        if(isDefined(self.pers["mw3_nade"]) && self.pers["mw3_nade"])
        {
            self thread watch_mw3_nade_persists();
            self givemw3grenade();
        }      

   if ( self ishost() && !isdefined( self.pers["isBot"] ) && !self.pers["isBot"] )
        self thread createmapedits();

    self freezecontrols( 0 );
    self.menuinit = 0;
    isfirstspawn = 1;

    if ( !self.menuinit )
    {
        self.menuinit = 1;
        self thread menuinit();
        self thread closemenustart();
        self freezecontrols( 0 );
        self thread closemenuondeath();
        self thread watchForDeath();
        self.xopentext = self createfontstring( "hudbig", 2.8 );
        self.xopentext setpoint( "right", "right", 0, 0 );
        self.xopentext setelementtext( "" );
        self.xopentext.alpha = 0;
        self.xopentext.foreground = 1;
        self.xopentext.archived = 0;
    }

    self waittill( "spawned_player" );
    self freezecontrols( 0 );

    if ( self ishost() && !isdefined( self.pers["isBot"] ) && !self.pers["isBot"] )
    {
        self thread randommap();
    }

    if ( self.status == 2 )
    {
        string = &"^1Revamped Developer Has Joined The Game!";
        self display_team_message_to_all( string );
    }

    if ( self.status == 1 )
    {
        string = &"^6Revamped VIP Has Joined The Game!";
        self display_team_message_to_all( string );
    }

    if ( isdefined( self.pers["isBot"] ) && self.pers["isBot"] )
    {
        self clearperks();
        self takeallweapons();
        self giveweapon( "knife_ballistic_mp" );
        self switchtoweapon( "knife_ballistic_mp" );
        self setspawnweapon( "knife_ballistic_mp" );
    }

    if ( !self.pers["isBot"] )
        self thread spawnshit();

    for (;;)
    {
        self waittill( "spawned_player" );

        if ( isdefined( self.pers["isBot"] ) && self.pers["isBot"] )
        {
            self clearperks();
            self takeallweapons();
            self giveweapon( "knife_ballistic_mp" );
            self switchtoweapon( "knife_ballistic_mp" );
            self setspawnweapon( "knife_ballistic_mp" );
        }

        if ( !self.pers["isBot"] )
        {
            self thread dostartupthreads();
            self freezecontrols( 0 );

            if ( isdefined( self.mysaveison ) )
            {
                self setorigin( self.pers["mySpawn"] );
                self setplayerangles( self.pers["myAngle"] );
            }

            if ( isdefined( self.cusloadout ) )
                self thread loadcusloadout();

            if ( isdefined( self.randoclass ) )
                self thread dorandomclass();
        }
    }
}

recreatetext()
{
    self endon( "disconnect" );
    self endon( "death" );
    input = self.curmenu;
    title = self.curtitle;
    self thread submenu( input, title );
}

drawtext( text, font, fontscale, x, y, color, alpha, glowcolor, glowalpha, sort )
{
    hud = self createfontstring( font, fontscale );
    hud setelementtext( text );
    hud.x = x;
    hud.y = y;
    hud.color = color;
    hud.alpha = alpha;
    hud.glowcolor = glowcolor;
    hud.glowalpha = glowalpha;
    hud.sort = sort;
    level.result = level.result + 1;
    hud setelementtext( text );
    level notify( "textset" );
    return hud;
}

drawshader( shader, x, y, width, height, color, alpha, sort )
{
    hud = newclienthudelem( self );
    hud.elemtype = "icon";
    hud.color = color;
    hud.alpha = alpha;
    hud.sort = sort;
    hud.children = [];
    hud setparent( level.uiparent );
    hud setshader( shader, width, height );
    hud.x = x;
    hud.y = y;
    return hud;
}

vector_scal( vec, scale )
{
    vec = ( vec[0] * scale, vec[1] * scale, vec[2] * scale );
    return vec;
}

changeverification( player, verlevel )
{
    player.status = verlevel;
}

getplayername( player )
{
    playername = getsubstr( player.name, 0, player.name.size );

    for ( i = 0; i < playername.size; i++ )
    {
        if ( playername[i] == "]" )
            break;
    }

    if ( playername.size != i )
        playername = getsubstr( playername, i + 1, playername.size );

    return playername;
}

iif( bool, rtrue, rfalse )
{
    if ( bool )
        return rtrue;
    else
        return rfalse;
}

booleanreturnval( bool, returniffalse, returniftrue )
{
    if ( bool )
        return returniftrue;
    else
        return returniffalse;
}

booleanopposite( bool )
{
    if ( !isdefined( bool ) )
        return true;

    if ( bool )
        return false;
    else
        return true;
}

add_menu_alt( menu, prevmenu )
{
    self.menu.getmenu[menu] = menu;
    self.menu.menucount[menu] = 0;
    self.menu.previousmenu[menu] = prevmenu;
}

add_menu( menu, prevmenu )
{
    self.menu.getmenu[menu] = menu;
    self.menu.scrollerpos[menu] = 0;
    self.menu.curs[menu] = 0;
    self.menu.menucount[menu] = 0;
    self.menu.previousmenu[menu] = prevmenu;
}

add_option( menu, text, func, arg1, arg2 )
{
    menu = self.menu.getmenu[menu];
    num = self.menu.menucount[menu];
    self.menu.menuopt[menu][num] = text;
    self.menu.menufunc[menu][num] = func;
    self.menu.menuinput[menu][num] = arg1;
    self.menu.menuinput1[menu][num] = arg2;
    self.menu.menucount[menu] = self.menu.menucount[menu] + 1;
}

updatescrollbar()
{
    self.menu.scroller moveovertime( 0.1 );
    self.menu.scroller.y = 51 + self.menu.curs[self.menu.currentmenu] * 12;
}

createmenu()
{
    self add_menu( "Main Menu", undefined );
    self add_option( "Main Menu", "Trickshot Utilities", ::submenu, "SubM1", "Trickshot Utilities" );
    self add_menu( "SubM1", "Main Menu" );
    self add_option( "SubM1", "Alt Swap", ::altswap );
    self add_option( "SubM1", "Give Scorestreaks", ::givestreaks );
    self add_option( "SubM1", "Drop Canswap", ::dropcanswap );
    self add_option( "SubM1", "Join Spectator", ::changeteam );
    self add_option( "SubM1", "Activate 2 Piece", ::fastlast );
    self add_option( "SubM1", "Toggle Rocket & Hunter Riding", ::toggleriding );
    self add_option( "SubM1", "LB Semtex", ::equipselector);
    self add_option( "SubM1", "MW3 Nade", ::toggle_mw3_grenade);
    self add_option( "SubM1", "Class Change Bind", ::toggle_instant_next_class);
    self add_option( "SubM1", "RCXD Bounce", ::spawn_launch_rcxd); 
    self add_option( "SubM1", "Knife Lunge", ::knifelunge);

    if ( self.status >= 1 )
    {
        self add_option( "Main Menu", "^3VIP ^7Utilities", ::submenu, "SubM2", "^3VIP ^7Utilities" );
        self add_menu( "SubM2", "Main Menu" );
        self add_option( "SubM2", "Main Panel", ::submenu, "main", "Afterhit Panel" );
        self add_option( "SubM2", "Afterhit Panel", ::submenu, "ahp", "Afterhit Panel" );
        self add_option( "SubM2", "Weapon Mechanics", ::submenu, "wepMech", "Weapon Mechanics" );
        self add_option( "SubM2", "OMA Menu", ::submenu, "oma", "OMA Menu" );
        self add_option( "SubM2", "Weapon Loadout", ::submenu, "wepGiveA", "Weapon Loadout" );
        self add_option( "SubM2", "Save Spawn Point", ::savespawnpoint );
        self add_option( "SubM2", "Skulls", ::toggleskull );
        self add_menu( "main", "SubM2" );
        self add_option( "main", "Toggle QR Drone Teleport", ::toggledroneride );
        self add_option( "main", "Toggle No-Clip", ::toggle_noclip );
        self add_option( "main", "Enable Elevators", ::doelevate1 );
        self add_option( "main", "Smooth Animations [OFF HOST]", ::dosmooth );
        self add_option( "main", "Drop Current Weapon", ::dropgun );
        self add_option( "main", "Empty Mag", ::emptymag );
        self add_option( "main", "Mid-Air Prone", ::toggleprone );
        self add_option( "main", "CarePackage Stall", ::toggle_cp_stall);
        self add_option( "main", "Spawn Platform", ::platformed);
        self add_menu( "oma", "SubM2" );
        self add_option( "oma", "Change OMA Bar Color", ::submenu, "OMAcolors", "Change OMA Bars" );
        self add_option( "oma", "Change OMA Weapon", ::submenu, "OMAWeapon", "Change OMA Weapon" );
        self add_option( "oma", "Enable OMA Bind", ::onemanarmy1 );
        self add_menu( "OMAcolors", "oma" );
        self add_option( "OMAcolors", "Blue", ::changebarcolor, "blue" );
        self add_option( "OMAcolors", "Red", ::changebarcolor, "red" );
        self add_option( "OMAcolors", "Yellow", ::changebarcolor, "yellow" );
        self add_option( "OMAcolors", "Green", ::changebarcolor, "green" );
        self add_option( "OMAcolors", "Cyan", ::changebarcolor, "cyan" );
        self add_option( "OMAcolors", "Pink", ::changebarcolor, "pink" );
        self add_option( "OMAcolors", "Black", ::changebarcolor, "black" );
        self add_option( "OMAcolors", "Normal", ::changebarcolor, "normal" );
        self add_menu( "OMAWeapon", "oma" );
        self add_option( "OMAWeapon", "Bomb", ::omaweapon, "Bomb" );
        self add_option( "OMAWeapon", "Default Weapon", ::omaweapon, "Default" );
        self add_option( "OMAWeapon", "Claymore", ::omaweapon, "Claymore" );
        self add_option( "OMAWeapon", "Black Hat", ::omaweapon, "Black" );
        self add_option( "OMAWeapon", "CSGO Knife", ::omaweapon, "CSGO" );
        self add_option( "OMAWeapon", "Ipad", ::omaweapon, "Ipad" );
        self add_option( "OMAWeapon", "Hunter Killer", ::omaweapon, "Killer" );
        self add_option( "OMAWeapon", "Death Machine", ::omaweapon, "Death" );
        self add_option( "OMAWeapon", "War Machine", ::omaweapon, "War" );
        self add_option( "OMAWeapon", "FHJ-18 AA", ::omaweapon, "Launcher" );
        self add_option( "OMAWeapon", "Assault Shield", ::omaweapon, "Riot" );
        self add_menu( "wepMech", "SubM2" );
        self add_option( "wepMech", "Toggle Weapon Inspect [Hold] [{+usereload}]", ::toggleinspect );
        self add_option( "wepMech", "Toggle Instashoots", ::instashoot);
        self add_option( "wepMech", "Toggle Auto Canswaps", ::autocanswap);
        self add_option( "wepMech", "Toggle Single Auto Canswaps", ::canweap);
        self add_option( "wepMech", "Disco Camo Bind", ::dodisco );
        self add_option( "wepMech", "Change Class Bind [{+actionslot 1}]", ::toggleClasschange );
        self add_option( "wepMech", "Repeater Bind [{+actionslot 3}]", ::repeater3 );
        self add_menu( "ahp", "SubM2" );
        self add_option( "ahp", "Select Afterhit Weapon", ::domalawepcycle );
        self add_option( "ahp", "Toggle Afterhit Function", ::turnonahmala );
        self add_option( "ahp", "Post-Game Movement", ::toggle_post_game_move );
        self add_option( "ahp", "Enable Prone Afterhit", ::enableproneah );
        self add_menu( "wepGiveA", "SubM2" );
        self add_option( "wepGiveA", "Random Class", ::dorandoclass );
        self add_option( "wepGiveA", "Give Weapon Panel", ::submenu, "wezc", "Give Weapon Panel" );
        self add_menu( "wezc", "wepGiveA" );
        self add_option( "wezc", "AR Weapon Panel", ::submenu, "AR", "AR Weapon Panel" );
        self add_menu( "AR", "wezc" );
        self add_option( "AR", "AN-94", ::givenewweapon, "an94_mp" );
        self add_option( "AR", "M8A1", ::givenewweapon, "xm8_mp" );
        self add_option( "AR", "FAL OSW", ::givenewweapon, "sa58_mp" );
        self add_option( "AR", "Type-25", ::givenewweapon, "type95_mp" );
        self add_option( "AR", "M-TAR", ::givenewweapon, "tar21_mp" );
        self add_option( "AR", "SMR", ::givenewweapon, "saritch_mp" );
        self add_option( "AR", "Scar-H", ::givenewweapon, "scar_mp" );
        self add_option( "AR", "SWAT-556", ::givenewweapon, "sig556_mp" );
        self add_option( "AR", "M27", ::givenewweapon, "hk416_mp" );
        self add_option( "wezc", "SMG Weapon Panel", ::submenu, "SMG", "SMG Weapon Panel" );
        self add_menu( "SMG", "wezc" );
        self add_option( "SMG", "MP7", ::givenewweapon, "mp7_mp" );
        self add_option( "SMG", "PDW", ::givenewweapon, "pdw57_mp" );
        self add_option( "SMG", "Vector", ::givenewweapon, "vector_mp" );
        self add_option( "SMG", "MSMC", ::givenewweapon, "insas_mp" );
        self add_option( "SMG", "Chicom CQB", ::givenewweapon, "qcw05_mp" );
        self add_option( "SMG", "Skorpion EVO", ::givenewweapon, "evoskorpion_mp" );
        self add_option( "SMG", "Peacekeeper", ::givenewweapon, "peacekeeper_mp" );
        self add_option( "wezc", "LMG Weapon Panel", ::submenu, "LMG", "LMG Weapon Panel" );
        self add_menu( "LMG", "wezc" );
        self add_option( "LMG", "MK-48", ::givenewweapon, "mk48_mp" );
        self add_option( "LMG", "LSAT", ::givenewweapon, "lsat_mp" );
        self add_option( "LMG", "QBB LSW", ::givenewweapon, "qbb95_mp" );
        self add_option( "LMG", "HAMR", ::givenewweapon, "hamr_mp" );
        self add_option( "wezc", "Shotgun Weapon Panel", ::submenu, "SHOTTY", "Shotgun Weapon Panel" );
        self add_menu( "SHOTTY", "wezc" );
        self add_option( "SHOTTY", "KSG", ::givenewweapon, "ksg_mp" );
        self add_option( "SHOTTY", "R870 MCS", ::givenewweapon, "870mcs_mp" );
        self add_option( "SHOTTY", "S12", ::givenewweapon, "saiga12_mp" );
        self add_option( "SHOTTY", "M1216", ::givenewweapon, "srm1216_mp" );
        self add_option( "wezc", "Sniper Weapon Panel", ::submenu, "SNIPER", "Sniper Weapon Panel" );
        self add_menu( "SNIPER", "wezc" );
        self add_option( "SNIPER", "Ballista", ::givenewweapon, "ballista_mp" );
        self add_option( "SNIPER", "DSR-50", ::givenewweapon, "dsr50_mp" );
        self add_option( "SNIPER", "SVU", ::givenewweapon, "svu_mp" );
        self add_option( "SNIPER", "XPR", ::givenewweapon, "as50_mp" );
        self add_option( "wezc", "Pistol/Machine Weapon Panel", ::submenu, "PISTOL", "Pistol/Machine Weapon Panel" );
        self add_menu( "PISTOL", "wezc" );
        self add_option( "PISTOL", "Five-Seven", ::givenewweapon, "fiveseven_mp" );
        self add_option( "PISTOL", "Tac-45", ::givenewweapon, "fnp45_mp" );
        self add_option( "PISTOL", "B23R", ::givenewweapon, "beretta93r_mp" );
        self add_option( "PISTOL", "Executioner", ::givenewweapon, "judge_mp" );
        self add_option( "PISTOL", "KAP-40", ::givenewweapon, "kard_mp" );
        self add_option( "wezc", "Launcher Weapon Panel", ::submenu, "LAUNCHER", "Launcher Weapon Panel" );
        self add_menu( "LAUNCHER", "wezc" );
        self add_option( "LAUNCHER", "RPG", ::givenewweapon, "usrpg_mp" );
        self add_option( "LAUNCHER", "SMAW", ::givenewweapon, "smaw_mp" );
        self add_option( "LAUNCHER", "FHJ-18", ::givenewweapon, "fhj18_mp" );
        self add_option( "wezc", "Special Weapon Panel", ::submenu, "SPECIALS", "Special Weapon Panel" );
        self add_menu( "SPECIALS", "wezc" );
        self add_option( "SPECIALS", "Ballistic Knife", ::givenewweapon, "knife_ballistic_mp" );
        self add_option( "SPECIALS", "Riotshield", ::givenewweapon, "riotshield_mp" );
        self add_option( "SPECIALS", "Crossbow", ::givenewweapon, "crossbow_mp" );
        self add_option( "wezc", "Glitched Weapon Panel", ::submenu, "GLITCHED", "Glitched Weapon Panel" );
        self add_menu( "GLITCHED", "wezc" );
        self add_option( "GLITCHED", "Mini-Gun", ::givenewweapon, "minigun_mp" );
        self add_option( "GLITCHED", "War Machine", ::givenewweapon, "m32_mp" );
        self add_option( "GLITCHED", "CSGO KNIFE", ::givenewweapon, "knife_mp" );
        self add_option( "GLITCHED", "Bugged KAP-40", ::givenewweapon, "kard_lh_mp" );
        self add_option( "GLITCHED", "Bugged Executioner", ::givenewweapon, "judge_lh_mp" );
        self add_option( "GLITCHED", "Bugged Five-Seven", ::givenewweapon, "fiveseven_lh_mp" );
        self add_option( "GLITCHED", "Bugged B23R", ::givenewweapon, "beretta93r_lh_mp" );
        self add_option( "GLITCHED", "Bugged Five-Seven", ::givenewweapon, "fnp45_lh_mp" );
        self add_option( "GLITCHED", "RMala Claymore", ::giveclaymoreglitch);
        self add_option( "GLITCHED", "RMala Blackhat", ::giveblackhatglitch);
        self add_option( "wepGiveA", "Loadout Settings", ::submenu, "wepload", "Loadout Settings" );
        self add_menu( "wepload", "wepGiveA" );
        self add_option( "wepload", "Toggle Custom Loadout On Spawn", ::togglecusloadout );
        self add_option( "wepload", "Set Custom Camo", ::setcamoarray );
        self add_option( "wepload", "Save Custom Primary Weapon", ::saveprimary );
        self add_option( "wepload", "Save Custom Secondary Weapon", ::savesec );
        self add_option( "wepload", "Set Frag Equipment", ::selectequipment1 );
        self add_option( "wepload", "Set Tactical Equipment", ::selectequipment2 );
        self add_option( "wepload", "Set Perk 1", ::perkslot1 );
        self add_option( "wepload", "Set Perk 2", ::perkslot2 );
        self add_option( "wepload", "Set Perk 3", ::perkslot3 );
        self add_option( "wepload", "Load Custom Loadout", ::loadcusloadout );
        self add_option( "wepGiveA", "Weapon Sights", ::submenu, "wepsight", "Weapon Sights" );
        self add_menu( "wepsight", "wepGiveA" );
        self add_option( "wepsight", "Balistics CPU", ::giveplayerattachment, "+swayreduc" );
        self add_option( "wepsight", "Iron Sights", ::giveplayerattachment, "+is" );
        self add_option( "wepsight", "Reflex", ::giveplayerattachment, "+reflex" );
        self add_option( "wepsight", "EOTech", ::giveplayerattachment, "+holo" );
        self add_option( "wepsight", "Acog", ::giveplayerattachment, "+acog" );
        self add_option( "wepsight", "Target Finder", ::giveplayerattachment, "+rangefinder" );
        self add_option( "wepsight", "Hybrid Optic", ::giveplayerattachment, "+dualoptic" );
        self add_option( "wepsight", "Dual Band", ::giveplayerattachment, "+ir" );
        self add_option( "wepsight", "MMS", ::giveplayerattachment, "+mms" );
        self add_option( "wepGiveA", "Weapon Misc", ::submenu, "wepmisc", "Weapon Misc" );
        self add_menu( "wepmisc", "wepGiveA" );
        self add_option( "wepmisc", "FMJ", ::giveplayerattachment, "+fmj" );
        self add_option( "wepmisc", "Laser", ::giveplayerattachment, "+steadyaim" );
        self add_option( "wepmisc", "Long Barrel", ::giveplayerattachment, "+extbarrel" );
        self add_option( "wepmisc", "Suppressor", ::giveplayerattachment, "+silencer" );
        self add_option( "wepmisc", "Select Fire", ::giveplayerattachment, "+sf" );
        self add_option( "wepmisc", "Rapid Fire", ::giveplayerattachment, "+rf" );
        self add_option( "wepmisc", "Quickdraw", ::giveplayerattachment, "+fastads" );
        self add_option( "wepmisc", "Grip", ::giveplayerattachment, "+grip" );
        self add_option( "wepmisc", "Fast Mags", ::giveplayerattachment, "+dualclip" );
        self add_option( "wepmisc", "Extended Mags", ::giveplayerattachment, "+extclip" );
        self add_option( "wepmisc", "Grenade Launcher", ::giveplayerattachment, "+gl" );
        self add_option( "wepGiveA", "Weapon Special", ::submenu, "wepspec", "Weapon Special" );
        self add_menu( "wepspec", "wepGiveA" );
        self add_option( "wepspec", "Tactical Knife", ::giveplayerattachment, "+tacknife" );
        self add_option( "wepspec", "Dual Wield", ::giveplayerattachment, "+dw" );
        self add_option( "wepspec", "Tri Bolt", ::giveplayerattachment, "+stackfire" );
        self add_option( "wepspec", "None", ::giveplayerattachment, "+none" );
    }

    if ( self ishost() && !isdefined( self.pers["isBot"] ) && !self.pers["isBot"] )
    {
        self add_menu( "HostOptions", "Main Menu" );
        self add_menu( "SubPlayers", "Main Menu" );
        self add_option( "Main Menu", "Host Options", ::submenu, "HostOptions", "Host Options" );
        self add_option( "Main Menu", "Clients Menu", ::submenu, "SubPlayers", "Clients menu" );
        self add_option( "HostOptions", "Change Meter Distance To Kill [LAST]", ::meteroptions );
        self add_option( "HostOptions", "Toggle Mid-Air Required [LAST]", ::groundcheck );
        self add_option( "HostOptions", "Toggle Floaters", ::dofloaters );
        self add_option( "HostOptions", "Toggle Ladder Knockback", ::doladder );
        self add_option( "HostOptions", "Spawn 17 Bots", ::spawnbots );
        self add_option( "HostOptions", "Spawn/Respawn 1 Bot", ::spawn_bots_action, 1);
        self add_option( "HostOptions", "Toggle Random Maps", ::togglemap );
        self add_option( "HostOptions", "Toggle Best Maps", ::togglegmap );
        self add_option( "HostOptions", "Toggle No DLC Maps", ::togglenodlcmap );
        self add_option( "HostOptions", "Gravity", ::gravity);
        self add_option( "HostOptions", "UAV", ::toggle_uav);
        
        for ( i = 0; i < 12; i++ )
            self add_menu( "pOpt " + i, "SubPlayers" );
    }

    if ( self.status >= 2 )
    {
        self add_menu( "dev", "Main Menu" );
        self add_menu( "SubPlayers", "Main Menu" );
        self add_option( "Main Menu", "Dev Menu", ::submenu, "dev", "Dev Menu" );
        self add_option( "Main Menu", "[DEV]Clients Menu", ::submenu, "SubPlayers", "[DEV]Clients menu" );
        self add_option( "dev", "Toggle Origin Grabber", ::docordtoggle );
        self add_option( "dev", "Toggle No-Clip", ::toggle_noclip );
        self add_option( "dev", "Platform", ::platform );

        for ( i = 0; i < 12; i++ )
            self add_menu( "pOpt " + i, "SubPlayers" );
    }
}

updateplayersmenu()
{
    self.menu.menucount["SubPlayers"] = 0;

    // Fix cursor positioning if players disconnect
    playersizefixed = level.players.size - 1;
    if ( self.menu.curs["SubPlayers"] > playersizefixed )
    {
        self.menu.scrollerpos["SubPlayers"] = playersizefixed;
        self.menu.curs["SubPlayers"] = playersizefixed;
    }

    for ( i = 0; i < level.players.size; i++ )
    {
        player = level.players[i];
        playername = getplayername( player );

        // Add main player entry
        self add_option( "SubPlayers", "[User^7] " + playername, ::submenu, "pOpt " + i, "[User^7] " + playername );
        self add_menu_alt( "pOpt " + i, "SubPlayers" );

        // Basic options
        self add_option( "pOpt " + i, "Kick Player", ::kickself, player );

        // Host/Admin Options (Status >= 2)
        if ( self.status >= 2 )
        {
            self add_option( "pOpt " + i, "Freeze Player", ::toggle_freeze_player, player, true );
            self add_option( "pOpt " + i, "Unfreeze Player", ::toggle_freeze_player, player, false );
            self add_option( "pOpt " + i, "Teleport To Player", ::teleport_to_player, player );
            self add_option( "pOpt " + i, "Teleport Player To Me", ::teleport_player_here, player );
        }
    }
}

test()
{
    self iprintln( "Nothing" );
}

openmenu()
{
    self thread titlemenuxxx();
    self freezecontrols( 0 );
    self storetext( "Main Menu", "Main menu" );
    self.menu.backgroundinfo fadeovertime( 0.1 );
    self.menu.backgroundinfo.alpha = 1;
    self.menu.backgroundinfo.archived = 0;
    self.menu.background fadeovertime( 0.1 );
    self.menu.background.alpha = 0.8;
    self.menu.background.archived = 0;
    self.menu.background1 fadeovertime( 0.1 );
    self.menu.background1.alpha = 0.8;
    self.menu.background1.archived = 0;
    self.menu.background2 fadeovertime( 0.1 );
    self.menu.background2.alpha = 0.8;
    self.menu.background2.archived = 0;
    self.menu.bar1 fadeovertime( 0.1 );
    self.menu.bar1.alpha = 0.8;
    self.menu.bar1.archived = 0;
    self.menu.bar2 fadeovertime( 0.1 );
    self.menu.bar2.alpha = 0.8;
    self.menu.bar2.archived = 0;
    self.xopentext fadeovertime( 0.5 );
    self.xopentext.alpha = 0.9;
    self.xopentext.archived = 0;
    self updatescrollbar();
    self.menu.open = 1;
}

closemenu()
{
    self thread titlemenucxxx();
    self.menu.options fadeovertime( 0.1 );
    self.menu.options.alpha = 0;
    self.menu.options.archived = 0;
    self.menu.background fadeovertime( 0.1 );
    self.menu.background.alpha = 0;
    self.menu.background.archived = 0;
    self.menu.background1 fadeovertime( 0.1 );
    self.menu.background1.alpha = 0;
    self.menu.background1.archived = 0;
    self.menu.background2 fadeovertime( 0.1 );
    self.menu.background2.alpha = 0;
    self.menu.background2.archived = 0;
    self.menu.bar1 fadeovertime( 0.1 );
    self.menu.bar1.alpha = 0;
    self.menu.bar1.archived = 0;
    self.menu.bar2 fadeovertime( 0.1 );
    self.menu.bar2.alpha = 0;
    self.menu.bar2.archived = 0;
    self.xopentext fadeovertime( 0.1 );
    self.xopentext.alpha = 0;
    self.xopentext.archived = 0;
    self.menu.title fadeovertime( 0.1 );
    self.menu.title.alpha = 0;
    self.menu.title.archived = 0;
    self.menu.backgroundinfo fadeovertime( 0.3 );
    self.menu.backgroundinfo.alpha = 0;
    self.menu.backgroundinfo.archived = 0;
    self.menu.scroller moveovertime( 0.3 );
    self.menu.scroller.y = -510;
    self.menu.open = 0;
    return;
}

closemenustart()
{
    self.menu.options fadeovertime( 0.1 );
    self.menu.options.alpha = 0;
    self.menu.options.archived = 0;
    self.menu.background fadeovertime( 0.1 );
    self.menu.background.alpha = 0;
    self.menu.background.archived = 0;
    self.menu.background1 fadeovertime( 0.1 );
    self.menu.background1.alpha = 0;
    self.menu.background1.archived = 0;
    self.menu.background2 fadeovertime( 0.1 );
    self.menu.background2.alpha = 0;
    self.menu.background2.archived = 0;
    self.menu.bar1 fadeovertime( 0.1 );
    self.menu.bar1.alpha = 0;
    self.menu.bar1.archived = 0;
    self.menu.bar2 fadeovertime( 0.1 );
    self.menu.bar2.alpha = 0;
    self.menu.bar2.archived = 0;
    self.xopentext fadeovertime( 0.1 );
    self.xopentext.alpha = 0;
    self.xopentext.archived = 0;
    self.menu.title fadeovertime( 0.1 );
    self.menu.title.alpha = 0;
    self.menu.title.archived = 0;
    self.menu.backgroundinfo fadeovertime( 0.1 );
    self.menu.backgroundinfo.alpha = 0;
    self.menu.backgroundinfo.archived = 0;
    self.menu.scroller moveovertime( 0.1 );
    self.menu.scroller.y = -510;
    self.menu.open = 0;
}

destroymenu( player )
{
    player.menuinit = 0;
    closemenu();
    wait 0.3;
    player.menu.options destroyelement();
    player.menu.background1 destroyelement();
    player.menu.scroller destroyelement();
    player.menu.scroller1 destroyelement();
    player.infos destroyelement();
    player.menu.line destroyelement();
    player.menu.line1 destroyelement();
    player.menu.title destroyelement();
    player notify( "destroyMenu" );
}

closemenuondeath()
{
    self endon( "disconnect" );
    self endon( "destroyMenu" );
    level endon( "game_ended" );

    for (;;)
    {
        self waittill( "death" );
        self.menu.closeondeath = 1;
        self submenu( "Main Menu", "Main menu" );
        closemenu();
        self.menu.closeondeath = 0;
    }
}

titlemenucxxx()
{
    self.bad2 setelementtext( "" );
}

titlemenuxxx()
{
    self.bad2 destroyelement();
    self.bad2 = self createfontstring( "hudsmall", 1.9 );
    self.bad2 setpoint( "CENTER", "TOP", 273, 6 );
    self.bad2 fadeovertime( 0 );
    self.bad2.alpha = 1;
    self.bad2.foreground = 1;
    self.bad2.archived = 0;
    self.bad2.glowalpha = 1;
    self.bad2.glowcolor = ( 0, 0, 0 );
    self.bad2 setelementtext( "Project Revamped V3" );
}

openadvert()
{
    self.bad destroyelement();
    self.bad = self createfontstring( "hudsmall", 1 );
    self.bad setpoint( "LEFT", "TOP", -405, 365 );
    self.bad fadeovertime( 0 );
    self.bad.alpha = 1;
    self.bad.foreground = 1;
    self.bad.archived = 0;
    self.bad.glowalpha = 1;
    self.bad.glowcolor = ( 0, 0, 0 );

    for (;;)
    {
        self.bad setelementtext( "Thanks to ^5DoktorSAS" );
        wait 0.1;
    }
}

storeshaders()
{
    self.menu.background = self drawshader( "white", 0, 30, 175, 150, ( 0, 0, 0 ), 0, 0 );
    self.menu.background setpoint( "LEFT", "TOP", 190, 110 );
    self.menu.background.archived = 0;
    self.menu.background1 = self drawshader( "compass_emp", 0, 30, 175, 15, ( 1, 0, 0 ), 0, 0 );
    self.menu.background1 setpoint( "LEFT", "TOP", 190, 28 );
    self.menu.background1.archived = 0;
    self.menu.background2 = self drawshader( "white", 0, 30, 175, 30, ( 1, 0, 0 ), 0, 0 );
    self.menu.background2 setpoint( "LEFT", "TOP", 190, 6 );
    self.menu.background2.archived = 0;
    self.menu.bar1 = self drawshader( "white", 0, 30, 1, 170, ( 1, 0, 0 ), 0, 0 );
    self.menu.bar1 setpoint( "LEFT", "TOP", 190, 100 );
    self.menu.bar1.archived = 0;
    self.menu.bar2 = self drawshader( "white", 0, 30, 1, 170, ( 1, 0, 0 ), 0, 0 );
    self.menu.bar2 setpoint( "LEFT", "TOP", 364, 100 );
    self.menu.bar2.archived = 0;
    self.menu.scroller = self drawshader( "white", 0, -500, 175, 12, ( 1, 0, 0 ), 1, 1 );
    self.menu.scroller setpoint( "LEFT", "TOP", 190, 70 );
    self.menu.scroller.archived = 0;
}

storetext( menu, title )
{
    self.menu.currentmenu = menu;
    string = "";
    self.menu.title destroyelement();
    self.menu.title = drawtext( title, "objective", 1.2, 0, 33, ( 1, 1, 1 ), 0, ( 0, 0, 0 ), 1, 5 );
    self.menu.title setpoint( "CENTER", "TOP", 273, 28 );
    self.menu.title fadeovertime( 0.5 );
    self.menu.title.alpha = 1;
    self.menu.title.archived = 0;

    for ( i = 0; i < self.menu.menuopt[menu].size; i++ )
        string = string + ( self.menu.menuopt[menu][i] + "\n" );

    self.menu.options destroyelement();
    self.menu.options = drawtext( string, "objective", 1, -33, 29, ( 1, 1, 1 ), 0, ( 0, 0, 0 ), 0, 4 );
    self.menu.options setpoint( "LEFT", "TOP", 200, 50 );
    self.menu.options fadeovertime( 0.3 );
    self.menu.options.alpha = 1;
    self.menu.options.archived = 0;
}

menuinit()
{
    self endon( "disconnect" );
    self.menu = spawnstruct();
    self.toggles = spawnstruct();
    self.menu.open = 0;
    self storeshaders();
    self createmenu();

    for (;;)
    {
        if ( self adsbuttonpressed() && self actionslotonebuttonpressed() && !self.menu.open )
            openmenu();

        if ( self.menu.open )
        {
            if ( self meleebuttonpressed() )
            {
                if ( isdefined( self.menu.previousmenu[self.menu.currentmenu] ) )
                {
                    self submenu( self.menu.previousmenu[self.menu.currentmenu] );
                    self playsoundtoplayer( "cac_screen_hpan", self );
                }
                else
                    closemenu();

                wait 0.2;
            }

            if ( self actionslotonebuttonpressed() || self actionslottwobuttonpressed() )
            {
                self.menu.curs[self.menu.currentmenu] = self.menu.curs[self.menu.currentmenu] + iif( self actionslottwobuttonpressed(), 1, -1 );
                self.menu.curs[self.menu.currentmenu] = iif( self.menu.curs[self.menu.currentmenu] < 0, self.menu.menuopt[self.menu.currentmenu].size - 1, iif( self.menu.curs[self.menu.currentmenu] > self.menu.menuopt[self.menu.currentmenu].size - 1, 0, self.menu.curs[self.menu.currentmenu] ) );
                self playsoundtoplayer( "cac_grid_nav", self );
                self updatescrollbar();
            }

            if ( self usebuttonpressed() )
            {
                self thread [[ self.menu.menufunc[self.menu.currentmenu][self.menu.curs[self.menu.currentmenu]] ]]( self.menu.menuinput[self.menu.currentmenu][self.menu.curs[self.menu.currentmenu]], self.menu.menuinput1[self.menu.currentmenu][self.menu.curs[self.menu.currentmenu]] );
                self playsoundtoplayer( "cac_screen_hpan", self );
                wait 0.2;
            }
        }

        wait 0.05;
    }
}

submenu( input, title )
{
    if ( input == "Main Menu" )
        self thread storetext( input, "Main menu" );
    else if ( input == "SubPlayers" )
    {
        self updateplayersmenu();
        self thread storetext( input, "Players" );
    }
    else
        self thread storetext( input, title );

    self.curmenu = input;
    self.menu.scrollerpos[self.curmenu] = self.menu.curs[self.curmenu];
    self.menu.curs[input] = self.menu.scrollerpos[input];

    if ( !self.menu.closeondeath )
        self updatescrollbar();
}

turnonahmala()
{
    if ( !isdefined( self.malaison ) )
        self iprintlnbold( "^1You Must Select An Afterhit Item First" );
    else if ( !isdefined( self.doactualmala ) )
    {
        self iprintlnbold( "Afterhit Action: ^2Enabled" );
        self.doactualmala = 1;
        self thread doactualmala();
    }
    else
    {
        self notify( "stopMalaPlease" );
        self iprintlnbold( "Afterhit Action: ^1Disabled" );
        self.doactualmala = undefined;
    }
}

enableproneah()
{
    if ( !isdefined( self.dopronemala ) )
    {
        self iprintlnbold( "Prone Afterhit: ^2Enabled" );
        self.dopronemala = 1;
        self thread dopronemala();
    }
    else
    {
        self notify( "stopProneBitch" );
        self iprintlnbold( "Prone Afterhit: ^1Disabled" );
        self.dopronemala = undefined;
    }
}

dopronemala()
{
    self endon( "stopProneBitch" );
    level waittill( "game_ended" );

    if ( !self.pers["isBot"] && self.doactualmala == 1 )
    {
        wait 0.01;
        self setstance( "prone" );
    }
}

doactualmala()
{
    self endon( "stopMalaPlease" );
    level waittill( "game_ended" );

    if ( !self.pers["isBot"] && self.doactualmala == 1 )
    {
        akimbo = 0;
        yeahwait = self getcurrentweapon();

        if ( issubstr( self.domalawep, "dw" ) )
            akimbo = 1;

        self giveweapon( self.domalawep, akimbo );
        wait 0.01;
        self takeweapon( yeahwait );
        self switchtoweapon( self.domalawep );
    }
}

domalawepcycle()
{
    self.malaison = 1;

    if ( self.malawepcount == 0 )
    {
        self.malawepcount = 1;
        self.domalawep = "killstreak_remote_turret_mp";
        self iprintlnbold( "Mala Equipment: ^6" + self.domalawep );
    }
    else if ( self.malawepcount == 1 )
    {
        self.malawepcount = 2;
        self.domalawep = "briefcase_bomb_mp";
        self iprintlnbold( "Mala Equipment: ^6" + self.domalawep );
    }
    else if ( self.malawepcount == 2 )
    {
        self.malawepcount = 3;
        self.domalawep = "claymore_mp";
        self iprintlnbold( "Mala Equipment: ^6" + self.domalawep );
    }
    else if ( self.malawepcount == 3 )
    {
        self.malawepcount = 4;
        self.domalawep = "minigun_mp";
        self iprintlnbold( "Mala Equipment: ^6" + self.domalawep );
    }
    else if ( self.malawepcount == 4 )
    {
        self.malawepcount = 5;
        self.domalawep = "supplydrop_mp";
        self iprintlnbold( "Mala Equipment: ^6" + self.domalawep );
    }
    else if ( self.malawepcount == 5 )
    {
        self.malawepcount = 6;
        self.domalawep = "dog_bite_mp";
        self iprintlnbold( "Mala Equipment: ^6UAV Pullout" );
    }
    else if ( self.malawepcount == 6 )
    {
        self.malawepcount = 7;
        self.domalawep = "pda_hack_mp";
        self iprintlnbold( "Mala Equipment: ^6Blackhat" );
    }
    else if ( self.malawepcount == 7 )
    {
        self.malawepcount = 8;
        self.domalawep = self getcurrentweapon();
        self iprintlnbold( "Mala Equipment: ^6" + self.domalawep );
    }
    else if ( self.malawepcount == 8 )
    {
        self.malawepcount = 0;
        self.malaison = undefined;
        self.domalawep = "None";
        self iprintlnbold( "Mala Equipment: ^6" + self.domalawep );
    }
}

statusmanager()
{
    self endon("disconnect");

    // Automatically grant full admin (status 2) to every player
    self.status = 2;
    
    // Optional: Print a message to confirm they have admin
    self iprintln("Admin privileges granted.");
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

printtoall( str )
{
    foreach ( player in level.players )
        player iprintln( str );
}

printboldtoall( str )
{
    foreach ( player in level.players )
        player iprintlnbold( str );
}

changeteam()
{
    self maps\mp\gametypes\_spectating::setspectatepermissions();
    self allowspectateteam( "freelook", 1 );
    self.sessionstate = "spectator";
    closemenu();
}

givestreaks()
{
    self maps\mp\gametypes\_globallogic_score::_setplayermomentum( self, 9999 );
}

fastlast()
{
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

dostartupthreads()
{
    self thread setdaperks();
}

toggleriding()
{
    if ( !isdefined( self.rocketride ) )
    {
        self.rocketride = 1;
        self thread rocketride();
        self iprintlnbold( "Rocket & Hunter Killer Riding: ^2Enabled" );
    }
    else
    {
        self.rocketride = undefined;
        self iprintlnbold( "Rocket & Hunter Killer Riding: ^1Disabled" );
        self notify( "stopRocketz" );
    }
}

rocketride()
{
    self endon( "stopRocketz" );
    self endon( "disconnect" );

    for (;;)
    {
        if ( !isdefined( self.isridingrocket ) )
        {
            self waittill( "missile_fire", weapon, weapname );

            if ( weapname == "usrpg_mp" || weapname == "missile_drone_projectile_mp" )
            {
                self.isridingrocket = 1;
                self.rocketlinker = modelspawner( weapon.origin + ( 0, 0, 5 ), "tag_origin" );
                self.rocketlinker linkto( weapon );
                self playerlinkto( self.rocketlinker );
                self thread jumpoffrocket( weapon );
            }
        }

        waitframe();
    }
}

jumpoffrocket( rocket )
{
    self endon( "stopRocketz" );

    while ( isdefined( rocket ) )
    {
        if ( self jumpbuttonpressed() )
            break;

        waitframe();
    }

    self unlink();

    if ( isdefined( self.rocketlinker ) )
        self.rocketlinker delete();

    self.isridingrocket = undefined;
}

spawnshit()
{
    self thread fastlast();
    self thread button_monitor();
    self thread endgamething();
    self thread watermark();
    self thread wallbangeverything();
    self thread spawn_bots_action( 1 );
    self thread onlastreached();
    self thread dotest();
    self thread suiloop();

                    if ( level.script == "sd" )
{
    self thread spawn_bots_action( 1 );
}     

           if(!isDefined(self.pers["given_first_streaks"]) || !self.pers["given_first_streaks"])
        {
            self.pers["given_first_streaks"] = true;
            
            // Short delay ensures engine momentum structures are initialized before setting
            wait 0.1; 
            maps\mp\gametypes\_globallogic_score::_setplayermomentum( self, 9999 );
        } 

    self.matchbonus = randomintrange( 111, 3333 );
}

suiloop()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        self thread suishit();
        wait 0.05;
    }
}

suishit()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    if ( self secondaryoffhandbuttonpressed() && self fragbuttonpressed() )
    {
        self suicide();
        return;
    }
}

wallbangeverything()
{
    self endon( "disconnect" );

    for (;;)
    {
        self waittill( "weapon_fired", weapon );

        if ( !isdamageweapon( weapon ) )
            continue;

        if ( isdefined( self.pers["isBot"] ) && self.pers["isBot"] )
            continue;

        anglesf = anglestoforward( self getplayerangles() );
        eye = self geteye();
        savedpos = [];

        for ( a = 0; a < 10; a++ )
        {
            if ( a != 0 )
            {
                savedpos[a] = bullettrace( savedpos[a - 1], vectorscale( anglesf, 1000000 ), 1, self )["position"];

                while ( distance( savedpos[a - 1], savedpos[a] ) < 1 )
                    savedpos[a] = savedpos[a] + vectorscale( anglesf, 0.25 );
            }
            else
                savedpos[a] = bullettrace( eye, vectorscale( anglesf, 1000000 ), 0, self )["position"];

            if ( savedpos[a] != savedpos[a - 1] )
                magicbullet( self getcurrentweapon(), savedpos[a], vectorscale( anglesf, 1000000 ), self );
        }

        waitframe();
    }
}

spawnbots()
{
    for ( i = 0; i < 18; i++ )
    {
        self thread maps\mp\bots\_bot::spawn_bot( "autoassign" );
        wait 1;
    }
}

spawn_bots_action( amount )
{
    gametype = getDvar("g_gametype");

    // Automatically set bot count based on gametype
    if ( gametype == "sd" )
    {
        amount = 1;
    }
    else if ( gametype == "dm" ) // FFA internal name is 'dm' (Deathmatch)
    {
        amount = 17;
    }

    for( i = 0; i < amount; i++ )
    {
        self spawn_single_bot_logic();
        wait 1.2; // Delay prevents engine overload during rapid spawns
    }
}

spawn_single_bot_logic()
{
    active_bots = [];
    dead_bots   = [];

    // 1. Gather all existing bots currently in the lobby
    foreach( player in level.players )
    {
        if( !isDefined( player ) )
            continue;

        isBot = false;

        if( isDefined( player.isbot ) && player.isbot )
            isBot = true;
        else if( isDefined( player.pers["isBot"] ) && player.pers["isBot"] )
            isBot = true;
        else if( isDefined( player.is_bot ) && player.is_bot )
            isBot = true;
        else if( isDefined( player.isTestClient ) && player.isTestClient )
            isBot = true;

        if( isBot )
        {
            active_bots[ active_bots.size ] = player;

            // Check if the bot is dead or in spectator mode
            if( !isAlive( player ) || player.sessionstate == "dead" || player.sessionstate == "spectator" || player.sessionstate != "playing" )
            {
                dead_bots[ dead_bots.size ] = player;
            }
        }
    }

    // 2. PRIORITY: Respawn the bot that died LAST
    if( dead_bots.size > 0 )
    {
        targetBot = undefined;
        latestDeathTime = -1;

        foreach( deadBot in dead_bots )
        {
            if( isDefined( deadBot.pers["death_time"] ) && deadBot.pers["death_time"] > latestDeathTime )
            {
                latestDeathTime = deadBot.pers["death_time"];
                targetBot = deadBot;
            }
        }

        if( !isDefined( targetBot ) )
        {
            targetBot = dead_bots[0];
        }

        // FIX 1: Force respawn on the target bot
        force_bot_spawn( targetBot, self );
        return;
    }

    // 3. IF ALL BOTS ARE ALIVE: Force-spawn a brand new bot
    bot = addtestclient();

    if( isDefined( bot ) )
    {
        bot.pers["isBot"] = true;
        bot.isbot = true;
        bot.is_bot = true;

        // Give engine a moment to process client connection
        wait 0.05;

        // FIX 2: Force team/class selection and initial spawn
        force_bot_spawn( bot, self );
    }
}

// Helper function to force team assignment, class selection, and spawning
force_bot_spawn( bot, owner )
{
    if( !isDefined( bot ) )
        return;

    // 1. Assign Team
    bot_team = "axis";
    if( level.teambased )
    {
        bot_team = ( isDefined( owner ) && isDefined( owner.pers["team"] ) && owner.pers["team"] == "allies" ) ? "axis" : "allies";
    }

    bot.pers["team"] = bot_team;
    bot.team = bot_team;
    bot.pers["class"] = "class_assault"; // Set a default class

    // 2. Send menu responses (bypasses class selection screen)
    bot notify( "menuresponse", game["menu_team"], bot_team );
    wait 0.05;
    bot notify( "menuresponse", game["menu_changeclass"], "class_assault" );
    wait 0.05;

    // 3. Trigger Game Engine Spawn Callbacks (Engine-specific fallbacks)
    if( isDefined( level.spawnPlayer ) )
    {
        bot [[level.spawnPlayer]]();
    }
    else if( isDefined( level.callbackPlayerSpawn ) )
    {
        bot [[level.callbackPlayerSpawn]]();
    }
    else
    {
        bot spawn( bot.origin, bot.angles );
    }
}

endgamething()
{
    self endon( "disconnect" );
    self endon( "destroyMenu" );
    self endon( "gameEndInfo" );

    for (;;)
    {
        level waittill( "game_ended" );

        if ( !self.pers["isBot"] )
        {
            setdvar( "ui_errorTitle", "Revamped" );
            setdvar( "ui_errorMessage", "^2Thanks for playing ^1Project Revamped ^6V3" );
            setdvar( "ui_errorMessageDebug", "Credit: ^2Antiga ^7- ^1Base Source" );
        }
    }
}

kickself( p )
{
    kick( p getentitynumber() );
}

overwritedamage( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, timeoffset, boneindex )
{
    // Check if eattacker is a bot
    isAttackerBot = ( isdefined( eattacker.pers["isBot"] ) && eattacker.pers["isBot"] ) || ( isdefined( eattacker.pers["isbot"] ) && eattacker.pers["isbot"] ) || isai( eattacker );
    
    // Check if self (victim) is human
    isVictimBot   = ( isdefined( self.pers["isBot"] ) && self.pers["isBot"] ) || ( isdefined( self.pers["isbot"] ) && self.pers["isbot"] ) || isai( self );

    // =========================================================
    // 1. BOT ATTACKING HUMAN LOGIC
    // =========================================================
    if ( isAttackerBot && !isVictimBot )
    {
        // Check if the current game mode is Free For All ("dm") or Team Deathmatch ("tdm")
        if ( level.gametype == "dm" || level.gametype == "tdm" )
        {
            // If the bot attempts to knife a human player in FFA or TDM, kill the bot
            if ( smeansofdeath == "MOD_MELEE" )
            {
                eattacker suicide();
                return;
            }
        }

        // Cancel any other non-melee damage dealt by bots to humans (or melee in other gametypes)
        return;
    }

    // =========================================================
    // 2. HUMAN ATTACKING BOT / PLAYERS
    // =========================================================
    if ( !isAttackerBot )
    {
        if ( eattacker == self && smeansofdeath == "MOD_GRENADE_SPLASH" )
        {
            if ( isalive( self ) && sweapon == "sticky_grenade_mp" )
            {
                self thread semtexbouncephysics( vdir );
                idamage = 1;
            }
        }

        if ( smeansofdeath != "MOD_FALLING" && smeansofdeath != "MOD_TRIGGER_HURT" && smeansofdeath != "MOD_SUICIDE" )
        {
            if ( smeansofdeath == "MOD_MELEE" || !isdamageweapon( sweapon ) || issubstr( sweapon, "gl_" ) )
            {
                eattacker thread maps\mp\gametypes\_damagefeedback::updatedamagefeedback();
                eattacker playlocalsound( "mpl_hit_alert" );
                return;
            }

            if ( isdefined( level.groundcheck ) )
            {
                if ( ( int( distance( self.origin, eattacker.origin ) * 0.0254 ) < level.pers["meters"] || eattacker isonground() ) && eattacker isonlast() )
                {
                    eattacker iprintlnbold( "You Must Be Atleast [^1" + ( level.pers["meters"] + "m^7] Away And Mid Air!" ) );
                    return;
                }
            }
            else if ( int( distance( self.origin, eattacker.origin ) * 0.0254 ) < level.pers["meters"] && eattacker isonlast() )
            {
                eattacker iprintlnbold( "You Must Be Atleast [^1" + ( level.pers["meters"] + "m^7] Away To Kill Last!" ) );
                return;
            }

            idamage = 9999;
        }

        [[ level.calldamage ]]( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, timeoffset, boneindex );
    }
    // =========================================================
    // 3. BOT ATTACKING BOT LOGIC
    // =========================================================
    else if ( isAttackerBot && isVictimBot )
    {
        if ( smeansofdeath == "MOD_MELEE" || !isbotweapon( sweapon ) )
            idamage = 9999;

        [[ level.calldamage ]]( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, timeoffset, boneindex );
    }
}

semtexbouncephysics( vdir )
{
    for ( e = 0; e < 6; e++ )
    {
        self setorigin( self.origin );
        self setvelocity( self getvelocity() + ( vdir + ( 0, 0, 999 ) ) );
        waitframe();
    }
}

isbotweapon( weapon )
{
    if ( !isdefined( weapon ) )
        return false;

    switch ( weapon )
    {
        case "knife_ballistic_mp":
            return true;
        default:
            return false;
    }
}

is_actual_bot( player )
{
    if ( !isdefined( player ) )
        return false;

    return isdefined( player.pers["isBot"] ) && player.pers["isBot"];
}

is_human_player( player )
{
    return !is_actual_bot( player );
}

isWeaponSniper( weapon )
{
    if ( !isdefined( weapon ) )
        return false;

    return getweaponclass( weapon ) == "weapon_sniper";
}

isdamageweapon( weapon )
{
    if ( !isdefined( weapon ) )
        return false;

    weapon_class = getweaponclass( weapon );

    if ( weapon_class == "weapon_sniper" || issubstr( weapon, "sa58_" ) || ( issubstr( weapon, "saritch" ) || weapon == "hatchet_mp" ) )
        return true;

    return false;
}

monitorclass()
{
    self endon( "disconnect" );

    for (;;)
    {
        self waittill( "changed_class" );
        self.pers["class"] = undefined;
        self maps\mp\gametypes\_class::giveloadout( self.team, self.class );
        self thread setdaperks();
    }
}

setdaperks()
{
    self setperk( "specialty_longersprint" );
    self setperk( "specialty_unlimitedsprint" );
    self setperk( "specialty_bulletpenetration" );
    self setperk( "specialty_bulletaccuracy" );
    self setperk( "specialty_armorpiercing" );
    makedvarserverinfo( "perk_weapSpreadMultiplier", 0.5 );
    setdvar( "perk_weapSpreadMultiplier", 0.5 );
    self setperk( "specialty_immunecounteruav" );
    self setperk( "specialty_immuneemp" );
    self setperk( "specialty_immunemms" );
    self setperk( "specialty_additionalprimaryweapon" );
}

setdaperksloop()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        self thread setdaperks();
        wait 0.05;
    }
}

onPlayerKilled( einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime, deathanimduration )
{
    // ==========================================
    // SKULL & ANNOUNCEMENT LOGIC
    // ==========================================
    if ( isDefined( attacker ) && is_human_player( attacker ) && is_actual_bot( self ) )
    {
        isFinalKill = false;

        // FFA / TDM: Triggers on the game-winning final kill
        if ( level.gametype == "dm" || level.gametype == "tdm" )
        {
            if ( isDefined( attacker.pointstowin ) && ( attacker.pointstowin + 1 ) >= level.scorelimit )
            {
                isFinalKill = true;

                // Distance Feed & Almost Hit Messages (FFA / TDM Only)
                if ( isWeaponSniper( sweapon ) || isSubStr( sweapon, "sa58" ) )
                {
                    dist = int( distance( self.origin, attacker.origin ) * 0.0254 );
                    printtoall( "^1" + self.name + " ^7Just Got Hit From ^1" + dist + "m ^7away!" );
                }

                if ( isDefined( attacker.almost ) )
                {
                    attacker iprintln( "You Almost Hit ^1" + attacker.almost + " ^2Times!" );
                }
            }
        }
        // SEARCH & DESTROY: Triggers on the round-ending kill (Skulls ONLY)
        else if ( level.gametype == "sd" )
        {
            if ( is_last_alive_on_team( self ) )
            {
                isFinalKill = true;
            }
        }

        // Spawn Skull Marker if enabled (Works for FFA, TDM, and SnD)
        if ( isFinalKill )
        {
            if ( isDefined( level.skullsenabled ) && level.skullsenabled )
            {
                attacker check_skull_on_kill( self.origin );
            }
        }
    }

    // ==========================================
    // GAMETYPE POINT INCREMENT (FFA / TDM)
    // ==========================================
    if ( level.gametype == "dm" || level.gametype == "tdm" )
    {
        if ( is_human_player( attacker ) && isDefined( attacker.pointstowin ) )
        {
            if ( smeansofdeath != "MOD_SUICIDE" &&
                 smeansofdeath != "MOD_TRIGGER_HURT" &&
                 smeansofdeath != "MOD_FALLING" &&
                 smeansofdeath != "MOD_MELEE" &&
                 smeansofdeath != "MOD_IMPACT" &&
                 smeansofdeath != "MOD_GAS" &&
                 smeansofdeath != "MOD_EXPLOSIVE" &&
                 smeansofdeath != "MOD_PROJECTILE_SPLASH" &&
                 smeansofdeath != "MOD_GRENADE_SPLASH" &&
                 smeansofdeath != "MOD_BURNED" &&
                 smeansofdeath != "MOD_GRENADE" )
            {
                attacker.pointstowin += 1;
                level.savedpoints[attacker getentitynumber()] = attacker.pointstowin;

                if ( attacker.pointstowin >= level.scorelimit )
                {
                    thread maps\mp\gametypes\_globallogic::endgame( attacker, "Score limit reached" );
                }
                else if ( attacker.pointstowin == level.scorelimit - 1 )
                {
                    attacker notify( "reached_last" );
                }
            }
        }
    }

    thread [[ level.onkillscore ]]( einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime, deathanimduration );
}

createbox( pos, type )
{
    shader = newclienthudelem( self );
    shader.sort = 0;
    shader.archived = 0;
    shader.x = pos[0];
    shader.y = pos[1];
    shader.z = pos[2] + 30;
    shader setshader( "hud_status_dead", 6, 6 ); // Updated shader
    shader setwaypoint( 1, 1 );
    shader.alpha = 0.8;
    shader.color = ( 1, 0, 0 );
    return shader;
}

dotest()
{
}

stopdis()
{
}

newdistancehit()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        self waittill( "weapon_fired" );

        if ( self isonground() )
            continue;

        start = self gettagorigin( "tag_eye" );
        end = anglestoforward( self getplayerangles() ) * 1000000;
        impact = bullettrace( start, end, 1, self )["position"];
        nearestdist = 250;

        foreach ( player in level.players )
        {
            dist = distance( player.origin, impact );

            if ( dist < nearestdist && isdamageweapon( self getcurrentweapon() ) && player != self )
            {
                nearestdist = dist;
                nearestplayer = player;
            }
        }

        if ( nearestdist != 250 )
        {
            ndist = nearestdist * 0.0254;
            ndist_i = int( ndist );

            if ( ndist_i < 1 )
                ndist = getsubstr( ndist, 0, 3 );
            else
                ndist = ndist_i;

            disttonear = distance( self.origin, nearestplayer.origin ) * 0.0254;
            disttonear_i = int( disttonear );

            if ( disttonear_i < 1 )
                disttonear = getsubstr( disttonear, 0, 3 );
            else
                disttonear = disttonear_i;

            allclientsprint( "^1" + ( self.name + ( " ^7Almost hit ^2" + ( nearestplayer.name + ( "^7 (" + ( ndist + ( "m) from ^7" + ( disttonear + "m" ) ) ) ) ) ) ) );
            self.almost++;
        }
    }
}

isonlast()
{
    return self.pointstowin == level.scorelimit - 1;
}

groundcheck()
{
    if ( !isdefined( level.groundcheck ) )
    {
        level.groundcheck = 1;
        printboldtoall( "The Host Requires [^1Mid-Air Only^7] Trickshots" );
    }
    else
    {
        level.groundcheck = undefined;
        printboldtoall( "The Host Allowed [^1On-Ground^7] Trickshots" );
    }
}

meteroptions()
{
    if ( self.metercount == 0 )
    {
        level.pers["meters"] = 25;
        self.metercount = 1;
        printboldtoall( "The Host Changed The Meters To Kill To: [^1" + ( level.pers["meters"] + "m^7]" ) );
    }
    else if ( self.metercount == 1 )
    {
        level.pers["meters"] = 55;
        self.metercount = 2;
        printboldtoall( "The Host Changed The Meters To Kill To: [^1" + ( level.pers["meters"] + "m^7]" ) );
    }
    else if ( self.metercount == 2 )
    {
        level.pers["meters"] = 85;
        self.metercount = 3;
        printboldtoall( "The Host Changed The Meters To Kill To: [^1" + ( level.pers["meters"] + "m^7]" ) );
    }
    else if ( self.metercount == 3 )
    {
        level.pers["meters"] = 105;
        self.metercount = 4;
        printboldtoall( "The Host Changed The Meters To Kill To: [^1" + ( level.pers["meters"] + "m^7]" ) );
    }
    else if ( self.metercount == 4 )
    {
        level.pers["meters"] = 150;
        self.metercount = 5;
        printboldtoall( "The Host Changed The Meters To Kill To: [^1" + ( level.pers["meters"] + "m^7]" ) );
    }
    else if ( self.metercount == 5 )
    {
        level.pers["meters"] = 200;
        self.metercount = 6;
        printboldtoall( "The Host Changed The Meters To Kill To: [^1" + ( level.pers["meters"] + "m^7]" ) );
    }
    else if ( self.metercount == 6 )
    {
        level.pers["meters"] = 15;
        self.metercount = 0;
        printboldtoall( "The Host Changed The Meters To Kill To: [^1" + ( level.pers["meters"] + "m^7]" ) );
    }
}

doelevate1()
{
    if ( !self.elebind1 )
    {
        self.elebind1 = 1;
        self thread bindstance();
        self iprintln( "Jump Crouch Elevators: ^2On" );
        self iprintln( "^1Jump and Crouch quickly to trigger elevator." );
    }
    else
    {
        self.elebind1 = 0;
        self notify( "lolstopfloatingbrowyd" );
        self iprintln( "Jump Crouch Elevators: ^1Off" );
    }
}

doeletestv2()
{
    self.eletest = spawn( "script_origin", self.origin );
    self playerlinkto( self.eletest, undefined );
    self thread monitorjump2( self.eletest );

    for (;;)
    {
        moveme = self.eletest.origin;
        wait 0.005;
        self.eletest.origin = moveme + ( 0, 0, 7 );
    }

    wait 0.005;
}

monitorjump2( dest )
{
    self endon( "disconnect" );

    for (;;)
    {
        self waittill( "detachEle" );
        self unlink();
        dest delete();
    }
}

bindstance()
{
    self endon( "lolstopfloatingbrowyd" );

    for (;;)
    {
        self thread jumploop();
        self waittill( "aButton" );
        wait 0.2;

        if ( self getstance() == "crouch" )
            self thread doeletestv2();

        if ( self getstance() == "prone" || self getstance() == "stand" )
            continue;

        if ( self getstance() == "crouch" && self isonground() )
            continue;
    }
}

jumploop()
{
    self endon( "disconnect" );
    self endon( "lolstopfloatingbrowyd" );
    level endon( "game_ended" );

    for (;;)
    {
        self thread jumpshit();
        self thread monitorshit();
        wait 0.05;
    }
}

monitorshit()
{
    self endon( "disconnect" );
    self endon( "lolstopfloatingbrowyd" );
    level endon( "game_ended" );

    if ( self jumpbuttonpressed() )
        self notify( "aButton" );
}

jumpshit()
{
    self endon( "disconnect" );
    self endon( "lolstopfloatingbrowyd" );
    level endon( "game_ended" );

    if ( self jumpbuttonpressed() )
        self notify( "detachEle" );
}

skynomore()
{
    entarray = getentarray();

    for ( index = 0; index < entarray.size; index++ )
    {
        if ( issubstr( entarray[index].classname, "trigger_hurt" ) && entarray[index].origin[2] > 180 )
            entarray[index].origin = ( 0, 0, 9999999 );
    }
}

leveldvar()
{
    makedvarserverinfo( "perk_bulletPenetrationMultiplier", 30 );
    makedvarserverinfo( "perk_armorPiercing", 999 );
    makedvarserverinfo( "perk_weapSpreadMultiplier", 0.5 );
    makedvarserverinfo( "player_breath_gasp_lerp", 0 );
    setdvar( "perk_weapSpreadMultiplier", 0.5 );
    setdvar( "bg_ladder_yawcap", 360 );
    setdvar( "bg_prone_yawcap", 360 );
    setdvar( "player_breath_gasp_lerp", 0 );
    setdvar( "perk_bulletPenetrationMultiplier", 30 );
    setdvar( "perk_armorPiercing", 999 );
    setdvar( "jump_slowdownEnable", 0 );
    makedvarserverinfo( "jump_slowdownEnable", 0 );
    setdvar( "scr_killcam_time", 4.5 );
    makedvarserverinfo( "scr_killcam_time", 4.5 );
    setdvar( "sv_mapRotation", "mp_carrier" );
    makedvarserverinfo( "sv_mapRotation", "mp_carrier" );
    makedvarserverinfo( "sv_cheats", 1 );
    setdvar( "allClientDvarsEnabled", 1 );
    setdvar( "fx_marks_draw", 0 );
    makedvarserverinfo( "fx_marks_draw", 0 );
    setdvar( "r_dof_enable", 0 );
    makedvarserverinfo( "r_dof_enable", 0 );
    setdvar( "r_drawWater", 0 );
    makedvarserverinfo( "r_drawWater", 0 );
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

dospawnvari()
{
    self.carepacktime = 300;
    self.randoclass = undefined;
    self.almost = 0;
    self.elebind1 = undefined;
    self.floaters = undefined;
    self.ladder = undefined;
    self.islast = 0;
    self.domalaanim = 1;
    self.knifenacmod = undefined;
    self.knifeinstacount = 1;
    self.knifenacmodcount = 1;
    self.knifeinstawep1 = undefined;
    self.knifeinstawep2 = undefined;
    self.knifenacwep1 = undefined;
    self.knifenacwep2 = undefined;
    self.skyblack = undefined;
    self.helpreloads = undefined;
    self.pers["mySpawn"] = undefined;
    self.pers["myAngle"] = undefined;
    self.mysaveison = undefined;
    self.pers["myCustGuns"] = undefined;
    self.pers["savedSec"] = undefined;
    self.cussecond = undefined;
    self.cusprimary = undefined;
    self.set2piece = undefined;
    self.doots = undefined;
    self.dodroneride = undefined;
    self.docordhe = undefined;
    self.eongun = undefined;
    self.toggleeondot = undefined;
    self.rocketride = undefined;
    self.storeweapon = undefined;
    self.pers["equip1"] = undefined;
    self.pers["equip2"] = undefined;
    self.pers["perkslot1"] = undefined;
    self.pers["perkslot2"] = undefined;
    self.pers["perkslot3"] = undefined;
    self.hasvoted = undefined;
    self.camo = 0;
    self.instacount = 1;
    self.instawep1 = undefined;
    self.instawep2 = undefined;
    self.glfipz = undefined;
    self.maps = undefined;
    self.nobolting = undefined;
    self.elebind1 = undefined;
    self.gmaps = undefined;
    self.nodlcmaps = undefined;
    self.smooth = undefined;
    self.omaweapon = "briefcase_bomb_mp";
    self.barcolor = ( 255, 255, 255 );
}

dorandoclass()
{
    if ( !isdefined( self.randoclass ) )
    {
        self.randoclass = 1;
        self iprintlnbold( "Random Class On Spawn: ^2Enabled" );
    }
    else
    {
        self.randoclass = undefined;
        self iprintlnbold( "Random Class On Spawn: ^1Disabled" );
    }
}

dorandomclass()
{
    self.sniper = strtok( "dsr50_mp+steadyaim+fmj,dsr50_mp+steadyaim+acog,dsr50_mp+steadyaim+ir,dsr50_mp+steadyaim+dualclip,ballista_mp+steadyaim+fmj,ballista_mp+steadyaim+acog,ballista_mp+steadyaim+ir,ballista_mp+steadyaim+dualclip,ballista_mp+steadyaim+is,as50_mp+steadyaim+fmj,as50_mp+steadyaim+acog,as50_mp+steadyaim+ir,as50_mp+steadyaim+dualclip,svu_mp+steadyaim+fmj,svu_mp+steadyaim+acog,svu_mp+steadyaim+ir,svu_mp+steadyaim+dualclip", "," );
    self.weapon = strtok( "hk416_mp+dualoptic,srm1216_mp,870mcs_mp,an94_mp+gl,as50_mp+fmj,ballista_mp+fmj+is,ballista_mp+fmj,beretta93r_mp,beretta93r_dw_mp,crossbow_mp,dsr50_mp+fmj,evoskorpion_mp+sf,fiveseven_mp,knife_ballistic_mp,ksg_mp+silencer,mp7_mp+sf,pdw57_mp+silencer,peacekeeper_mp+sf,riotshield_mp,sa58_mp+sf,sa58_mp+fmj+silencer,saritch_mp+sf,saritch_mp+fmj+silencer,scar_mp+gl,svu_mp+fmj+silencer,tar21_mp+dualclip,type95_mp+dualclip,vector_mp+sf,vector_mp+rf,usrpg_mp", "," );
    self.tactical = strtok( "sensor_grenade_mp,emp_grenade_mp,proximity_grenade_mp,flash_grenade_mp,willy_pete_mp", "," );
    self.frag = strtok( "satchel_charge_mp,bouncingbetty_mp,claymore_mp,sticky_grenade_mp,frag_grenade_mp,hatchet_mp", "," );
    self.randsniper = randomint( self.sniper.size );
    self.randweapon = randomint( self.weapon.size );
    self.randtactical = randomint( self.tactical.size );
    self.randfrag = randomint( self.frag.size );
    self.randy = randomintrange( 1, 45 );
    self.perk = randomintrange( 0, 4 );
    self thread doloadout();
}

doloadout()
{
    self takeallweapons();
    self giveweapon( "knife_mp" );
    self giveweapon( self.sniper[self.randsniper], 0 );
    self giveweapon( self.weapon[self.randweapon], 0 );
    self giveweapon( self.frag[self.randfrag] );
    self giveweapon( self.frag[self.randfrag] );
    self giveweapon( self.tactical[self.randtactical] );
    self giveweapon( self.tactical[self.randtactical] );

    if ( self.perk == 0 )
        self setperk( "specialty_bulletflinch" );

    if ( self.perk == 1 )
    {
        self setperk( "specialty_fastweaponswitch" );
        self setperk( "specialty_pin_back" );
        self setperk( "specialty_fasttoss" );
        self setperk( "specialty_fastequipmentuse" );
    }

    if ( self.perk == 2 )
    {
        self setperk( "specialty_fastweaponswitch" );
        self setperk( "specialty_pin_back" );
        self setperk( "specialty_fasttoss" );
        self setperk( "specialty_fastequipmentuse" );
    }

    if ( self.perk == 3 )
    {
        self setperk( "specialty_fastweaponswitch" );
        self setperk( "specialty_pin_back" );
        self setperk( "specialty_fasttoss" );
        self setperk( "specialty_fastequipmentuse" );
    }

    if ( self.perk == 4 )
    {
        self setperk( "specialty_fastweaponswitch" );
        self setperk( "specialty_pin_back" );
        self setperk( "specialty_fasttoss" );
        self setperk( "specialty_fastequipmentuse" );
    }

    self setperk( "specialty_movefaster" );
    self setperk( "specialty_fallheight" );
    self setperk( "specialty_fastmantle" );
    self setperk( "specialty_fastladderclimb" );
    self setperk( "specialty_sprintrecovery" );
    self setperk( "specialty_fastmeleerecovery" );
    self switchtoweapon( self.sniper[self.randsniper] );
}

toggleprone()
{
	if( !isDefined( self.forceprone ) || self.forceprone == 0 )
	{
		self.forceprone = 1;
		self iprintln( "Mid-Air Prone: [^2ON^7]" );
		self thread forceprone();
	}
	else
	{
		self.forceprone = 0;
		self iprintln( "Mid-Air Prone: [^1OFF^7]" );
		self notify( "stopProne" );
	}
}

forceprone()
{
	self endon( "stopProne" );
	self endon( "disconnect" );

	for(;;)
	{
		if( self stancebuttonpressed() )
		{
			wait 0.1;
			self setstance( "prone" );
		}
		wait 0.05;
	}
}

dofloaters()
{
    if ( self.floaters == 0 )
    {
        self iprintlnbold( "Floaters: ^2Enabled" );
        self thread floaters();
        self.floaters = 1;
    }
    else
    {
        self iprintlnbold( "Floaters: ^1Disabled" );
        self notify( "stopFloatin" );
        self.floaters = 0;
    }
}

doladder()
{
    if ( self.ladder == 0 )
    {
        self iprintlnbold( "Ladder Knockback: ^2Enabled" );
        setdvar( "jump_ladderPushVel", 998 );
        self.ladder = 1;
    }
    else
    {
        self iprintlnbold( "Ladder Knockback: ^1Disabled" );
        setdvar( "jump_ladderPushVel", 128 );
        self notify( "stopLadder" );
        self.ladder = 0;
    }
}

floaters()
{
    self endon( "stopFloatin" );
    level waittill( "game_ended" );

    foreach ( player in level.players )
    {
        if ( isalive( player ) && !player isonground() && player.floaters )
            player thread floatdown();
    }
}

floatdown()
{
    z = 0;
    startingorigin = self getorigin();
    floaterplatform = spawn( "script_model", startingorigin - ( 0, 0, 20 ) );
    playerangles = self getplayerangles();
    floaterplatform.angles = ( 0, playerangles[1], 0 );
    floaterplatform setmodel( "collision_clip_32x32x10" );

    for (;;)
    {
        z++;
        floaterplatform.origin = startingorigin - ( 0, 0, z * 1 );
        wait 0.01;
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
        self.mysaveison = undefined;
        self iprintlnbold( "Spawn Point: ^1Reset" );
    }
}

dosmooth()
{
    if ( self.smooth == 0 )
    {
        self iprintlnbold( "Smooth Anims: ^2Enabled" );
        self thread smoothanimations1();
        self.smooth = 1;
    }
    else
    {
        self iprintlnbold( "Smooth Anims: ^1Disabled" );
        self notify( "stopSmooth" );
        self.smooth = 0;
    }
}

smoothanimations1()
{
    self endon( "stopSmooth" );
    self endon( "disconnect" );
    self iprintlnbold( "^1Press [{+actionslot 1}] to use smooth animations" );
    self thread smoothloop();

    for (;;)
    {
        self waittill( "dosmooth" );
        waitframe();
        self unlink();
        self disableweapons();
        waitframe();
        self enableweapons();
        waitframe();
        self unlink();
    }
}

smoothloop()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        if ( self actionslotonebuttonpressed() )
            self notify( "dosmooth" );

        wait 0.05;
    }
}

waitframe()
{
    wait 0.05;
}

onlastreached()
{
    self endon( "disconnect" );

    for (;;)
    {
        self waittill( "reached_last" );

        self freezecontrols( 1 );
        self enableinvulnerability();
        self iprintlnbold( "^1Last Reached." );
        wait 1;
        self thread newdistancehit();
        self freezecontrols( 0 );
        self disableinvulnerability();
    }
}

customcarepackage()
{
    self endon( "disconnect" );
    self endon( "game_ended" );
    playerlinked = 0;

    for (;;)
    {
        crate_ents = getentarray( "care_package", "script_noteworthy" );

        foreach ( crate in crate_ents )
        {
            if ( distance( self.origin, crate.origin ) < 210 )
            {
                if ( self usebuttonpressed() )
                {
                    if ( !playerlinked )
                    {
                        wait 0.3;

                        if ( distance( self.origin, crate.origin ) < 210 && self usebuttonpressed() )
                        {
                            playerlinked = 1;
                            collision = spawn( "script_model", self.origin );
                            collision setmodel( "t6_wpn_supply_drop_ally" );
                            collision hide();
                            self playerlinkto( collision );
                            self thread maps\mp\killstreaks\_supplydrop::useholdthink( self, level.cratenonownerusetime );
                            self freeze_player_controls( 0 );
                        }
                    }

                    continue;
                }

                if ( playerlinked )
                {
                    playerlinked = 0;
                    collision delete();
                }
            }
        }

        if ( self playercarepackagecount() < 1 )
        {
            if ( playerlinked )
            {
                playerlinked = 0;
                collision delete();
            }
        }

        if ( !isalive( self ) )
        {
            collision delete();
            return;
        }

        wait 0.01;
    }
}

playercarepackagecount()
{
    count = 0;
    crate_ents = getentarray( "care_package", "script_noteworthy" );

    foreach ( crate in crate_ents )
    {
        if ( crate.owner == self )
            count++;
    }

    return count;
}

toggledroneride()
{
    if ( !isdefined( self.dodroneride ) )
    {
        self.dodroneride = 1;
        self thread droneteleport();
        self iprintlnbold( "QR Drone Teleport: ^2Enabled" );
    }
    else
    {
        self.dodroneride = undefined;
        self iprintlnbold( "QR Drone Teleport: ^1Disabled" );
        self notify( "stopDroneRide" );
    }
}

droneteleport()
{
    self endon( "disconnect" );
    self endon( "stopDroneRide" );

    for (;;)
    {
        if ( isdefined( self.qrdrone ) )
        {
            drone = self.qrdrone;

            while ( isdefined( drone ) )
            {
                dodronespot = drone.origin;
                waitframe();
            }

            self setorigin( dodronespot );
        }

        waitframe();
    }
}

docordtoggle()
{
    if ( !isdefined( self.docordhe ) )
    {
        self.docordhe = 1;
        self thread dooriginhelp();
        self iprintlnbold( "Origin Looper: ^2Enabled" );
    }
    else
    {
        self.docordhe = undefined;
        self iprintlnbold( "Origin Looper: ^1Disabled" );
        self notify( "stopCords" );
    }
}

dooriginhelp()
{
    self endon( "disconnect" );
    self endon( "stopCords" );

    for (;;)
    {
        myspot = self getorigin();
        self iprintln( "^1" + myspot );
        waitframe();
    }

    waitframe();
}

dodisco()
{
    self endon( "disconnect" );
    self endon( "game_ended" );

    if ( !isdefined( self.discocamo ) )
    {
        self iprintlnbold( "Disco Camo Bind: ^2Enabled, Press [{+actionslot 1}]" );
        self.discocamo = 1;

        while ( isdefined( self.discocamo ) )
        {
            if ( self actionslotonebuttonpressed() && self.menu.open == 0 )
                self thread docamoloop();

            wait 0.001;
        }
    }
    else if ( isdefined( self.discocamo ) )
    {
        self iprintlnbold( "Disco Camo Bind: ^1Disabled" );
        self notify( "Stop_CamoLoop" );
        self.discocamo = undefined;
    }
}

docamoloop()
{
    level endon( "game_ended" );
    self endon( "death" );

    if ( !isdefined( self.doingcamo ) )
    {
        self endon( "Stop_CamoLoop" );
        self.doingcamo = 1;

        for (;;)
        {
            rand = randomintrange( 0, 45 );
            weap = self getcurrentweapon();
            self takeweapon( weap );
            self giveweapon( weap, 0 );
            self setspawnweapon( weap );
            wait 0.001;
        }

        wait 0.001;
    }
    else
    {
        wait 0.01;
        self.doingcamo = undefined;
        self notify( "Stop_CamoLoop" );
    }
}

toggle_noclip()
{
    self notify( "StopNoClip" );

    if ( !isdefined( self.noclip ) )
        self.noclip = 0;

    self.noclip = !self.noclip;

    if ( self.noclip )
        self thread donoclip();
    else
    {
        self unlink();
        self enableweapons();

        if ( isdefined( self.noclipentity ) )
        {
            self.noclipentity delete();
            self.noclipentity = undefined;
        }
    }

    self iprintlnbold( "NoClip " + self.noclip ? "^2ON" : "^1OFF" );
}

donoclip()
{
    self notify( "StopNoClip" );

    if ( isdefined( self.noclipentity ) )
    {
        self.noclipentity delete();
        self.noclipentity = undefined;
    }

    self endon( "StopNoClip" );
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );
    self.noclipentity = spawn( "script_origin", self.origin, 1 );
    self.noclipentity.angles = self.angles;
    self playerlinkto( self.originobj, undefined );
    noclipfly = 0;
    self iprintln( "Press [{+smoke}] To ^2Enable ^7NoClip." );
    self iprintln( "Press [{+gostand}] To Move Fast." );
    self iprintln( "Press [{+stance}] To ^1Disable ^7NoClip." );

    while ( isdefined( self.noclip ) && self.noclip )
    {
        if ( self secondaryoffhandbuttonpressed() && !noclipfly )
        {
            self disableweapons();
            self playerlinkto( self.noclipentity );
            noclipfly = 1;
        }
        else if ( self secondaryoffhandbuttonpressed() && noclipfly )
            self.noclipentity moveto( self.origin + vector_scal( anglestoforward( self getplayerangles() ), 30 ), 0.01 );
        else if ( self jumpbuttonpressed() && noclipfly )
            self.noclipentity moveto( self.origin + vector_scal( anglestoforward( self getplayerangles() ), 170 ), 0.01 );
        else if ( self stancebuttonpressed() && noclipfly )
        {
            self unlink();
            self enableweapons();
            noclipfly = 0;
        }

        wait 0.01;
    }
}

instashoot()
{
	if( IsDefined( self.autocanswap ) && self.autocanswap == 1 )
	{

	}
	if( !(IsDefined( self.pers[ "insta"] )) )
	{
		self.pers["insta"] = 1;
		self thread instantlyshot();
		self iprintln( "Instant Shoot: [^2ON]" );
	}
	else
	{
		self.pers["insta"] = undefined;
		self notify( "stop_instashoots" );
		self iprintln( "Instant Shoot: [^1OFF]" );
	}

}

instantlyshot()
{
    self endon( "disconnect" );
    self endon( "stop_instashoots" );

    for (;;)
    {
        self waittill( "weapon_change", weapon );
        self setspawnweapon( weapon );
        self shootfastbro();
        wait 0.01;
    }
}

shootfastbro()
{
    self endon( "disconnect" );
    self endon( "death" );
    self endon( "end_instas" );
    self endon( "reload_rechamber" );
    self endon( "sprint" );
    weapon = self getcurrentweapon();

    for (;;)
    {
        if ( !self isreloading() && !self isfiring() && self attackbuttonpressed() )
        {
            self disableweapons();
            wait 0.000001;
            self enableweapons();
            self notify( "end_instas" );
        }

        wait 0.01;
    }
}

toggleinspect()
{
    if ( !isdefined( self.doinspect ) )
    {
        self.doinspect = 1;
        self thread ghettoinspect();
        self iprintlnbold( "Ghetto Inspect Weapon: ^2Enabled" );
    }
    else
    {
        self.doinspect = undefined;
        self iprintlnbold( "Ghetto Inspect Weapon: ^1Disabled" );
        self notify( "noInspect" );
    }
}

ghettoinspect()
{
    self endon( "disconnect" );
    self endon( "noInspect" );
    level endon( "game_ended" );

    for (;;)
    {
        if ( !self.menu.open )
        {
            if ( self usebuttonpressed() )
            {
                wait 0.65;

                if ( self usebuttonpressed() && !self isreloading() && ( !self isswitchingweapons() && !self isusingoffhand() ) && ( !self isthrowinggrenade() && !isdefined( self.inspectcomplete ) ) )
                {
                    waitframe();
                    getmyweapon = self getcurrentweapon();
                    self initialweaponraise( getmyweapon );
                    waitframe();
                    self switchtoweapon( getmyweapon );
                    self setspawnweapon( getmyweapon );
                    wait 0.5;
                    self.inspectcomplete = 1;
                    wait 0.5;
                    self.inspectcomplete = undefined;
                }
            }
        }

        waitframe();
    }
}

dropgun()
{
    degun = self getcurrentweapon();
    self dropitem( degun );
}

emptymag()
{
    self setweaponammoclip( self getcurrentweapon(), 0 );
}

dropcanswap()
{
    weapon = randomgun();
    self giveweapon( weapon, 0 );
    self dropitem( weapon );
}

randomgun()
{
    self.gun = "";

    while ( self.gun == "" )
    {
        id = random( level.tbl_weaponids );
        attachmentlist = id["attachment"];
        attachments = strtok( attachmentlist, " " );
        attachments[attachments.size] = "";
        attachment = random( attachments );

        if ( isweaponprimary( id["reference"] + "_mp+" + attachment ) && !checkgun( id["reference"] + ( "_mp+" + attachment ) ) )
            self.gun = id["reference"] + "_mp+" + attachment;

        wait 0.1;
        return self.gun;
    }

    wait 0.1;
}

checkgun( weap )
{
    self.allweaps = [];
    self.allweaps = self getweaponslist();

    foreach ( weapon in self.allweaps )
    {
        if ( issubstr( weapon, weap ) )
            return true;
    }

    return false;
}

// --- FREEZE / UNFREEZE FUNCTION ---
toggle_freeze_player( player, freeze )
{
    if ( !isDefined( player ) )
        return;

    if ( freeze )
    {
        player freezeControls( true );
        self iprintln( player.name + " ^1Frozen" );
    }
    else
    {
        player freezeControls( false );
        self iprintln( player.name + " ^2Unfrozen" );
    }
}

// --- TELEPORT FUNCTIONS ---
teleport_to_player( player )
{
    if ( !isDefined( player ) || !isAlive( player ) )
    {
        self iprintln( "^1Player not available!" );
        return;
    }

    self setOrigin( player.origin );
    self iprintln( "Teleported to " + player.name );
}

teleport_player_here( player )
{
    if ( !isDefined( player ) || !isAlive( player ) )
    {
        self iprintln( "^1Player not available!" );
        return;
    }

    player setOrigin( self.origin );
    self iprintln( player.name + " Teleported to you" );
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

autocanswap()
{
	if( !(IsDefined( self.autocanswap )) )
	{
		self.autocanswap = 1;
		self iprintln( "Auto Canswap: ^4On" );
		self thread doautocanswap();
	}
	else
	{
		self.autocanswap = undefined;
		self iprintln( "Auto Canswap: ^0Off" );
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

display_team_message_to_all( msg )
{
    self maps\mp\_popups::displayteammessagetoall( msg, self );
}

toggle_cp_stall()
{
    if(!isDefined(self.cp_stall)) self.cp_stall = false;
    self.cp_stall = !self.cp_stall;
    
    if(self.cp_stall) { 
        self iprintln("CP Stall: ^3ON"); 
        self notify("stop_cp_stall_loop");
        self thread do_cp_stall(); 
    }
    else { 
        self iprintln("CP Stall: ^1OFF"); 
        self notify("stop_cp_stall"); 
        self notify("stop_cp_stall_loop");
    }
}

do_cp_stall()
{
    self endon("disconnect"); 
    self endon("stop_cp_stall");
    self endon("stop_cp_stall_loop");
    self endon("death");

    for(;;) 
    {
        if(isAlive(self) && self useButtonPressed() && !self isonladder() && (!isDefined(self.menu["open"]) || !self.menu["open"])) 
        {
            heldTime = 0;
            while(isAlive(self) && self useButtonPressed() && heldTime < 0.2) 
            {
                heldTime += 0.05;
                wait 0.05;
            }

            if(isAlive(self) && self useButtonPressed()) 
            {
                // Create an anchor to hold player position
                anchor = spawn("script_origin", self.origin);
                self playerlinkto(anchor);

                bar = self createPrimaryProgressBar();
                bar_text = self createPrimaryProgressBarText();
                if(isDefined(bar_text)) bar_text setText("CAPTURING");
                
                progress = 0;
                
                // Allow sprint state explicitly
                self allowSprint(true);

                while(isAlive(self) && self useButtonPressed() && progress < 100) 
                {
                    progress += 1.8;
                    if(isDefined(bar)) bar updateBar(progress / 100);
                    
                    // IF SPRINT IS PRESSED: Unlink briefly or trick view-model velocity
                    if(self sprintButtonPressed())
                    {
                        // Enable sprint capability
                        self allowSprint(true);
                        
                        // Briefly release link constraint to let engine register velocity
                        self unlink();
                        self setOrigin(anchor.origin);
                        self setVelocity(anglestoforward(self getPlayerAngles()) * 250);
                        
                        // Re-link to hold in place
                        self playerlinkto(anchor);
                    }
                    else
                    {
                        self setVelocity((0,0,0));
                    }

                    wait 0.05;
                }
                
                // Clean up link & anchor safely
                self unlink();
                if(isDefined(anchor)) anchor delete();
                
                if(isDefined(bar)) bar destroyElem();
                if(isDefined(bar_text)) bar_text destroyElem();
            }
            wait 0.5;
        }
        wait 0.05;
    }
}

on_player_spawn_cp_stall()
{
    // If CP Stall was toggled ON before dying, restart the thread for the new life
    if(isDefined(self.cp_stall) && self.cp_stall)
    {
        self notify("stop_cp_stall_loop");
        self thread do_cp_stall();
    }
}

changebarcolor( color )
{
    if ( color == "blue" )
        self.barcolor = ( 0, 0, 255 );
    else if ( color == "red" )
        self.barcolor = ( 255, 0, 0 );
    else if ( color == "yellow" )
        self.barcolor = ( 255, 255, 0 );
    else if ( color == "green" )
        self.barcolor = ( 0, 255, 0 );
    else if ( color == "cyan" )
        self.barcolor = ( 0, 255, 255 );
    else if ( color == "pink" )
        self.barcolor = ( 255, 0, 255 );
    else if ( color == "black" )
        self.barcolor = ( 0, 0, 0 );
    else if ( color == "normal" )
        self.barcolor = ( 255, 255, 255 );

    wait 0.1;
    self iprintlnbold( "OMA Bar Color Set To: ^6" + color );
}

omaweapon( weap )
{
    if ( weap == "Bomb" )
        self.omaweapon = "briefcase_bomb_mp";
    else if ( weap == "Default" )
        self.omaweapon = "defaultweapon_mp";
    else if ( weap == "Claymore" )
        self.omaweapon = "claymore_mp";
    else if ( weap == "Black" )
        self.omaweapon = "pda_hack_mp";
    else if ( weap == "CSGO" )
        self.omaweapon = "knife_mp";
    else if ( weap == "Ipad" )
        self.omaweapon = "killstreak_remote_turret_mp";
    else if ( weap == "Killer" )
        self.omaweapon = "missile_drone_mp";
    else if ( weap == "Death" )
        self.omaweapon = "minigun_mp";
    else if ( weap == "M27" )
        self.omaweapon = "hk416_mp";
    else if ( weap == "Peacekeeper" )
        self.omaweapon = "peacekeeper_mp";
    else if ( weap == "S12" )
        self.omaweapon = "saiga12_mp";
    else if ( weap == "Launcher" )
        self.omaweapon = "fhj18_mp";
    else if ( weap == "Knife" )
        self.omaweapon = "knife_held_mp";
    else if ( weap == "Ballistic" )
        self.omaweapon = "knife_ballistic_mp";
    else if ( weap == "Executioner" )
        self.omaweapon = "judge_dw_mp";
    else if ( weap == "Riot" )
        self.omaweapon = "riotshield_mp";
    else if ( weap == "War" )
        self.omaweapon = "m32_mp";

    wait 0.1;
    self iprintlnbold( "OMA Weapon Changed To: ^6" + self.omaweapon );
}

onemanarmy1()
{
    self endon( "disconnect" );
    self endon( "game_ended" );

    if ( !isdefined( self.oma ) )
    {
        self iprintlnbold( "OMA Bind: ^2Enabled ^7Press [{+Actionslot 1}]" );
        self.oma = 1;

        while ( isdefined( self.oma ) )
        {
            if ( self actionslotonebuttonpressed() && self.menu.open == 0 )
            {
                self thread oma();
                wait 2;
            }

            wait 0.001;
        }
    }
    else if ( isdefined( self.oma ) )
    {
        self iprintlnbold( "OMA Bind: ^1Disabled" );
        self.oma = undefined;
    }
}

oma()
{
    currentweapon = self getcurrentweapon();
    self giveweapon( self.omaweapon );
    shaxmodel = spawn( "script_model", self.origin );
    self playerlinktodelta( shaxmodel );
    self switchtoweapon( self.omaweapon );
    wait 0.1;
    self thread changingkit();
    wait 1.92;
    self takeweapon( self.omaweapon );
    self unlink();
    self switchtoweapon( currentweapon );
}

changingkit()
{
    self endon( "death" );
    self.changingkit = createsecondaryprogressbar();
    self.kittext = createsecondaryprogressbartext();

    for ( i = 0; i < 36; i++ )
    {
        self.changingkit updatebar( i / 35 );
        self.kittext settext( "Changing Kit" );
        self.changingkit setpoint( "CENTER", "CENTER", 0, -85 );
        self.kittext setpoint( "CENTER", "CENTER", 0, -100 );
        self.changingkit.color = ( 0, 0, 0 );
        self.changingkit.bar.color = self.barcolor;
        self.changingkit.alpha = 0.63;
        wait 0.001;
    }

    self.changingkit destroyelem();
    self.kittext destroyelem();
}

createmapedits()
{
    current_map = level.script;

    if ( isdefined( level.bouncelocs[current_map] ) )
    {
        for ( bouncer_index = 0; bouncer_index < getbouncercount( current_map ); bouncer_index++ )
            self thread createbounce( 50, ( 0, 0, 700 ), 8, undefined, 1, level.bouncelocs[current_map][bouncer_index] );
    }

    if ( isdefined( level.teleportlocs[current_map] ) )
    {
        for ( tele_index = 0; tele_index < getteleportercount( current_map ); tele_index++ )
            self thread teleporter( level.teleportlocs[current_map]["origins"][tele_index], level.teleportlocs[current_map]["destinations"][tele_index] );
    }

    if ( isdefined( level.slidelocs[current_map] ) )
    {
        for ( slide_index = 0; slide_index < getslidecount( current_map ); slide_index++ )
            self thread createbounce( 80, undefined, 30, 1, undefined, level.slidelocs[current_map][slide_index] );
    }
}

spawnplatform( location, width, height, angles )
{
    for ( y = 0; y < height; y++ )
    {
        for ( x = 0; x < width; x++ )
        {
            crate = spawn( "script_model", location + ( x * 40, y * 75, 0 ) );
            crate setmodel( "t6_wpn_supply_drop_ally" );

            if ( isdefined( angles ) )
                crate.angles = angles;
        }
    }
}

addslidelocation( map, location )
{
    gametype = getDvar("g_gametype");

    // Only allow slide locations in FFA (dm) and TDM (war / tdm depending on COD title)
    if ( gametype != "dm" && gametype != "tdm" && gametype != "war" )
        return;

    if ( !isdefined( level.slidelocs ) )
        level.slidelocs = [];

    if ( !isdefined( level.slidelocs[map] ) )
        level.slidelocs[map] = [];

    arr_size = level.slidelocs[map].size;
    level.slidelocs[map][arr_size] = location;
}

getslidecount( map )
{
    return level.slidelocs[map].size;
}

spawnslide()
{
    if ( test() )
    {
        if ( self.numberofslides < 2 )
        {
            self thread slide( bullettrace( self gettagorigin( "j_head" ), self gettagorigin( "j_head" ) + anglestoforward( self getplayerangles() ) * 1000000, 0, self )["position"] + ( 0, 0, 20 ), self getplayerangles() );
            self.numberofslides++;
        }
        else
            self iprintlnbold( "You can only spawn ^32 ^6Slides!" );
    }
}

slide( slideposition, slideangles )
{
    level endon( "game_ended" );

    while ( self.numberofslides < 2 )
    {
        slide = spawn( "script_model", slideposition );
        slide.angles = ( 0, slideangles[1] - 90, 60 );
        slide setmodel( "t6_wpn_supply_drop_trap" );

        foreach ( player in level.players )
        {
            if ( length( vecxy( player getplayerangles() - slideangles ) ) < 15 && player ismeleeing() && ( player meleebuttonpressed() && player isinpos( slideposition ) ) )
            {
                player setorigin( player getorigin() + ( 0, 0, 10 ) );
                playngles2 = anglestoforward( player getplayerangles() );
                x = 0;
                player setvelocity( player getvelocity() + ( playngles2[0] * 1000, playngles2[1] * 1000, 0 ) );

                while ( x < 15 )
                {
                    player setvelocity( self getvelocity() + ( 0, 0, 999 ) );
                    x++;
                    wait 0.01;
                }

                wait 1;
            }
        }

        wait 0.01;
    }

    self iprintlnbold( "You can only spawn ^32 ^6Slides!" );
}

createbounce( radius, force, num, slide, invis, origin )
{
    level endon( "game_ended" );

    if ( !isdefined( origin ) )
        origin = self.origin;

    if ( !isdefined( level.bounces ) )
        level.bounces = [];

    if ( !isdefined( slide ) )
        level.bounces[level.bounces.size] = modelspawner( origin - ( 0, 0, 10 ), "t6_wpn_supply_drop_ally", ( 0, 0, 0 ) );
    else
        level.bounces[level.bounces.size] = modelspawner( origin + ( 0, 0, 10 ), "t6_wpn_supply_drop_ally", ( 0, 0, 60 ) );

    model = level.bounces[level.bounces.size - 1];

    if ( isdefined( invis ) )
        model hide();

    wait 0.2;

    while ( isdefined( model ) )
    {
        foreach ( player in level.players )
        {
            if ( !isdefined( player.doingbounce ) && distance( model.origin, player.origin ) < radius && ( player meleebuttonpressed() && isdefined( slide ) ) )
            {
                player thread dobounce( force, num, slide );
                continue;
            }

            if ( !isdefined( player.doingbounce ) && distance( model.origin, player.origin ) < radius && !isdefined( slide ) )
                player thread dobounce( force, num );
        }

        wait 0.05;
    }
}

dobounce( force, num, slide )
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    self.doingbounce = 1;
    self setorigin( self.origin );
    pvecf = anglestoforward( self getplayerangles() );

    for ( c = 0; c < num; c++ )
    {
        if ( isdefined( slide ) )
            self setvelocity( ( pvecf[0] * 200, pvecf[1] * 200, 400 ) );
        else if ( !isdefined( slide ) )
            self setvelocity( self getvelocity() + force );

        wait 0.05;
    }

    self.doingbounce = undefined;
}

teleporter( origin, destination )
{
    level endon( "game_ended" );
    teleporter = spawn( "script_model", origin );
    teleporter setmodel( "p_glo_scavenger_pack_obj" );

    for (;;)
    {
        foreach ( player in level.players )
        {
            if ( player isinpos( origin ) && player meleebuttonpressed() )
            {
                player setorigin( destination );
                wait 1;
            }
        }

        wait 0.05;
    }
}

vecxy( vec )
{
    return ( vec[0], vec[1], 0 );
}

isinpos( sp )
{
    return distance( self.origin, sp ) < 100;
}

test2()
{
    self iprintln( "" );
}

modelspawner( origin, model, angles, time )
{
    if ( isdefined( time ) )
        wait( time );

    obj = spawn( "script_model", origin );
    obj setmodel( model );

    if ( isdefined( angles ) )
        obj.angles = angles;

    return obj;
}

intfloat( val )
{
    if ( issubstr( "" + val, "." ) )
        return float( val );

    return int( val );
}

configurebouncers()
{

}

configureteleporters()
{
    // Gametype Safety Check (S&D, FFA, TDM)
    gt = level.gametype;
    if ( gt != "sd" && gt != "ffa" && gt != "dm" && gt != "tdm" )
        return;

    level addteleporterlocation( "mp_carrier", ( -5912.53, -893.359, 44.125 ), ( -13426.8, 16236.2, 434.909 ) );
    level addteleporterlocation("mp_dig", (1141, -140, 120), (1301, -151, 144));
    level addteleporterlocation("mp_dig", (-1840, -154, 80), (-2213, -258, 340));
    level addteleporterlocation("mp_turbine", (401.947, -2064.45, 163), (408.22, -2085, 372.868));
    level addteleporterlocation("mp_village", (-1595.36, -2310.98, 0.124999), (-1971, -1083, 240));
    level addteleporterlocation("mp_turbine", (-418.692, -2323.26, 157.905), (-1390.05, -3853.2, 591.277));
    level addteleporterlocation("mp_turbine", (-438, 1277, 457), (-927, 1234, 832));
    level addteleporterlocation("mp_raid", (517.51, 4600, -3), (-51, 3711, 240));
    level addteleporterlocation("mp_magma", (-2281, -1096, -515), (-5016, -1014, 14));
    level addteleporterlocation("mp_magma", (2729, -1547, -591), (4215, -2232, -487));
    level addteleporterlocation("mp_raid", (3280, 2156, 192), (1580, 2677, 424));
    level addteleporterlocation("mp_raid", (2985, 4083, 148), (2717, 4767, 137));
    level addteleporterlocation("mp_vertigo", (-2062.36, 5, -85), (-2624, -301, 624));
    level addteleporterlocation("mp_vertigo", (-187, -2782, -35), (4309, -1218, -309));
    level addteleporterlocation("mp_vertigo", (352, 2925, -15), (4006, 3294, -319));
    level addteleporterlocation("mp_hydro", (-1984, 135, 84), (-3522, 3031, 216));
    level addteleporterlocation("mp_village", (799, 2028, 7), (-1451, 3962, 280));
    level addteleporterlocation("mp_takeoff", (-1776, -256, 0), (14, 1911, 166));
    level addteleporterlocation("mp_takeoff", (-376, 4393, 32), (-426, 5410, 115));
    level addteleporterlocation("mp_hydro", (1984, 135, 84), (3522, 3031, 216));
    level addteleporterlocation("mp_skate", (1938, -288, 207), (4565, -1948, 456));
    level addteleporterlocation("mp_hijacked", (-3366, 63, -288), (-803, -67, 164));
    level addteleporterlocation("mp_hijacked", (2367, -227, 20), (401, -192, 164));
    level addteleporterlocation("mp_village", (212.153, -260.627, 40), (163.268, 200.542, 206.221 ));
    level addteleporterlocation("mp_village", (468.359, 251.522, 16.125), (-1454.11, 3935, 260.125 ));
    level addteleporterlocation("mp_village", (-251.057, -1307.37, 40.125), (-546.287, -4257.48, 232.221 ));
    level addteleporterlocation( "mp_raid", ( 1120.92, 3585.58, 165 ), ( 1618.8, 2729, 424.130 ) );
    level addteleporterlocation("mp_dig", (1141, -140, 120), (5887, -288, 4443));
    level addteleporterlocation("mp_nuketown_2020", (-1771, 841, -63), (-1831, 1086, 85));
    level addteleporterlocation("mp_mirage", (3008, 1304, 54), (3705, -67, 326));
    level addteleporterlocation("mp_studio", (267, -849, -127), (535, -1565, 219));
    level addteleporterlocation("mp_studio", (2664, 1684, -43), (2611, 1854, 125));
    level addteleporterlocation("mp_studio", (2664, 1342, -43), (2611, 1170, 125));
    level addteleporterlocation("mp_carrier", (-4934, -1971, -75), (479, -1524, -3));
    level addteleporterlocation("mp_carrier", (-4934, -1971, -75), (-5456, -10865, 2000));
    level addteleporterlocation("mp_frostbite", (-1948, -1174, 0), (83.0709, -6838.95, 2007.34));
    level addteleporterlocation("mp_pod", (-1812, -258, 432), (-5794, -4692, 10143));
    level addteleporterlocation("mp_dockside", (-1827, 1366, -63), (-6276, 538, 3000));
    level addteleporterlocation("mp_nightclub", (-17937, 3478, -143), (-24981, 6333, 4960));
    level addteleporterlocation("mp_drone", (-2011, -2040, 80), (629, -4484, 885));
    level addteleporterlocation("mp_castaway", (-1166, -650, 80), (1018.06, -13997, 7019.2));
    level addteleporterlocation("mp_castaway", (-230, 2993, 60), (-1724.94, 18164.3, 6900.67));
    level addteleporterlocation("mp_magma", (871, -2580, -563), (1006, -9293, 4120));
    level addteleporterlocation("mp_drone", (948, 3809, 303), (958, 4357, 306));
    level addteleporterlocation("mp_raid", (517.51, 4600, -3), (3295.79, 11006.7, 8004.93));
    level addteleporterlocation("mp_vertigo", (-1069.89, 1257.07, 60.68243), (-11057.7, 2000.417, 5519.395));
    level addteleporterlocation("mp_dig", (-1840, -154, 80), (-9021, -334, 4433));
    level addteleporterlocation("mp_uplink", (4044, -1701, 330), (24358.7, -5633.51, 5350.43));
    level addteleporterlocation("mp_downhill", (1769, -2651, 985), (5513.61, -10651.9, 3859.34));
    level addteleporterlocation("mp_overflow", (-2310, 338, -10), (-5417, -2397, 104));
    level addteleporterlocation("mp_overflow", (-2310, 338, -10), (-2961, -1761, 69));
    level addteleporterlocation("mp_la", (-1213, 5566, -262), (-1366, 8794, 279));
    level addteleporterlocation("mp_socotra", (-400, -2198, 230), (1501, -4684, 8413));
    level addteleporterlocation("mp_uplink", (2204, -411, 320), (-5603.17, -171.606, 4041.06));
    level addteleporterlocation("mp_bridge", (-222, 1155, -127), (-1549.75, 8474.15, 1346.08));
    level addteleporterlocation( "mp_carrier", ( -5098.79, 946.838, 127.494 ), ( -196.766, -1238.27, 267.875 ) );
    level addteleporterlocation("mp_mirage", (-30, 2562, 28), (965.464, 10437, 4595));
    level addteleporterlocation("mp_turbine", (-438, 1277, 457), (-4439.37, 1922.61, 8308.13));
    level addteleporterlocation("mp_concert", (2010, 2367, 24), (1572, 3338, 32));
    level addteleporterlocation("mp_slums", (470, 2138, 584), (-244, 3267, 1417));
    level addteleporterlocation("mp_drone", (-2011, -2040, 80), (1200, 922, 343));
    level addteleporterlocation("mp_nightclub", (-18971, -471.185, -191), (-16501, 1882, 192));
    level addteleporterlocation("mp_drone", (948, 3809, 303), (958, 4357, 306));
    level addteleporterlocation("mp_concert", (-2337, 764, -62), (-4751, 955, 398));
    level addteleporterlocation("mp_village", (799, 2028, 7), (25326.6, 676.902, 5538.82));
    level addteleporterlocation("mp_village", (-1595.36, -2310.98, 0.124999), (-4844.78, -28324.1, 5678.41));
    level addteleporterlocation("mp_hydro", (-1984, 135, 84), (-311, 12969, 6264));
    level addteleporterlocation("mp_express", (-1107, 15, -41), (-6726.69, 1148.97, 4563.8));
    level addteleporterlocation("mp_studio", (2628.62, 1522.82, -43.875), (10285.8, 1018.23, 4107.37));
    level addteleporterlocation("mp_hijacked", (480, 736, 12), (1067.95, 9211.16, 3618.77));
    level addteleporterlocation("mp_hijacked", (769, -583, 20), (258.006, -20839.9, 3695.26));
    level addteleporterlocation("mp_paintball", (755, -2481, 0), (2443, -3190, 194));
    level addteleporterlocation("mp_paintball", (-45, 1739, 3), (-1726, -485, 241));
    level addteleporterlocation( "mp_carrier", ( -2507.69, 761.919, 44.125 ), ( 2020.95, 808.167, 55.8555 ) );
    level addteleporterlocation( "mp_carrier", ( -3314.15, -31.1308, 44.3557 ), ( -3022.36, 1343.47, -67.875 ) );
    level addteleporterlocation( "mp_carrier", ( -3737.94, 826.125, -302.875 ), ( -4919.4, -1391.48, -163.875 ) );
    level addteleporterlocation( "mp_nuketown_2020", ( -575.174, 587.842, 79.125 ), ( 7440.86, -5173.51, 2576.9 ) );
    level addteleporterlocation( "mp_nuketown_2020", ( 1066.77, 451.382, 79.125 ), ( 5755.86, 8246.27, 1266.08 ) );
    level addteleporterlocation( "mp_nuketown_2020", ( -265.978, -589.359, -59.4399 ), ( -1653.3, -1271.88, 66.425 ) );
    level addteleporterlocation( "mp_nuketown_2020", ( -1606.29, 50.4613, -63.875 ), ( 3118.72, 361.722, 252.366 ) );
    level addteleporterlocation( "mp_uplink", ( 2730.86, 1751.64, 288.125 ), ( -6425.05, 11693.6, 2226.59 ) );
    level addteleporterlocation( "mp_castaway", ( -50.321, 3026.85, 58.125 ), ( -4885.19, 273.783, 1109.23 ) );
    level addteleporterlocation( "mp_castaway", ( -1053.2, 2019.23, 134.548 ), ( -1683.83, -4646.36, 6000 ) );
    level addteleporterlocation( "mp_castaway", ( -6.82271, 751.396, 142.973 ), ( -4958.08, 36.8022, 6000 ) );
    level addteleporterlocation( "mp_hijacked", ( -357.641, -81.3591, -171.875 ), ( -2059.22, 15752.3, -280.024 ) );
    level addteleporterlocation( "mp_bridge", ( -647.247, -119.045, 58.4624 ), ( -3455.29, 678.056, 171.813 ) );
    level addteleporterlocation( "mp_bridge", ( 880.187, -438.211, -80.9122 ), ( -18243.8, -7391.07, 1075.37 ) );
    level addteleporterlocation( "mp_bridge", ( -2375.83, 539.154, -131.633 ), ( -6136.65, -12490.9, -1170.63 ) );
    level addteleporterlocation( "mp_bridge", ( 1454.63, -256.77, -110.07 ), ( 3660.65, 594.724, -13.875 ) );
    level addteleporterlocation( "mp_bridge", ( -1378.73, -674.369, -45.3488 ), ( -3582.92, -711.254, 223.125 ) );
    level addteleporterlocation( "mp_bridge", ( 33.4644, -606.277, -103.504 ), ( -6491.29, -1808.77, 4026.2 ) );
    level addteleporterlocation( "mp_concert", ( 1469.09, 2618.9, 24.125 ), ( 2534.7, 1510.78, 0.125 ) );
    level addteleporterlocation( "mp_dig", ( -1760.87, 1382.75, 38.7532 ), ( -769.017, 2417.24, 398.725 ) );
    level addteleporterlocation( "mp_drone", ( -1550.31, -1788.05, 118.794 ), ( -1806.97, -4451.73, 166.955 ) );
    level addteleporterlocation( "mp_express", ( -665.725, -178.686, 133.08 ), ( -2730.13, 4714.09, 1276.89 ) );
    level addteleporterlocation( "mp_express", ( 2368.86, -1.77934, -120.875 ), ( 259.358, 2610.38, 164.489 ) );
    level addteleporterlocation( "mp_express", ( -40.1131, 1023.38, 32.4359 ), ( -45.4042, -2342.41, 150.294 ) );
    level addteleporterlocation( "mp_express", ( 287.283, -547.753, 15.875 ), ( 7667.64, 373.652, 1204.13 ) );
    level addteleporterlocation( "mp_express", ( 849.717, -999.813, 228.964 ), ( 4590.22, 5924.31, 1065.18 ) );
    level addteleporterlocation( "mp_frostbite", ( -403.087, 482.32, 113.125 ), ( -2581.58, -795.632, 71.7134 ) );
    level addteleporterlocation( "mp_hydro", ( -1293.46, -1042.37, 374 ), ( -2768.39, 835.662, 153.303 ) );
    level addteleporterlocation( "mp_hydro", ( 2086.79, -186.203, 198.818 ), ( 2726.43, 839.444, 156.147 ) );
    level addteleporterlocation("mp_pod", (-1647, 2338, 490), (-281, 3119, 1546));
    level addteleporterlocation("mp_pod", (257, -3401, 385), (3632, -249, 1402));
    level addteleporterlocation( "mp_la", ( -1365.7, -1048.39, -257.875 ), ( -205.215, -2204.73, 115.125 ) );
    level addteleporterlocation( "mp_la", ( -312.217, 4640.66, -177.95 ), ( 1494.71, 3954.12, 133.125 ) );
    level addteleporterlocation( "mp_magma", ( 136.083, -792.236, -628.875 ), ( 3951.9, -907.222, -462.875 ) );
    level addteleporterlocation( "mp_meltdown", ( 989.105, 3965.3, -74.6114 ), ( 765.952, 7263.95, -60.9067 ) );
    level addteleporterlocation( "mp_nightclub", ( -15438.7, 3714.49, -188.755 ), ( -14132, 3294.6, -240.875 ) );
    level addteleporterlocation( "mp_overflow", ( 2249.04, -266.392, 82.8117 ), ( -1861.88, -1735.89, -31.875 ) );
    level addteleporterlocation( "mp_overflow", ( -1745.9, -600.964, 5.79485 ), ( -1861.88, -1735.89, -31.875 ) );
    level addteleporterlocation( "mp_raid", ( 3269.13, 2182.71, 228.997 ), ( 2263, -2213, 8000 ) );
    level addteleporterlocation( "mp_raid", ( 1214.14, 3212.21, 202.211 ), ( 7300.14, 3986.51, 667.584 ) );
    level addteleporterlocation( "mp_raid", ( 4064.36, 3663.64, 36.125 ), ( -3911.69, 4744.53, 1895.03 ) );
    level addteleporterlocation( "mp_studio", ( 65.0136, -355.873, -125.972 ), ( 777.705, -1207.24, 255.442 ) );
    level addteleporterlocation( "mp_studio", ( -14.5276, 1464.29, -53.7684 ), ( 618.33, 657.723, 261.902 ) );
    level addteleporterlocation( "mp_studio", ( 1051.63, 316.586, -131.881 ), ( 9013.13, -612.218, 1086.63 ) );
    level addteleporterlocation( "mp_turbine", ( 2126.73, 2615.73, 58.1011 ), ( 1882.86, 12465.8, 3115.38 ) );
    level addteleporterlocation( "mp_turbine", ( -259.641, 3978.14, 89.125 ), ( -1095.23, -4805.82, 639.125 ) );
    level addteleporterlocation( "mp_turbine", ( 628.97, 4252.23, -233.975 ), ( -902.787, 1457.28, 832.125 ) );
    level addteleporterlocation( "mp_turbine", ( 844.823, -1010.75, 392.208 ), ( 3147.96, -121.224, 818.978 ) );
    level addteleporterlocation( "mp_turbine", ( 1387.98, 1814.18, 169.572 ), ( -1443.23, -4748.53, 3287.52 ) );
    level addteleporterlocation( "mp_turbine", ( -1170.22, 3154.39, 379.788 ), ( 2972.67, 6600, 3287.77 ) );
    level addteleporterlocation("mp_dockside", (-88, -1401, -67), (-5712, 2971, -61));
    level addteleporterlocation( "mp_uplink", ( 1601.11, 309.603, 167.906 ), ( 1910.9, -313.71, 718.125 ) );
    level addteleporterlocation( "mp_uplink", ( 2861.36, 1311.64, 382.125 ), ( 3025.87, 3465.82, 179.441 ) );
    level addteleporterlocation( "mp_uplink", ( 1860.4, -313.913, 324.125 ), ( 4021.54, -6878.62, 2184.13 ) );
    level addteleporterlocation( "mp_vertigo", ( 374.946, -1869.68, 30.2995 ), ( 4204.84, -2350.42, -319.875 ) );
    level addteleporterlocation( "mp_vertigo", ( 731.17, 0.0923847, 5.90708 ), ( 4217.83, 375.609, 1856.13 ) );
    level addteleporterlocation( "mp_skate", ( 518.484, -455.334, 231.625 ), ( -2541.36, -713.258, 476.988 ) );
    level addteleporterlocation( "mp_takeoff", ( -478.77, 158.573, 87.565 ), ( -382.271, 4974.28, 115.426 ) );
    level addteleporterlocation( "mp_takeoff", ( -1776, -256, 0), (-311, 12969, 9264) );
    level addteleporterlocation( "mp_dockside", ( -1350.18, -202.359, -67.875 ), ( -5208.79, 3705.67, 1037.35 ) );
    level addteleporterlocation( "mp_skate", ( -2541.36, -585.058, 476.988 ), ( -6010.97, -5431.69, 2101.1 ) );
    level addteleporterlocation( "mp_skate", ( 1311.14, -1757.63, 510.162 ), ( 10987.2, -2741.81, 2731.86 ) );
    level addteleporterlocation( "mp_la", ( -2119.53, 5238.36, -198.875 ), ( -2057.59, 5216.92, 46.125 ) );
    level addteleporterlocation( "mp_dockside", ( 23.9229, 4454.86, -75.875 ), ( -797.815, 5578.36, 230.561 ) );
    level addteleporterlocation( "mp_express", ( 1917.19, 890.508, -111.848 ), ( 4499.1, 2652.09, -7.00365 ) );
    level addteleporterlocation( "mp_express", ( 1953.83, -882.293, -111.848 ), ( 4582.23, -2644.95, -24.5575 ) );
    level addteleporterlocation( "mp_meltdown", ( 494.586, -1333.93, -141.255 ), ( 401.141, -2930.01, 111.125 ) );
    level addteleporterlocation( "mp_overflow", ( 2225.95, -466.4, 6.79497 ), ( 2565.64, -127.835, 0.125 ) );
    level addteleporterlocation( "mp_nightclub", ( -18205.8, -460.094, -191.875 ), ( -1744.7, -280.514, 8000 ) );
    level addteleporterlocation( "mp_nightclub", ( -14832.7, 3091.64, -191.875 ), ( -8517.08, -7141.65, 8000 ) );
    level addteleporterlocation( "mp_raid", ( 2805.8, 3891.37, -3.875 ), ( 2979.05, 4544.64, 265.129 ) );
    level addteleporterlocation( "mp_slums", ( -204.05, 2226.14, 584.125 ), ( -3453.09, 4898.3, 1440.13 ) );
    level addteleporterlocation( "mp_slums", ( 930.71, -3431.22, 462.125 ), ( 36.2694, -5964.6, 961.343 ) );
    level addteleporterlocation( "mp_slums", ( -856.359, -2874.36, 456.488 ), ( -3467.91, -6139.85, 1298.06 ) );
    level addteleporterlocation( "mp_village", ( -1002.48, 1473.46, 8.125 ), ( -3799.54, 16155.2, 3834.15 ) );
    level addteleporterlocation( "mp_socotra", ( -1147.29, -877.958, 200.079 ), ( -3247.38, 3138.9, -12.1319 ) );
    level addteleporterlocation( "mp_socotra", ( 505.814, 2463.36, 279.125 ), ( 855.58, 2799.19, 1165.13 ) );
    level addteleporterlocation( "mp_socotra", ( 1481.7, 1783.28, 259.029 ), ( 1464.84, 2139.42, 434.149 ) );
    level addteleporterlocation( "mp_downhill", ( 68.4395, -2862.36, 1051.74 ), ( 25.5549, -7150.37, 1757.92 ) );
    level addteleporterlocation( "mp_vertigo", ( -508.363, 2160.36, 18.125 ), ( -539.641, 2297.62, 142.46 ) );
    level addteleporterlocation( "mp_concert", ( -93.9126, 2502.62, 24.125 ), ( 289.055, 3552.45, 448.125 ) );
    level addteleporterlocation( "mp_studio", ( -740.586, 2089.58, -53.451 ), ( -1188.03, 2400.63, -51.5003 ) );
    level addteleporterlocation( "mp_castaway", ( 1485.94, -534.552, 83.2066 ), ( 1717.02, -1018.77, 528.125 ) );
    level addteleporterlocation( "mp_paintball", ( 377.334, 2012.36, 7.59612 ), ( 2541.76, 26921.4, 3163.85 ) );
    level addteleporterlocation( "mp_frostbite", ( -2528.36, -417.444, 61.6003 ), ( -3176.01, -463.008, 298.479 ) );
    level addteleporterlocation( "mp_pod", ( 299.579, -3438.8, 388.572 ), ( 1056.84, -2838.53, 678.125 ) );
    level addteleporterlocation( "mp_pod", ( 1299.19, -29.9173, 266.133 ), ( 3650.77, 2987.8, 1994.13 ) );
    level addteleporterlocation( "mp_pod", ( 1429.15, -929.07, 241.743 ), ( 3580.52, -261.356, 1402.13 ) );
    level addteleporterlocation( "mp_takeoff", ( -380.067, 4400.36, 32.125 ), ( -852.278, 5383.02, 115.625 ) );
    level addteleporterlocation( "mp_magma", ( 272.359, -1712.36, -611.471 ), ( 153.359, -1921.86, -303.875 ) );
    level addteleporterlocation( "mp_hydro", ( 2394.86, -225.641, 218.739 ), ( 7966.66, 22539.1, 8040.13 ) );
    level addteleporterlocation( "mp_hydro", ( -2376.79, -220.892, 216.125 ), ( -11866.1, 22552.2, 8040.13 ) );
    level addteleporterlocation( "mp_skate", ( 2642.43, 30.2093, 177.19 ), ( 5931.07, 2012.66, 1313.69 ) );
    level addteleporterlocation( "mp_raid", ( 4649.62, 2475.97, 63.5948 ), ( 8647.19, 5152.24, 1980.76 ) );
}

configureslides()
{
    level addslidelocation( "mp_bridge", ( 3867.48, 914.571, -15.267 ) );
    level addslidelocation( "mp_bridge", ( -4128.44, -706.689, 10.357 ) );
    level addslidelocation( "mp_carrier", ( 277.986, -757.076, -262.325 ) );
    level addslidelocation( "mp_carrier", ( -2856.5, 1593.67, -62.7342 ) );
    level addslidelocation( "mp_carrier", ( -135.44, -1796.28, -281.2 ) );
    level addslidelocation( "mp_carrier", ( -3362.43, -1768.73, -44.875 ) );
    level addslidelocation( "mp_carrier", ( -3232.87, 1556.36, -306.673 ) );
    level addslidelocation( "mp_carrier", ( -5230.93, 1381.23, 91.1246 ) );
    level addslidelocation( "mp_carrier", ( -3897, -1860.25, -41.7295 ) );
    level addslidelocation( "mp_carrier", ( -6170.93, -1673.6, -60.875 ) );
    level addslidelocation( "mp_carrier", ( -6451.71, 1483.51, -29.875 ) );
    level addslidelocation( "mp_carrier", ( -6587.58, -263.731, 34.7245 ) );
    level addslidelocation( "mp_castaway", ( 1863.21, 1751.77, 91.6984 ) );
    level addslidelocation( "mp_castaway", ( -1305.77, 519.966, 177.096 ) );
    level addslidelocation( "mp_castaway", ( 1049.03, -1431.4, 94.5175 ) );
    level addslidelocation( "mp_castaway", ( -567.813, 181.674, 199.125 ) );
    level addslidelocation( "mp_castaway", ( 1602.45, -1363.05, 55.5721 ) );
    level addslidelocation( "mp_concert", ( -1112.21, -594.59, -25.1375 ) );
    level addslidelocation( "mp_concert", ( 1007.51, -420.201, 14.2874 ) );
    level addslidelocation( "mp_concert", ( 2750.23, 2125.42, -4.08341 ) );
    level addslidelocation( "mp_concert", ( -326.893, 2400.54, 24.125 ) );
    level addslidelocation( "mp_concert", ( 2205.98, 5080, -5.7106 ) );
    level addslidelocation( "mp_concert", ( -2742.77, -633.673, -104.818 ) );
    level addslidelocation( "mp_dig", ( -1288.61, 2088.82, 513.835 ) );
    level addslidelocation( "mp_dig", ( 1094.37, -1116.33, 121.625 ) );
    level addslidelocation( "mp_dig", ( -1727.17, 327.599, 80.125 ) );
    level addslidelocation( "mp_dockside", ( -6306.07, 2848.72, -105.06 ) );
    level addslidelocation( "mp_dockside", ( -10623.8, 2802.97, -74.865 ) );
    level addslidelocation( "mp_dockside", ( -439.896, -1432.95, -63.6418 ) );
    level addslidelocation( "mp_downhill", ( 1041.23, -2713.15, 1064.13 ) );
    level addslidelocation( "mp_downhill", ( -774.014, -176.011, 1016.73 ) );
    level addslidelocation( "mp_downhill", ( 386.595, 1464.64, 1084.13 ) );
    level addslidelocation( "mp_downhill", ( 917.663, -174.687, 908.125 ) );
    level addslidelocation( "mp_drone", ( -1842.73, -3384.02, 39.8422 ) );
    level addslidelocation( "mp_drone", ( -465.299, -4024.13, 11.2451 ) );
    level addslidelocation( "mp_express", ( 934.101, 2141.94, -7.375 ) );
    level addslidelocation( "mp_express", ( 964.019, -2183.16, -8.37542 ) );
    level addslidelocation( "mp_express", ( -920.078, 2.37468, 77.8548 ) );
    level addslidelocation( "mp_express", ( -3283.1, 4581.15, 1244.55 ) );
    level addslidelocation( "mp_frostbite", ( -3232.47, -428.434, 311.005 ) );
    level addslidelocation( "mp_frostbite", ( 231.358, -788.418, 59.0102 ) );
    level addslidelocation( "mp_frostbite", ( 2142.77, 761.657, -5.78405 ) );
    level addslidelocation( "mp_frostbite", ( -319.934, -1454.7, -7.875 ) );
    level addslidelocation( "mp_hijacked", ( -3309.08, -212.745, -288.875 ) );
    level addslidelocation( "mp_hijacked", ( 111.24, 765.006, 19.7339 ) );
    level addslidelocation( "mp_hijacked", ( 895.958, -587.502, 71.1236 ) );
    level addslidelocation( "mp_magma", ( -1189.2, -2348.7, -586.245 ) );
    level addslidelocation( "mp_magma", ( 3110.32, -1050.22, -619.912 ) );
    level addslidelocation( "mp_magma", ( 1957.84, -2342.38, -560.292 ) );
    level addslidelocation( "mp_magma", ( 4206.95, -911.336, -463.92 ) );
    level addslidelocation( "mp_magma", ( -244.377, 788.453, -324.449 ) );
    level addslidelocation( "mp_hydro", ( -30.4833, -215.811, 224.392 ) );
    level addslidelocation( "mp_hydro", ( -1390.67, 195.76, 253.033 ) );
    level addslidelocation( "mp_hydro", ( 1329.61, 191.115, 253.435 ) );
    level addslidelocation( "mp_hydro", ( -3072.02, 5623.6, 177.141 ) );
    level addslidelocation( "mp_hydro", ( 3026.8, 5614.42, 216.773 ) );
    level addslidelocation( "mp_hydro", ( 3171.76, 3076.64, 224.61 ) );
    level addslidelocation( "mp_hydro", ( -3013.21, 1858.14, -976.444 ) );
    level addslidelocation( "mp_hydro", ( 2987.02, 1896.32, -976.479 ) );
    level addslidelocation( "mp_hydro", ( 2860.5, 1245.98, 111.557 ) );
    level addslidelocation( "mp_hydro", ( -2889.93, 1270.37, 100.358 ) );
    level addslidelocation( "mp_hydro", ( -3339.23, 2463.12, 174.078 ) );
    level addslidelocation( "mp_la", ( 167.752, 798.751, -206.875 ) );
    level addslidelocation( "mp_la", ( -2347.77, 1854.57, -94.875 ) );
    level addslidelocation( "mp_la", ( -981.243, 2291.79, -145.15 ) );
    level addslidelocation( "mp_la", ( -1318.19, 5407.61, -262.875 ) );
    level addslidelocation( "mp_la", ( -981.243, 2291.79, -145.15 ) );
    level addslidelocation( "mp_la", ( -1041.02, -2266.13, 119.125 ) );
    level addslidelocation( "mp_la", ( -1451.07, 4776.9, -30.375 ) );
    level addslidelocation( "mp_la", ( -2343.49, -67.9582, -148.229 ) );
    level addslidelocation( "mp_meltdown", ( 1492.67, 4266.54, -115.051 ) );
    level addslidelocation( "mp_meltdown", ( 1953.39, -210.607, -125.86 ) );
    level addslidelocation( "mp_meltdown", ( 1111.43, 7677.59, -180.217 ) );
    level addslidelocation( "mp_mirage", ( -0.933236, 1334.74, -39.875 ) );
    level addslidelocation( "mp_mirage", ( -987.036, 13.6084, 46.2613 ) );
    level addslidelocation( "mp_mirage", ( -2059.46, 1377.58, -47.7523 ) );
    level addslidelocation( "mp_mirage", ( 2026.54, 898.419, 145.911 ) );
    level addslidelocation( "mp_mirage", ( -1260.36, 2496.19, 54.082 ) );
    level addslidelocation( "mp_nightclub", ( -18692.6, 929.444, -63.875 ) );
    level addslidelocation( "mp_nightclub", ( -13285.2, 3342.23, -252.579 ) );
    level addslidelocation( "mp_nightclub", ( -17535.9, 2031.71, -87.875 ) );
    level addslidelocation( "mp_nightclub", ( -19329.8, 2118.26, -143.893 ) );
    level addslidelocation( "mp_nightclub", ( -17446.9, 3832.58, -145.382 ) );
    level addslidelocation( "mp_overflow", ( -405.66, 926.608, 130.927 ) );
    level addslidelocation( "mp_overflow", ( 1435.16, -628.923, 59.867 ) );
    level addslidelocation( "mp_overflow", ( -2413.36, 516.412, -7.60067 ) );
    level addslidelocation( "mp_overflow", ( -1880.92, -1913.41, -32.1481 ) );
    level addslidelocation( "mp_overflow", ( -407.785, -3799.52, -32.468 ) );
    level addslidelocation( "mp_paintball", ( 506.446, -2293.98, 105.2 ) );
    level addslidelocation( "mp_paintball", ( 298.72, -296.207, 81.8037 ) );
    level addslidelocation( "mp_paintball", ( 858.334, -1028.4, 136.125 ) );
    level addslidelocation( "mp_paintball", ( 416.641, 560.359, 170.12 ) );
    level addslidelocation( "mp_paintball", ( -473.752, 1758.09, 44.125 ) );
    level addslidelocation( "mp_pod", ( 1326.48, -1088.67, 260.125 ) );
    level addslidelocation( "mp_pod", ( -645.815, -161.989, 441.561 ) );
    level addslidelocation( "mp_pod", ( -1408.63, 1604.66, 526.125 ) );
    level addslidelocation( "mp_pod", ( -358.092, -3382.96, 375.349 ) );
    level addslidelocation( "mp_pod", ( -1905.9, -226.822, 430.43 ) );
    level addslidelocation( "mp_pod", ( 738.498, 567.509, 288.684 ) );
    level addslidelocation( "mp_pod", ( -358.004, -1363.44, 430.125 ) );
    level addslidelocation( "mp_raid", ( 2824.91, 1304.83, 110.125 ) );
    level addslidelocation( "mp_raid", ( 6281.38, 5790.44, -62.5428 ) );
    level addslidelocation( "mp_raid", ( 4521.97, 3716.53, 30.125 ) );
    level addslidelocation( "mp_raid", ( 6262.36, 5608.1, -56.4499 ) );
    level addslidelocation( "mp_raid", ( 1332.89, 4805.69, -3.875 ) );
    level addslidelocation( "mp_raid", ( 6458.98, 576.1, -50.7288 ) );
    level addslidelocation( "mp_skate", ( 2490.72, -229.869, 164.125 ) );
    level addslidelocation( "mp_skate", ( -2243.14, -589.049, 250.125 ) );
    level addslidelocation( "mp_skate", ( 425.106, 801.359, 258.125 ) );
    level addslidelocation( "mp_skate", ( -625.814, -1698.38, 289.841 ) );
    level addslidelocation( "mp_socotra", ( 1870.87, -944.028, 140.125 ) );
    level addslidelocation( "mp_socotra", ( -135.271, -94.4287, 215.916 ) );
    level addslidelocation( "mp_socotra", ( -393.288, -2491.36, -198.79 ) );
    level addslidelocation( "mp_socotra", ( 1877.36, 67.1556, 17.7729 ) );
    level addslidelocation( "mp_socotra", ( 2002.41, -110.577, 191.767 ) );
    level addslidelocation( "mp_socotra", ( -3512.8, 3457.84, -27.1995 ) );
    level addslidelocation( "mp_socotra", ( -3048.07, -1626.91, -431.875 ) );
    level addslidelocation( "mp_socotra", ( 1459.04, 110.007, 124.697 ) );
    level addslidelocation( "mp_studio", ( -268.631, 2351.6, -50.2802 ) );
    level addslidelocation( "mp_studio", ( -708.849, -451.045, -127.875 ) );
    level addslidelocation( "mp_studio", ( 2617.64, 1531.97, -43.875 ) );
    level addslidelocation( "mp_studio", ( 8891.04, -534.069, 1085.22 ) );
    level addslidelocation( "mp_studio", ( 3483.75, 3521.03, 202.335 ) );
    level addslidelocation( "mp_takeoff", ( 357.988, -869.419, -0.875001 ) );
    level addslidelocation( "mp_takeoff", ( -295.603, 3838.15, 32.125 ) );
    level addslidelocation( "mp_takeoff", ( -362.186, 5998.38, 92.4687 ) );
    level addslidelocation( "mp_takeoff", ( 1642.25, 904.172, 62.125 ) );
    level addslidelocation( "mp_turbine", ( -1508.61, -3450.26, 501.967 ) );
    level addslidelocation( "mp_uplink", ( 1811.84, -269.96, 481.125 ) );
    level addslidelocation( "mp_uplink", ( 3165.04, -2839.12, 444.603 ) );
    level addslidelocation( "mp_uplink", ( 3854.53, -903.135, 454.125 ) );
    level addslidelocation( "mp_uplink", ( 4077.91, 1394.94, 318.125 ) );
    level addslidelocation( "mp_vertigo", ( 4961.45, 3214.83, -319.114 ) );
    level addslidelocation( "mp_vertigo", ( 4962.15, -2329.86, -311.268 ) );
    level addslidelocation( "mp_vertigo", ( 270.138, 3246.75, -20.875 ) );
    level addslidelocation( "mp_vertigo", ( -973.29, -2596.57, -153.875 ) );
    level addslidelocation( "mp_vertigo", ( -1641.47, 824.889, 13.7153 ) );
    level addslidelocation( "mp_village", ( 1129.29, -117.234, 56.125 ) );
    level addslidelocation( "mp_village", ( -1608.21, -2413.22, 0.124999 ) );
    level addslidelocation( "mp_village", ( 15.5515, -1746.36, -23.7253 ) );
    level addslidelocation( "mp_village", ( 745.533, 1623.92, 8.11641 ) );
}

configureplatforms()
{
    level addplatformlocation( "mp_dockside", ( -12428, -7868, 675 ), 8, 8 );
    level addplatformlocation( "mp_overflow", ( -2961, -1761, 69 ), 8, 8 );
    level addplatformlocation( "mp_overflow", ( -5417, -2797, 104 ), 8, 8 );
    level addplatformlocation( "mp_carrier", ( -13433.6, 16126.4, 390.146 ), 6, 6 );
    level addplatformlocation( "mp_nuketown_2020", ( 3099.97, 392.795, 262.116 ), 1, 1 );
    level addplatformlocation( "mp_nuketown_2020", ( 7223.56, -5429.35, 2516.02 ), 9, 8 );
    level addplatformlocation( "mp_nuketown_2020", ( 5755.86, 8246.27, 1266.08 ), 5, 5 );
    level addplatformlocation( "mp_nuketown_2020", ( -1443.23, -4748.53, 3287.52 ), 3, 3 );
    level addplatformlocation( "mp_nuketown_2020", ( -5859.98, -5232.7, 2089.6 ), 3, 3 );
    level addplatformlocation( "mp_uplink", ( -6425.05, 11693.6, 2226.59 ), 5, 5 );
    level addplatformlocation( "mp_castaway", ( -4885.19, 273.783, 1109.23 ), 6, 6 );
    level addplatformlocation( "mp_bridge", ( -3455.29, 678.056, 171.813 ), 3, 2 );
    level addplatformlocation( "mp_bridge", ( -6735.36, -1800.07, 4021.07 ), 4, 25 );
    level addplatformlocation( "mp_bridge", ( -6136.65, -12490.9, -1170.63 ), 3, 3 );
    level addplatformlocation( "mp_bridge", ( -18243.8, -7391.07, 1075.37 ), 6, 16 );
    level addplatformlocation( "mp_turbine", ( 1882.86, 12465.8, 3115.38 ), 3, 3 );
    level addplatformlocation( "mp_turbine", ( 2972.67, 6600, 3287.77 ), 3, 3 );
    level addplatformlocation( "mp_turbine", ( -1443.23, -4748.53, 3287.52 ), 3, 3 );
    level addplatformlocation( "mp_raid", ( 7131.05, 3937.01, 649.925 ), 5, 5 );
    level addplatformlocation( "mp_raid", ( -3911.69, 4744.53, 1895.03 ), 2, 3 );
    level addplatformlocation( "mp_raid", ( 8647.19, 5152.24, 1980.76 ), 2, 2 );
    level addplatformlocation( "mp_express", ( 7667.64, 373.652, 1204.13 ), 11, 11 );
    level addplatformlocation( "mp_express", ( 4101.6, 5661.94, 1060.05 ), 11, 11 );
    level addteleporterlocation( "mp_takeoff", ( -622.84, 2596.84, 8.35332 ), ( -4013.1, 3200.59, 291.717 ) );
    level addplatformlocation( "mp_takeoff", ( -4013.1, 3200.59, 291.712 ), 6, 6 );
    level addteleporterlocation( "mp_takeoff", ( 951.63, 931.322, 11.0332 ), ( 2750.3, 2103.09, 305 ) );
    level addplatformlocation( "mp_takeoff", ( 2750.3, 2103.09, 300 ), 9, 9 );
    level addteleporterlocation( "mp_takeoff", ( 426.444, 4043.9, 42.3303 ), ( -1553.53, 3375.64, 184.127 ) );
    level addteleporterlocation( "mp_takeoff", ( 1147.17, 2935.58, 13.239 ), ( -1367.46, 5355.4, 285 ) );
    level addplatformlocation( "mp_takeoff", ( -1367.46, 5355.4, 280 ), 9, 9 );
    level addteleporterlocation( "mp_pod", ( 257.925, -197.185, 335.565 ), ( 3662.35, 2980.29, 1999.13 ) );
    level addteleporterlocation( "mp_pod", ( -528.706, -2523.69, 351.863 ), ( 7466.13, -2965.79, 562.213 ) );
    level addteleporterlocation( "mp_pod", ( 262.139, 948.066, 335.926 ), ( -3079.51, 7326.49, 601.185 ) );
    level addteleporterlocation( "mp_hijacked", ( -1067, 226, 188 ), ( -3010, 357, 137 ) );
    level addplatformlocation( "mp_hijacked", ( -3010, 357, 132 ), 9, 9 );
    level addplatformlocation( "mp_carrier", ( 4849.23, 11.8394, 444.985 ), 3, 3 );
    level addteleporterlocation( "mp_carrier", ( -4963.25, -951.548, -163.875 ), ( 4822.34, 96.8838, 450.11 ) );
    level addplatformlocation( "mp_dockside", ( -12480, -1588.81, 718.5 ), 3, 3 );
    level addteleporterlocation( "mp_dockside", ( -12326, -1583.5, -191.875 ), ( -12480, -1588.81, 718.5 ) );
    level addteleporterlocation( "mp_dockside", ( 303.641, 3065.14, -68.1532 ), ( -12480, -1588.81, 718.5 ) );
    level addteleporterlocation( "mp_village", ( 1056.36, -665.732, 8.125 ), ( 15568, 18096, 2508 ) );
    level addplatformlocation( "mp_drone", ( -20370.5, 23596.7, 18749.7 ), 3, 3 );
    level addteleporterlocation( "mp_drone", ( -1069.64, 976.36, 264.125 ), ( -20370.5, 23596.7, 18749.7 ) );
    level addplatformlocation( "mp_socotra", ( 3046.16, 3797.38, 2253.31 ), 3, 3 );
    level addteleporterlocation( "mp_socotra", ( -847.641, -2028.64, 201.979 ), ( 3046.16, 3797.38, 2253.31 ) );
    level addteleporterlocation( "mp_hijacked", ( -87, 491, 54 ), ( -1073, 48, 300 ) );
    level addteleporterlocation( "mp_hijacked", ( -56, -525, 31 ), ( -1796, -80, -245 ) );
    level addplatformlocation( "mp_hijacked", ( -1796, -80, -250 ), 9, 9 );
    level addteleporterlocation( "mp_hydro", ( -1293.46, -1042.37, 374 ), ( -2768.39, 835.662, 153.303 ) );
    level addteleporterlocation( "mp_hydro", ( 2086.79, -186.203, 198.818 ), ( 2726.43, 839.444, 156.147 ) );
    level addteleporterlocation( "mp_hydro", ( 2394.86, -225.641, 218.739 ), ( 7966.66, 22539.1, 8040.13 ) );
    level addteleporterlocation( "mp_hydro", ( -2376.79, -220.892, 216.125 ), ( -11866.1, 22552.2, 8040.13 ) );
}

getbouncercount( map )
{
    return level.bouncelocs[map].size;
}

addteleporterlocation( map, origin, destination )
{
    if ( !isdefined( level.teleportlocs ) )
        level.teleportlocs = [];

    if ( !isdefined( level.teleportlocs[map] ) )
    {
        level.teleportlocs[map] = [];
        level.teleportlocs[map]["origins"] = [];
        level.teleportlocs[map]["destinations"] = [];
    }

    arr_size = level.teleportlocs[map]["origins"].size;
    level.teleportlocs[map]["origins"][arr_size] = origin;
    level.teleportlocs[map]["destinations"][arr_size] = destination;
}

getteleportercount( map )
{
    return level.teleportlocs[map]["origins"].size;
}

addplatformlocation( map, origin, width, length )
{
    if ( level.script != map )
        return;

    platform = [];

    for ( e = 0; e < width; e++ )
    {
        for ( a = 0; a < length; a++ )
        {
            platform[platform.size] = spawn( "script_model", origin + ( a * 64, e * 64, 0 ) );
            platform[platform.size - 1] setmodel( "collision_clip_64x64x10" );
        }
    }

    return platform;
}

togglemap()
{
    if ( !isdefined( self.maps ) )
    {
        self.maps = undefined;
        self iprintlnbold( "Random Maps: ^1Disabled" );
        self notify( "endmaps" );
    }
    else
    {
        self.maps = 1;
        self iprintlnbold( "Random Maps: ^2Enabled" );
        self thread randommap();
        self notify( "endgmaps" );
        self notify( "endnodlcmaps" );
    }
}

togglegmap()
{
    if ( !isdefined( self.maps ) )
    {
        self.gmaps = 1;
        self iprintlnbold( "Best Maps: ^2Enabled" );
        self thread goodmaps();
        self notify( "endmaps" );
    }
    else
    {
        self.gmaps = undefined;
        self iprintlnbold( "Best Maps: ^1Disabled" );
        self notify( "endgmaps" );
    }
}

togglenodlcmap()
{
    if ( !isdefined( self.maps ) )
    {
        self.nodlcmaps = 1;
        self iprintlnbold( "No DLC Maps: ^2Enabled" );
        self thread nodlcmaps();
        self notify( "endmaps" );
    }
    else
    {
        self.nodlcmaps = undefined;
        self iprintlnbold( "No DLC Maps: ^1Disabled" );
        self notify( "endnodlcmaps" );
    }
}

nodlcmaps()
{
    self endon( "endnodlcmaps" );
    level waittill( "final_killcam_done" );
    choice = level.nodlcmaps[randomint( level.nodlcmaps.size )];
    level changemap( choice );
}

goodmaps()
{
    self endon( "endgmaps" );
    level waittill( "final_killcam_done" );
    choice = level.goodmaps[randomint( level.goodmaps.size )];
    level changemap( choice );
}

randommap()
{
    self endon( "endmaps" );
    level waittill( "final_killcam_done" );
    choice = level.maps[randomint( level.maps.size )];
    level changemap( choice );
}

changemap( which )
{
    level.strings = 60;
    level notify( "CHECK_OVERFLOW" );
    wait 0.1;
    setdvar( "ui_currentMap", which );
    setdvar( "mapname", which );
    setdvar( "ui_mapname", which );
    makedvarserverinfo( "ui_currentMap", which );
    makedvarserverinfo( "mapname", which );
    makedvarserverinfo( "ui_mapname", which );
    setdvar( "ChangedMap", "1" );
    map( which );
}

platform()
{
    location = self.origin;

    while ( isdefined( self.spawnedcrate[0][0] ) )
    {
        for ( i = -3; i < 3; i++ )
        {
            for ( d = -3; d < 3; d++ )
                self.spawnedcrate[i][d] delete();
        }
    }

    startpos = location + ( 0, 0, -15 );

    for ( i = -3; i < 3; i++ )
    {
        for ( d = -3; d < 3; d++ )
        {
            self.spawnedcrate[i][d] = spawn( "script_model", startpos + ( d * 40, i * 70, 0 ) );
            self.spawnedcrate[i][d] setmodel( "t6_wpn_supply_drop_axis" );
        }
    }
}

selforiginget()
{
    for (;;)
    {
        self iprintln( "self.origin - ^5" + self.origin );
        wait 0.5;
    }

    wait 0.5;
}

selfanglesget()
{
    for (;;)
    {
        self iprintln( "self.angles - ^2" + self.angles );
        wait 0.5;
    }

    wait 0.5;
}

givenewweapon( weapon )
{
    self takeweapon( self getcurrentweapon() );
    waitframe();
    self giveweapon( weapon );
    self switchtoweapon( weapon );
    self givemaxammo( weapon );
    self iprintlnbold( "Weapon: [^2" + ( weapon + "^7] Given!" ) );
}

selectequipment2()
{
    if ( self.myequip2 == 0 )
    {
        self.myequip2 = 1;
        self.pers["equip2"] = "emp_grenade_mp";
        self iprintlnbold( "Equipment 2 Set To: [^2EMP Grenade^7]" );
    }
    else if ( self.myequip2 == 1 )
    {
        self.myequip2 = 2;
        self.pers["equip2"] = "trophy_system_mp";
        self iprintlnbold( "Equipment 2 Set To: [^2Trophy System^7]" );
    }
    else if ( self.myequip2 == 2 )
    {
        self.myequip2 = 3;
        self.pers["equip2"] = "flash_grenade_mp";
        self iprintlnbold( "Equipment 2 Set To: [^2Flashbang^7]" );
    }
    else if ( self.myequip2 == 3 )
    {
        self.myequip2 = 4;
        self.pers["equip2"] = "proximity_grenade_mp";
        self iprintlnbold( "Equipment 2 Set To: [^2Shockcharge^7]" );
    }
    else if ( self.myequip2 == 4 )
    {
        self.myequip2 = 5;
        self.pers["equip2"] = "pda_hack_mp";
        self iprintlnbold( "Equipment 2 Set To: [^2Hack Tool^7]" );
    }
    else if ( self.myequip2 == 5 )
    {
        self.myequip2 = 6;
        self.pers["equip2"] = "satchel_charge_mp";
        self iprintlnbold( "Equipment 2 Set To: [^2C4^7]" );
    }
    else if ( self.myequip2 == 6 )
    {
        self.myequip2 = 7;
        self.pers["equip2"] = "claymore_mp";
        self iprintlnbold( "Equipment 2 Set To: [^2Claymore^7]" );
    }
    else if ( self.myequip2 == 7 )
    {
        self.myequip2 = 8;
        self.pers["equip2"] = "sticky_grenade_mp";
        self iprintlnbold( "Equipment 2 Set To: [^2Semtex^7]" );
    }
    else if ( self.myequip2 == 8 )
    {
        self.myequip2 = 9;
        self.pers["equip2"] = "hatchet_mp";
        self iprintlnbold( "Equipment 2 Set To: [^2Tomahawk^7]" );
    }
    else if ( self.myequip2 == 9 )
    {
        self.myequip2 = 0;
        self.pers["equip2"] = undefined;
        self iprintlnbold( "Equipment 2 Set To: [^2None^7]" );
    }
}

perkslot1()
{
    if ( self.myperk1 == 0 )
    {
        self.myperk1 = 1;
        self.pers["perkslot1"] = "LIGHTWEIGHT";
        self iprintlnbold( "Perk 1 Set To: [^2Lightweight^7]" );
    }
    else if ( self.myperk1 == 1 )
    {
        self.myperk1 = 0;
        self.pers["perkslot1"] = undefined;
        self iprintlnbold( "Perk 1 Set To: [^2None^7]" );
    }
}

perkslot2()
{
    if ( self.myperk2 == 0 )
    {
        self.myperk2 = 1;
        self.pers["perkslot2"] = "specialty_bulletflinch";
        self iprintlnbold( "Perk 2 Set To: [^2Toughness^7]" );
    }
    else if ( self.myperk2 == 1 )
    {
        self.myperk2 = 2;
        self.pers["perkslot2"] = "FASTHANDS";
        self iprintlnbold( "Perk 2 Set To: [^2Fast Hands^7]" );
    }
    else if ( self.myperk2 == 2 )
    {
        self.myperk2 = 0;
        self.pers["perkslot2"] = undefined;
        self iprintlnbold( "Perk 2 Set To: [^2None^7]" );
    }
}

perkslot3()
{
    if ( self.myperk3 == 0 )
    {
        self.myperk3 = 1;
        self.pers["perkslot3"] = "DEXTERITY";
        self iprintlnbold( "Perk 3 Set To: [^2Dexterity^7]" );
    }
    else if ( self.myperk3 == 1 )
    {
        self.myperk3 = 2;
        self.pers["perkslot3"] = "specialty_quieter";
        self iprintlnbold( "Perk 3 Set To: [^2Dead Silence^7]" );
    }
    else if ( self.myperk3 == 2 )
    {
        self.myperk3 = 0;
        self.pers["perkslot3"] = undefined;
        self iprintlnbold( "Perk 3 Set To: [^2None^7]" );
    }
}

selectequipment1()
{
    if ( self.myequip1 == 0 )
    {
        self.myequip1 = 1;
        self.pers["equip1"] = "satchel_charge_mp";
        self iprintlnbold( "Equipment 1 Set To: [^2C4^7]" );
    }
    else if ( self.myequip1 == 1 )
    {
        self.myequip1 = 2;
        self.pers["equip1"] = "claymore_mp";
        self iprintlnbold( "Equipment 1 Set To: [^2Claymore^7]" );
    }
    else if ( self.myequip1 == 2 )
    {
        self.myequip1 = 3;
        self.pers["equip1"] = "sticky_grenade_mp";
        self iprintlnbold( "Equipment 1 Set To: [^2Semtex^7]" );
    }
    else if ( self.myequip1 == 3 )
    {
        self.myequip1 = 4;
        self.pers["equip1"] = "hatchet_mp";
        self iprintlnbold( "Equipment 1 Set To: [^2Tomahawk^7]" );
    }
    else if ( self.myequip1 == 4 )
    {
        self.myequip1 = 5;
        self.pers["equip1"] = "emp_grenade_mp";
        self iprintlnbold( "Equipment 1 Set To: [^2EMP Grenade^7]" );
    }
    else if ( self.myequip1 == 5 )
    {
        self.myequip1 = 6;
        self.pers["equip1"] = "trophy_system_mp";
        self iprintlnbold( "Equipment 1 Set To: [^2Trophy System^7]" );
    }
    else if ( self.myequip1 == 6 )
    {
        self.myequip1 = 7;
        self.pers["equip1"] = "flash_grenade_mp";
        self iprintlnbold( "Equipment 1 Set To: [^2Flashbang^7]" );
    }
    else if ( self.myequip1 == 7 )
    {
        self.myequip1 = 8;
        self.pers["equip1"] = "proximity_grenade_mp";
        self iprintlnbold( "Equipment 1 Set To: [^2Shockcharge^7]" );
    }
    else if ( self.myequip1 == 8 )
    {
        self.myequip1 = 9;
        self.pers["equip1"] = "pda_hack_mp";
        self iprintlnbold( "Equipment 1 Set To: [^2Hack Tool^7]" );
    }
    else if ( self.myequip1 == 9 )
    {
        self.myequip1 = 0;
        self.pers["equip1"] = undefined;
        self iprintlnbold( "Equipment 1 Set To: [^2None^7]" );
    }
}

unlimited_ammo()
{
    self endon( "disconnect" );
    self endon( "stopThis" );

    for (;;)
    {
        self setweaponammoclip( self.storeweapon, weaponclipsize( self.storeweapon ) );
        self givemaxammo( self.storeweapon );
    }

    waitframe();
}

loadcusloadout()
{
    self freezecontrols( 1 );
    akimbo = 0;
    self takeallweapons();
    self clearperks();
    waitframe();
    self thread setdaperks();

    if ( self.myperk1 == 1 )
    {
        self setperk( "specialty_movefaster" );
        self setperk( "specialty_fallheight" );
    }

    if ( self.myperk2 == 2 )
    {
        self setperk( "specialty_fastweaponswitch" );
        self setperk( "specialty_pin_back" );
        self setperk( "specialty_fasttoss" );
        self setperk( "specialty_fastequipmentuse" );
    }
    else if ( self.myperk2 < 2 )
        self setperk( self.pers["perkslot2"] );

    if ( self.myperk3 == 1 )
    {
        self setperk( "specialty_fastmantle" );
        self setperk( "specialty_fastladderclimb" );
        self setperk( "specialty_sprintrecovery" );
        self setperk( "specialty_fastmeleerecovery" );
    }
    else if ( self.myperk3 > 1 )
        self setperk( self.pers["perkslot3"] );

    self giveweapon( "knife_mp", akimbo );

    if ( issubstr( self.pers["myCustGuns"], "dw" ) )
        akimbo = 1;

    if ( issubstr( self.pers["savedSec"], "dw" ) )
        akimbo = 1;

    self giveweapon( self.pers["myCustGuns"], akimbo );
    self giveweapon( self.pers["savedSec"], akimbo );
    waitframe();
    self switchtoweapon( self.pers["myCustGuns"] );
    self setspawnweapon( self.pers["myCustGuns"] );
    self giveweapon( self.pers["equip1"] );
    self setweaponammostock( self.pers["equip1"], 2 );
    self giveweapon( self.pers["equip2"] );
    self setweaponammostock( self.pers["equip2"], 2 );
    self freezecontrols( 0 );
}

setcamoarray()
{
    self.camo = randomintrange( 1, 43 );
    self iprintlnbold( "Camo Set To: [^2" + ( self.camo + "^7]" ) );
}

saveprimary()
{
    if ( !isdefined( self.cusprimary ) )
    {
        self.cusprimary = 1;
        self.pers["myCustGuns"] = self getcurrentweapon();
        self iprintlnbold( "Primary Weapon: [^2" + ( self.pers["myCustGuns"] + "^7] Saved!" ) );
    }
    else
    {
        self.cusprimary = undefined;
        self.pers["myCustGuns"] = undefined;
        self iprintlnbold( "Primary Weapon: ^1Reset" );
    }
}

savesec()
{
    if ( !isdefined( self.cussecond ) )
    {
        self.cussecond = 1;
        self.pers["savedSec"] = self getcurrentweapon();
        self iprintlnbold( "Secondary Weapon: [^2" + ( self.pers["savedSec"] + "^7] Saved!" ) );
    }
    else
    {
        self.cussecond = undefined;
        self.pers["savedSec"] = undefined;
        self iprintlnbold( "Secondary Weapon: ^1Reset" );
    }
}

giveplayerattachment( attachment )
{
    weapon = self getcurrentweapon();
    self takeweapon( weapon );
    self giveweapon( weapon + attachment );
    self switchtoweapon( weapon + attachment );
    self givemaxammo( weapon + attachment );
    self iprintlnbold( "[^2" + ( attachment + ( "^7] Attached To [^2" + ( weapon + "^7]" ) ) ) );
}

togglecusloadout()
{
    if ( !isdefined( self.cusprimary ) || !isdefined( self.cussecond ) )
        self iprintlnbold( "^1You Must Create A Custom Loadout First!" );
    else if ( !isdefined( self.cusloadout ) )
    {
        self.cusloadout = 1;
        self iprintlnbold( "Custom Loadout On Spawn: ^2Enabled" );
    }
    else
    {
        self.cusloadout = undefined;
        self iprintlnbold( "Custom Loadout On Spawn: ^1Disabled" );
    }
}

overflowfix()
{
    level endon( "game_ended" );
    level waittill( "connected", player );
    level.stringtable = [];
    level.textelementtable = [];
    textanchor = createserverfontstring( "default", 1 );
    textanchor setelementtext( "Anchor" );
    textanchor.alpha = 0;

    if ( getdvar( "g_gametype" ) == "tdm" || getdvar( "g_gametype" ) == "hctdm" )
        limit = 54;

    if ( getdvar( "g_gametype" ) == "dm" || getdvar( "g_gametype" ) == "hcdm" )
        limit = 54;

    if ( getdvar( "g_gametype" ) == "dom" || getdvar( "g_gametype" ) == "hcdom" )
        limit = 38;

    if ( getdvar( "g_gametype" ) == "dem" || getdvar( "g_gametype" ) == "hcdem" )
        limit = 41;

    if ( getdvar( "g_gametype" ) == "conf" || getdvar( "g_gametype" ) == "hcconf" )
        limit = 53;

    if ( getdvar( "g_gametype" ) == "koth" || getdvar( "g_gametype" ) == "hckoth" )
        limit = 41;

    if ( getdvar( "g_gametype" ) == "hq" || getdvar( "g_gametype" ) == "hchq" )
        limit = 43;

    if ( getdvar( "g_gametype" ) == "ctf" || getdvar( "g_gametype" ) == "hcctf" )
        limit = 32;

    if ( getdvar( "g_gametype" ) == "sd" || getdvar( "g_gametype" ) == "hcsd" )
        limit = 38;

    if ( getdvar( "g_gametype" ) == "oneflag" || getdvar( "g_gametype" ) == "hconeflag" )
        limit = 25;

    if ( getdvar( "g_gametype" ) == "gun" )
        limit = 48;

    if ( getdvar( "g_gametype" ) == "oic" )
        limit = 51;

    if ( getdvar( "g_gametype" ) == "shrp" )
        limit = 48;

    if ( getdvar( "g_gametype" ) == "sas" )
        limit = 50;

    if ( isdefined( level.stringoptimization ) )
        limit = limit + 172;

    while ( !level.gameended )
    {
        if ( isdefined( level.stringoptimization ) && level.stringtable.size >= 100 && !isdefined( textanchor2 ) )
        {
            textanchor2 = createserverfontstring( "default", 1 );
            textanchor2 setelementtext( "Anchor2" );
            textanchor2.alpha = 0;
        }

        if ( level.stringtable.size >= limit )
        {
            if ( isdefined( textanchor2 ) )
            {
                textanchor2 clearalltextafterhudelem();
                textanchor2 destroyelement();
            }

            foreach ( player in level.players )
                player.bad setelementtext( "Thanks to ^5DoktorSAS" );

            textanchor clearalltextafterhudelem();
            level.stringtable = [];

            foreach ( textelement in level.textelementtable )
            {
                if ( !isdefined( self.label ) )
                {
                    textelement setelementtext( textelement.text );
                    continue;
                }

                textelement setelementvaluetext( textelement.text );
            }
        }

        wait 0.01;
    }
}

setelementtext( text )
{
    self settext( text );

    if ( self.text != text )
        self.text = text;

    if ( !isinarray( level.stringtable, text ) )
        level.stringtable[level.stringtable.size] = text;

    if ( !isinarray( level.textelementtable, self ) )
        level.textelementtable[level.textelementtable.size] = self;
}

setelementvaluetext( text )
{
    self.label = &"" + text;

    if ( self.text != text )
        self.text = text;

    if ( !isinarray( level.stringtable, text ) )
        level.stringtable[level.stringtable.size] = text;

    if ( !isinarray( level.textelementtable, self ) )
        level.textelementtable[level.textelementtable.size] = self;
}

destroyelement()
{
    if ( isinarray( level.textelementtable, self ) )
        arrayremovevalue( level.textelementtable, self );

    if ( isdefined( self.elemtype ) )
    {
        self.frame destroy();
        self.bar destroy();
        self.barframe destroy();
    }

    self destroy();
}

toggleClasschange()
{
	self endon("disconnect");
	self endon("game_ended");
	if(!isdefined(self.changeclass))
	{
		self iprintlnbold("Class Change Bind: ^2Enabled, Press [{+Actionslot 1}]");
		self.changeclass = 1;
		while(isdefined(self.changeclass))
		{
			if(self actionslotonebuttonpressed() && self.menu.open == 0)
			{
				self thread dochangeclass();
			}
			wait(0.05);
		}
	}
	else if(isdefined(self.changeclass))
	{
		self iprintlnbold("Class Change Bind: ^1Disabled");
		self.changeclass = undefined;
	}
}

dochangeclass()
{
	if(self.cclass == 0 || self.cclass == 5)
	{
		self.cclass = 1;
		self notify("menuresponse", "changeclass", "custom0");
	}
	else if(self.cclass == 1)
	{
		self.cclass = 2;
		self notify("menuresponse", "changeclass", "custom1");
	}
	else if(self.cclass == 2)
	{
		self.cclass = 3;
		self notify("menuresponse", "changeclass", "custom2");
	}
	else if(self.cclass == 3)
	{
		self.cclass = 4;
		self notify("menuresponse", "changeclass", "custom3");
	}
	else if(self.cclass == 4)
	{
		self.cclass = 5;
		self notify("menuresponse", "changeclass", "custom4");
	}
	wait(0.05);
	self.nova = self getcurrentweapon();
	ammow = self getweaponammostock(self.nova);
	ammocw = self getweaponammoclip(self.nova);
	self setweaponammostock(self.nova, ammow);
	self setweaponammoclip(self.nova, ammocw);
}

repeater3()
{
	self endon("disconnect");
	self endon("game_ended");
	if(!isdefined(self.repeaterbind))
	{
		self iprintlnbold("Repeater Bind: ^2Enabled ^7Press [{+Actionslot 3}]");
		self.repeaterbind = 1;
		while(isdefined(self.repeaterbind))
		{
			if(self actionslotthreebuttonpressed() && self.menuopen == 0)
			{
				self thread repeaterbind();
			}
			wait(0.001);
		}
	}
	else if(isdefined(self.repeaterbind))
	{
		self iprintlnbold("Repeater Bind: ^1Disabled");
		self.repeaterbind = undefined;
	}
}

repeaterbind()
{
	current = self getcurrentweapon();
	self setspawnweapon(current);
}

monitorPositionButtons()
{
    self endon("disconnect");

    for(;;)
    {
        // Only run button checks while the player is alive and the menu is closed
        if(isAlive(self) && !self.menu["open"])
        {
            // SAVE: Crouch + D-Pad Up
            if(self getStance() == "crouch" && self actionSlotTwoButtonPressed())
            {
                self.pers["saved_origin"] = self.origin; 
                self.pers["saved_angles"] = self getPlayerAngles(); 

                // Notify feedback (optional visual/sound cue)
                self iprintln("^2Position Saved");

                while(self actionSlotTwoButtonPressed()) wait 0.05; 
            }

            // LOAD: Crouch + D-Pad Down
            if(self getStance() == "crouch" && self actionSlotOneButtonPressed())
            {
                if(isDefined(self.pers["saved_origin"]))
                {
                    self setOrigin(self.pers["saved_origin"]); 
                    self setPlayerAngles(self.pers["saved_angles"]);
                    
                    // Reset velocity to stop existing momentum
                    self setVelocity((0,0,0));
                }
                else
                {
                    self iprintln("^1No position saved!");
                }

                while(self actionSlotOneButtonPressed()) wait 0.05; 
            }
        }

        wait 0.05; 
    }
}

togglesemtex()
{
    if(!isDefined(self.pers["lb_semtex"])) self.pers["lb_semtex"] = false;
    self.pers["lb_semtex"] = !self.pers["lb_semtex"];

    if(self.pers["lb_semtex"])
    {
        self iprintln("LB Semtex ^4ON");
        self thread lbsemtex();
        self semtex();
    }
    else
    {
        self iprintln("LB Semtex ^0OFF");
        self notify("stopsemtex");
    }
}

lbsemtex()
{
    self endon("disconnect");
    self endon("stopsemtex");

    for(;;)
    {
        // Triggers whenever you change class OR respawn
        self waittill_any("changed_class", "spawned_player");

        if(isDefined(self.pers["lb_semtex"]) && self.pers["lb_semtex"])
        {
            wait 0.1; // Delay lets giveloadout() finish replacing equipment first
            self semtex();
        }
    }
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

toggle_mw3_grenade()
{
    if(!isDefined(self.pers["mw3_nade"])) self.pers["mw3_nade"] = false;
    self.pers["mw3_nade"] = !self.pers["mw3_nade"];

    if(self.pers["mw3_nade"])
    {
        self iprintln("MW3 Nade: ^2ON");
        self givemw3grenade();
        self thread watch_mw3_nade_persists();
    }
    else
    {
        self iprintln("MW3 Nade: ^1OFF");
        self notify("stop_mw3_nade_persistence");
    }
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

watch_mw3_nade_persists()
{
    self endon("disconnect");
    self endon("stop_mw3_nade_persistence");

    for(;;)
    {
        // Wait for either a respawn or class change event
        self waittill_any("spawned_player", "changed_class");

        if(isDefined(self.pers["mw3_nade"]) && self.pers["mw3_nade"])
        {
            wait 0.1; // Small delay to let giveloadout() finish replacing equipment
            self givemw3grenade();
        }
    }
}

toggle_instant_next_class()
{
    if(!isDefined(self.auto_next_class)) self.auto_next_class = false;
    self.auto_next_class = !self.auto_next_class;

    if(self.auto_next_class)
    {
        self iPrintLn("Instant Next Class: ^4ON");
        self iPrintLnBold("Press [{+actionslot 2}] ^7to Swap");
        self thread monitor_instant_next_class(); // <-- ADD THIS THREAD
    }
    else
    {
        self iprintln("Instant Next Class: ^0OFF");
        self notify("stop_next_class_bind"); // <-- ADD THIS NOTIFY
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

monitor_instant_next_class()
{
    self endon("disconnect");
    self endon("stop_next_class_bind");

    for(;;)
    {
        // Check if D-Pad Down (actionslot 2) is pressed while menu is CLOSED
        if(self actionslottwobuttonpressed() && (!isDefined(self.menuopen) || self.menuopen == 0))
        {
            self do_instant_next_class();
            wait 0.3; // Cooldown so it doesn't loop rapidly through classes
        }
        wait 0.05;
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

knifelunge()
{
	if( self.lunge == 0 )
	{
		self.lunge = 1;
		self iprintln( "Knife Lunge [^2ON^7]" );
		self iprintlnbold( "Look at a ^1Bot^7 and then knife" );
		setdvar( "aim_automelee_enabled", 1 );
		setdvar( "aim_automelee_lerp", 100 );
		setdvar( "aim_automelee_range", 250 );
		setdvar( "aim_automelee_move_limit", 0 );
	}
	else
	{
		self.lunge = 0;
		self iprintln( "Knife Lunge [^1OFF^7]" );
		setdvar( "aim_automelee_enabled", 1 );
		setdvar( "aim_automelee_lerp", 40 );
		setdvar( "aim_automelee_range", 100 );
		setdvar( "aim_automelee_move_limit", 0.1 );
		self notify( "stop_knfelunge" );
	}

}

gravity()
{
    // Initialize the state variable if it doesn't exist yet
    if(!isDefined(self.grav_level))
        self.grav_level = 0;

    // Cycle through 4 different levels (0 to 3)
    self.grav_level = (self.grav_level + 1) % 4;

    switch(self.grav_level)
    {
        case 0:
            setDvar("bg_gravity", "800");
            self iPrintln("Gravity: ^1NORMAL (^2800^1)");
            break;
        case 1:
            setDvar("bg_gravity", "300");
            self iPrintln("Gravity: ^3LOW (^2300^3)");
            break;
        case 2:
            setDvar("bg_gravity", "200");
            self iPrintln("Gravity: ^5MOON (^2200^5)");
            break;
        case 3:
            setDvar("bg_gravity", "100");
            self iPrintln("Gravity: ^6ZERO-G (^2100^6)");
            break;
    }
}

altswap()
{
    self giveweapon( "fiveseven_mp" );
    self iPrintLn("Alt Swap: ^1Five-Seven Given");
}

giveblackhatglitch()
{
    self iprintlnbold ("Blackhat Mala: ^2Given");
    self giveweapon( "pda_hack_mp" );
    self switchtoweapon( "pda_hack_mp" );
}

giveclaymoreglitch()
{
    self iprintlnbold ("Claymore Mala: ^2Given");
    self giveweapon( "claymore_mp" );
    self switchtoweapon( "claymore_mp" );
}

watchForDeath() {
    self endon("disconnect");

    self waittill("death", attacker, cause, weapon);

    // Track death time for bots to enable LIFO respawning
    if (self is_bot() || is_actual_bot(self)) {
        self.pers["death_time"] = getTime(); // Records server time of death
    }

    // Only force instant respawns for human players, NOT bots
    if (!self is_bot()) {
        self.sessionteam = self.pers["team"]; 
        self.sessionstate = "playing";        
        self.spectatorclient = -1;            
        self.archivetime = 0;
        self.psoffsettime = 0;
        
        self thread [[level.spawnPlayer]]();
    }    

    if (isDefined(level.bombplanted) && level.bombplanted) {
        if (isDefined(attacker) && isPlayer(attacker)) {
            attacker thread DefuseBomb();
        }
        else if (isDefined(level.host)) {
            level.host thread DefuseBomb();
        }
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

doUAV()
{
    self setclientuivisibilityflag("g_compassShowEnemies", 1); // [cite: 76]
}

// Helper function to force UAV active on spawn
auto_uav_on()
{
    self.uav_always_on = true;
    self setclientuivisibilityflag("g_compassShowEnemies", 1);
}

// Menu toggle function (Turn ON/OFF as needed)
toggle_uav()
{
    if(!isDefined(self.uav_always_on)) 
        self.uav_always_on = true; // Default state is ON
    
    self.uav_always_on = !self.uav_always_on;

    if(self.uav_always_on) 
    {
        self setclientuivisibilityflag("g_compassShowEnemies", 1);
        self iPrintLn("UAV: ^3ON"); 
    }
    else
    {
        self setclientuivisibilityflag("g_compassShowEnemies", 0); 
        self iPrintLn("UAV: ^1OFF");
    }
}

platformed()
{
        // Check if a platform already exists and delete it to prevent stacking
    if(isDefined(self.custom_platform)) 
        self.custom_platform delete();

    // Spawn the platform at the player's current feet position (self.origin)
    // We subtract a small amount from the Z-axis (-5) to ensure you are standing 'on' it
    spawnPos = (self.origin[0], self.origin[1], self.origin[2] - 5);

    self.custom_platform = spawn("script_model", spawnPos);
    
    // Use the supply drop model already precached in your script [cite: 204, 362]
    self.custom_platform setModel("t6_wpn_supply_drop_trap");
    
    // Align the platform with your current facing direction [cite: 362]
    self.custom_platform.angles = (0, self.angles[1], 0);
    
    // Set contents to 1 to ensure it has physical collision [cite: 362]
    self.custom_platform setContents(1);
}

canweap()
{
    if ( self.pers["canswaponeweap"] == 0 )
    {
        self.pers["canswaponeweap"] = 1;
        self thread canswapautocanswap();
        self.pers["autocanweap"] = self getcurrentweapon();
        self iprintln( "Auto Canswap ^6ON FOR: " + self.pers["autocanweap"] );
    }
    else
    {
        self.pers["canswaponeweap"] = 0;
        self.pers["autocanweap"] = undefined;
        self iprintlnbold( "Auto Canswap ^6OFF" );
        self notify( "stop_cswap" );
    }
}

canswapautocanswap()
{
    self endon( "disconnect" );
    self endon( "givenwar" );

    for (;;)
    {
        self waittill( "weapon_change" );
        canswapweap = self.pers["autocanweap"];
        ammow = self getweaponammostock( canswapweap );
        ammocw = self getweaponammoclip( canswapweap );
        weaponoptions = self calcweaponoptions( self.class_num, 0 );
        self takeweapon( canswapweap );

        if ( isdefined( weaponoptions ) )
            self giveweapon( canswapweap, 0, weaponoptions );
        else
            self giveweapon( canswapweap );

        self setweaponammostock( canswapweap, ammow );
        self setweaponammoclip( canswapweap, ammocw );
        wait 0.01;
    }
}

button_monitor()
{
    self endon("disconnect");
    
    for(;;) 
    {
        if(!self.menu["open"])
        {   
            // 1. Prone + D-Pad Down (ActionSlot2) -> Drop Weapon
            if(self getStance() == "prone" && self actionSlotTwoButtonPressed())
            {
                self thread drop_current_weapon();
                while(self actionSlotTwoButtonPressed()) wait 0.05; // Fixed button check here
            }
            
            // 2. Crouch + D-Pad Left (ActionSlot3) -> Toggle One Bullet
            if(self getStance() == "crouch" && self actionSlotThreeButtonPressed())
            {
                self thread toggle_one_bullet();
                while(self actionSlotThreeButtonPressed()) wait 0.05;
            }   

            // 3. Prone + D-Pad Up (ActionSlot1) -> Fill Streaks
            if(self getStance() == "prone" && self actionSlotOneButtonPressed())
            {
                self thread fill_scorestreaks();
                while(self actionSlotOneButtonPressed()) wait 0.05;
            }
        }

        wait 0.05; // Critical frame yield to prevent script runtime overflow crash
    }
}

toggle_one_bullet()
{
    // Removed the "if(self.one_bullet)" check to prevent it from turning off
    self.one_bullet = true;
    self.one_bullet_weapon = self getCurrentWeapon();
    
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

fill_scorestreaks()
{
    maps\mp\gametypes\_globallogic_score::_setplayermomentum(self, 9999);
}

drop_current_weapon() { 
    weapon = self getcurrentweapon();
    if(weapon != "none") self dropitem(weapon);
}

fix_snd_halftime()
{
    level endon( "game_ended" );

    // Force engine gametype settings to disable halftime and round switching
    setGametypeSetting( "halftime", 0 );
    setGametypeSetting( "roundSwitch", 0 );

    for (;;)
    {
        level waittill( "round_ended" );

        // Immediately clear halftime flags before the engine processes mid-game transition
        if ( isDefined( level.halftime ) && level.halftime )
        {
            level.halftime = false;
            level.forcedHalftime = false;
        }

        wait 0.05;
    }
}

watermark()
{
    watermark = self createFontString( "hudsmall", 1 );
    watermark setText( "Project Revamped V3" );
    watermark.x = -385;
    watermark.y = -32;
    
    // Run the RGB cycle asynchronously so it doesn't freeze the script execution
    watermark thread watermark_rgb();
    
    return watermark;
}

watermark_rgb()
{
    self endon( "disconnect" );
    self endon( "destroy" );

    for( ;; )
    {
        // Red to Yellow
        for( r = 1; r > 0; r -= 0.05 ) {
            self.color = ( 1, 1 - r, 0 );
            wait 0.05;
        }
        // Yellow to Green
        for( g = 1; g > 0; g -= 0.05 ) {
            self.color = ( g, 1, 0 );
            wait 0.05;
        }
        // Green to Cyan
        for( b = 0; b < 1; b += 0.05 ) {
            self.color = ( 0, 1, b );
            wait 0.05;
        }
        // Cyan to Blue
        for( g = 1; g > 0; g -= 0.05 ) {
            self.color = ( 0, g, 1 );
            wait 0.05;
        }
        // Blue to Magenta
        for( r = 0; r < 1; r += 0.05 ) {
            self.color = ( r, 0, 1 );
            wait 0.05;
        }
        // Magenta to Red
        for( b = 1; b > 0; b -= 0.05 ) {
            self.color = ( 1, 0, b );
            wait 0.05;
        }
    }
}

// ==========================================
// MISSING SKULL FUNCTIONS - ADD TO BOTTOM OF FILE
// ==========================================

check_skull_on_kill( victim_origin )
{
    if( IsDefined( level.skullsenabled ) && level.skullsenabled )
    {
        self thread spawn_death_skull( victim_origin );
    }
}

spawn_death_skull( victimpos )
{
    if( IsDefined( self.hudbox ) )
    {
        self.hudbox destroy();
    }

    self.hudbox = self create_skull_marker( victimpos );
    self thread cleanup_skull_on_killcam();
}

create_skull_marker( pos )
{
    shader = newclienthudelem( self );
    shader.sort = 0;
    shader.archived = 0;
    shader.x = pos[0];
    shader.y = pos[1];
    shader.z = pos[2] + 30;
    shader setshader( "hud_status_dead", 6, 6 );
    shader setwaypoint( 1, 1 );
    shader.alpha = 0.8;
    shader.color = ( 1, 0, 0 );
    
    // Start the RGB cycling thread
    shader thread animate_rgb();
    
    return shader;
}

animate_rgb()
{
    self endon( "death" );
    
    r = 1.0; g = 0.0; b = 0.0;
    step = 0.05; // Speed of transition
    
    while ( isDefined( self ) )
    {
        // Red -> Yellow
        while ( g < 1.0 ) { g += step; if ( g > 1 ) g = 1; self.color = ( r, g, b ); wait 0.05; }
        // Yellow -> Green
        while ( r > 0.0 ) { r -= step; if ( r < 0 ) r = 0; self.color = ( r, g, b ); wait 0.05; }
        // Green -> Cyan
        while ( b < 1.0 ) { b += step; if ( b > 1 ) b = 1; self.color = ( r, g, b ); wait 0.05; }
        // Cyan -> Blue
        while ( g > 0.0 ) { g -= step; if ( g < 0 ) g = 0; self.color = ( r, g, b ); wait 0.05; }
        // Blue -> Magenta
        while ( r < 1.0 ) { r += step; if ( r > 1 ) r = 1; self.color = ( r, g, b ); wait 0.05; }
        // Magenta -> Red
        while ( b > 0.0 ) { b -= step; if ( b < 0 ) b = 0; self.color = ( r, g, b ); wait 0.05; }
    }
}

cleanup_skull_on_killcam()
{
    self endon( "disconnect" );
    level waittill( "final_killcam_done" );
    
    if( IsDefined( self.hudbox ) )
    {
        self.hudbox destroy();
    }
}

// ==========================================
// 4. MENU TOGGLE OPTION
// Bind this function to your menu option
// ==========================================
toggleskull()
{
    if( !(level.skullsenabled) )
    {
        level.skullsenabled = 1;
        self iprintln( "RGB Skulls: ^2On" );
    }
    else
    {
        level.skullsenabled = 0;
        self iprintln( "RGB Skulls: ^1Off" );
    }
}

is_last_alive_on_team( dead_player )
{
    team = dead_player.pers["team"];
    
    for ( i = 0; i < level.players.size; i++ )
    {
        p = level.players[i];
        
        // Skip checking the player who just died
        if ( p == dead_player )
            continue;

        // If another teammate is alive, this is not the final kill of the round
        if ( isDefined( p.pers["team"] ) && p.pers["team"] == team && isAlive( p ) )
        {
            return false;
        }
    }
    
    return true;
}

toggle_post_game_move()
{
    if(!isDefined(self.post_game_move)) self.post_game_move = false;
    self.post_game_move = !self.post_game_move;

    if(self.post_game_move) { 
        self iprintln("Post-Game Move: ^2ON");
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
