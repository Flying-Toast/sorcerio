import wiziz.gameServer.spell;
import wiziz.gameServer.spells.base.splash;
import wiziz.gameServer.player;
import wiziz.gameServer.event;
import wiziz.gameServer.server;

class BlindSpell : SplashSpell {
	mixin registerSpell!(SpellName.blind, 4500);

	private enum duration = 2000;///how long it takes for the effect to wear off

	override string humanReadableEffect() {
		import std.conv;
		return "Affected players become \"blinded\" and their screens go dark for " ~ (duration / 1000).to!string ~ " seconds";
	}

	override void initialize() {
		speed = 0.7;
		range = 700;
		radius = 10;
		explosionRadius = 140;
		color = "#000";
		explosionTTL = 4000;
		effectDelay = duration;//make `effectDelay` the same as `duration` so a player can be affected again immediately after the effect wears off
		super.initialize();
	}

	override void splashAffect(Player player) {
		player.effectFlags["blind"] = true;
		EventManager.registerEvent(duration, delegate void (Server) {
			player.effectFlags.remove("blind");
		});
	}
}
