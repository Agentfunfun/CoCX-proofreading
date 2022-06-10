package classes.Races {
import classes.BodyData;
import classes.BodyParts.*;
import classes.CockTypesEnum;
import classes.Race;
import classes.Races;

public class AntRace extends Race {
    public static const AntBadEar:/*String*/Array = ["Avian"];
    	
	public function AntRace(id:int) {
		super("Ant", id);
		chimeraTier = 0;
		grandChimeraTier = 0;
	}
	
	public override function setup():void {
		
		addScores()
				.faceType(NOT(Face.HUMAN), 0, -1)
                .faceType(Face.ANT, +2)//Ant face suffers "not human" so plus 2 to counteract
				.hornType(Horns.NONE), +1)
                .earType(ANY(Ears.HoleEars, Ears.HUMAN), +1, -1)
                .earType(NONE(Ears.HUMAN, Ears.AVIAN), 0, -1)//Avian and Human balance to 0
				.skinCoatType(Skin.CHITIN, +1)
				.armType(Arms.ANT, +1)
				.legType(lowerBody.SPIDER, +1)
                .legType(lowerBody.ANT, +2)
				.hasCockOfType(CockTypesEnum.INSECT, +1)
				.wingType(ANY(Wings.ANT_SMALL, Wings.BEE_SMALL, Wings.BEE_LARGE), +1)
				.wingType(Wings.ANT_LARGE, +2)
				
		
		buildTier(8, "ant-morph")
				.buffs({
					"str.mult": +1.00
                    "tou.mult": +0.70,
					"int.mult": -0.70,
                    "wis.mult": -0.60
				})
				.end();
		
		buildTier(5, "plant-morph")
				.buffs({
					"str.mult": +0.10,
					"tou.mult": +0.50,
					"spe.mult": -0.20,
					"def": +4
				})
				.end();
	}
}
}
