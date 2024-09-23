#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

main()
{
	replacefunc( maps\mp\gametypes\_globallogic_player::finishplayerdamagewrapper, ::finishplayerdamagewrapper );
}

init()
{
	set_dvar_if_unset( "scr_killstreak_print", 0 );
	set_dvar_if_unset( "scr_printDamage", false );
	set_dvar_if_unset( "scr_showHP", false );
	
	level.showHP = getDvarInt( "scr_showHP" );
	level.killstreakPrint = getDvarInt( "scr_killstreak_print" );
	level.allowPrintDamage = getDvarInt( "scr_printDamage" );
	
	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for ( ;; )
	{
		level waittill( "connected", player );
		
		player thread onPlayerSpawned();
	}
}

onPlayerSpawned()
{
	self endon( "disconnect" );
	
	self.printDamage = true;
	
	for ( ;; )
	{
		self waittill( "spawned_player" );
		
		if ( level.killstreakPrint )
		{
			self thread watchNotifyKSMessage();
		}
		
		if ( level.showHP )
		{
			self thread drawHP();
		}
	}
}

watchNotifyKSMessage()
{
	self endon( "disconnect" );
	self endon( "death" );
	
	for ( lastKs = self.pers["cur_kill_streak"];; )
	{
		wait 0.05;
		
		for ( curStreak = lastKs + 1; curStreak <= self.pers["cur_kill_streak"]; curStreak++ )
		{
			//if (curStreak == 5)
			//	continue;
			
			if ( curStreak % 5 != 0 )
			{
				continue;
			}
			
			self thread streakNotify( curStreak );
		}
		
		lastKs = self.pers["cur_kill_streak"];
	}
}

streakNotify( streakVal )
{
	self endon( "disconnect" );
	
	notifyData = spawnStruct();
	
	if ( level.killstreakPrint > 1 )
	{
		xpReward = streakVal * 100;
		
		self thread maps\mp\gametypes\_rank::giveRankXP( "killstreak_bonus", xpReward );
		
		notifyData.notifyText = "+" + xpReward;
	}
	
	wait .05;
	
	notifyData.titleLabel = &"MP_KILLSTREAK_N";
	notifyData.titleText = streakVal;
	
	self maps\mp\gametypes\_hud_message::notifyMessage( notifyData );
	
	iprintln( &"RANK_KILL_STREAK_N", self, streakVal );
}

doPrintDamage( dmg, hitloc, flags )
{
	self endon( "disconnect" );
	
	huddamage = newclienthudelem( self );
	huddamage.alignx = "center";
	huddamage.horzalign = "center";
	huddamage.x = 10;
	huddamage.y = 235;
	huddamage.fontscale = 1.6;
	huddamage.font = "objective";
	huddamage setvalue( dmg );
	
	if ( ( flags & level.iDFLAGS_RADIUS ) != 0 )
	{
		huddamage.color = ( 0.25, 0.25, 0.25 );
	}
	
	if ( ( flags & level.iDFLAGS_PENETRATION ) != 0 )
	{
		huddamage.color = ( 1, 1, 0.25 );
	}
	
	if ( hitloc == "head" )
	{
		huddamage.color = ( 1, 0.25, 0.25 );
	}
	
	huddamage moveovertime( 1 );
	huddamage fadeovertime( 1 );
	huddamage.alpha = 0;
	huddamage.x = randomIntRange( 25, 70 );
	
	val = 1;
	
	if ( randomInt( 2 ) )
	{
		val = -1;
	}
	
	huddamage.y = 235 + randomIntRange( 25, 70 ) * val;
	
	wait 1;
	
	if ( isDefined( huddamage ) )
	{
		huddamage destroy();
	}
}

finishplayerdamagewrapper( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime, boneindex )
{
	pixbeginevent( "finishPlayerDamageWrapper" );
	
	if ( isDefined( level.allowPrintDamage ) && level.allowPrintDamage )
	{
		if ( !isDefined( eattacker ) )
		{
			if ( !isDefined( einflictor ) && isDefined( self.printDamage ) && self.printDamage )
			{
				self thread doPrintDamage( idamage, shitloc, idflags );
			}
		}
		else if ( isPlayer( eattacker ) && isDefined( eattacker.printDamage ) && eattacker.printDamage )
		{
			eattacker thread doPrintDamage( idamage, shitloc, idflags );
		}
		else if ( isDefined( eattacker.owner ) && isPlayer( eattacker.owner ) && isDefined( eattacker.owner.printDamage ) && eattacker.owner.printDamage )
		{
			eattacker.owner thread doPrintDamage( idamage, shitloc, idflags );
		}
	}
	
	if ( !level.console && idflags & level.idflags_penetration && isplayer( eattacker ) )
	{
/#
		println( "penetrated:" + self getentitynumber() + " health:" + self.health + " attacker:" + eattacker.clientid + " inflictor is player:" + isplayer( einflictor ) + " damage:" + idamage + " hitLoc:" + shitloc );
#/
		eattacker addplayerstat( "penetration_shots", 1 );
	}
	
	self finishplayerdamage( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime, boneindex );
	
	if ( getdvar( #"scr_csmode" ) != "" )
	{
		self shellshock( "damage_mp", 0.2 );
	}
	
	self damageshellshockandrumble( eattacker, einflictor, sweapon, smeansofdeath, idamage );
	pixendevent();
}

initHPdraw()
{
	self endon( "disconnect" );

	self.drawHP = self createFontString( "default", 1.2 );
	self.drawHP setPoint( "BOTTOM RIGHT", "BOTTOM RIGHT", -150, -20 );
	
	self.drawSpeed = self createFontString( "default", 1.2 );
	self.drawSpeed setPoint( "BOTTOM RIGHT", "BOTTOM RIGHT", -150, -10 );
	
	self waittill( "death" );
	
	if ( isDefined( self.drawHP ) )
	{
		self.drawHP destroy();
	}
	
	if ( isDefined( self.drawSpeed ) )
	{
		self.drawSpeed destroy();
	}
}

drawHP()
{
	self endon( "disconnect" );
	self endon( "death" );
	self thread initHPdraw();
	
	for ( ;; )
	{
		//self.drawHP setText("HP: "+self.health+"  KS: "+self.pers["cur_kill_streak"]);
		self.drawHP setValue( self.health );
		
		vel = self getVelocity();
		self.drawSpeed setValue( int( length( ( vel[0], vel[1], 0 ) ) ) );
		wait 0.05;
	}
}
