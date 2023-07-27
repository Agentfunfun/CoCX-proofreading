package classes.Scenes.Crafting {
import classes.BaseContent;
import classes.ItemSlotClass;
import classes.Items.Alchemy.AlchemyComponent;
import classes.Items.Alchemy.AlchemyLib;
import classes.Items.Alchemy.AlembicCatalyst;
import classes.Items.Consumable;
import classes.Scenes.Crafting;
import classes.Scenes.SceneLib;
import classes.internals.EnumValue;

import coc.view.CoCButton;

import flash.utils.Dictionary;

public class AlchemyExtraction extends BaseContent {
    
    public static const ALEMBIC_LEVELS:/*EnumValue*/Array = [];
    public static const ALEMBIC_LEVEL_NONE:int = EnumValue.add(ALEMBIC_LEVELS, 0, "NONE", {
        name: "no alembic",
        successChance: 0
    });
    public static const ALEMBIC_LEVEL_SIMPLE:int = EnumValue.add(ALEMBIC_LEVELS, 1, "SIMPLE", {
        name: "simple alembic",
        successChance: 25
    });
    public static const ALEMBIC_LEVEL_GOOD:int = EnumValue.add(ALEMBIC_LEVELS, 2, "GOOD", {
        name: "good alembic",
        successChance: 50
    });
    public static const ALEMBIC_LEVEL_ANCIENT:int = EnumValue.add(ALEMBIC_LEVELS, 3, "ANCIENT", {
        name: "ancient alembic",
        successChance: 75
    });
    
    
    
    public function AlchemyExtraction() {
	}
    private function get alembicLevel():int {
        return Crafting.alembicLevel;
    }
    private function get alembicCatalyst():AlembicCatalyst {
        return Crafting.alembicCatalyst;
    }
    private function set alembicCatalyst(value:AlembicCatalyst):void {
        Crafting.alembicCatalyst = value;
    }
    
    
    public function alembicName():String {
        return ALEMBIC_LEVELS[alembicLevel].name;
    }
    public function alembicObject():EnumValue {
        return ALEMBIC_LEVELS[alembicLevel];
    }
    
    private var alembicItem:Consumable = null;
    private var alembicItemCount:int = 0;
    public function alembicCapacity():int {
        return 10;
    }
    // Number of component rolls per ingredient
    public function alembicYield():int {
        return 2;
    }
    
    // [failureChance, substanceChance, essenceChance, residueChance, pigmentChance]
    private function calcChances():/*Number*/Array {
        var result:/*Number*/Array = [100,0,0,0,0];
        var successChance:Number = alembicObject().successChance;
        // TODO @aimozg also affected by skill?
        successChance = boundFloat(0, successChance, 100);
        result[0] = 100 - successChance;
        var n:int = 4;
        if (alembicItem && !alembicItem.substances) n--;
        if (alembicItem && !alembicItem.essences) n--;
        if (alembicItem && !alembicItem.residues) n--;
        if (alembicItem && !alembicItem.pigments) n--;
        result[1] = successChance/n;
        result[2] = successChance/n;
        result[3] = successChance/n;
        result[4] = successChance/n;
        if (alembicCatalyst != null) {
            result[alembicCatalyst.componentType] *= alembicCatalyst.chanceFactor;
        }
        if (alembicItem) {
            if (!alembicItem.substances) result[AlchemyLib.CT_SUBSTANCE] = 0;
            if (!alembicItem.essences) result[AlchemyLib.CT_ESSENCE] = 0;
            if (!alembicItem.residues) result[AlchemyLib.CT_RESIDUE] = 0;
            if (!alembicItem.pigments) result[AlchemyLib.CT_PIGMENT] = 0;
        }
        return normalizeArray(result,100);
    }
    
    public function extractionMenu(inventoryPage:int = 0, usePearl:Boolean =false):void {
        clearOutput();
        if (alembicItemCount > 0) {
            outputText("You have "+alembicItemCount+" x "+alembicItem.longNameBase);
            if (alembicCatalyst) {
                outputText(" and "+alembicCatalyst.longName);
            }
            outputText(" in your "+alembicName()+". ");
        } else if (alembicCatalyst) {
            outputText("Your "+alembicName()+" is empowered by "+alembicCatalyst.longName+", but doesn't contain any processable material. ")
        } else {
            outputText("Your "+alembicName()+" is empty. ")
        }
        outputText("\n\n");
        
        var chances:/*Number*/Array = calcChances();
        outputText("<b>Tool quality</b>: "+alembicName());
        outputText("\n<b>Catalyst</b>: "+(alembicCatalyst?alembicCatalyst.longName:"<i>none</i>"));
        outputText("\n<b>Ingredient</b>: "+(alembicItem?alembicItemCount+" x "+alembicItem.longNameBase:"<i>none</i>"));
        // TODO @aimozg alchemy skill
        outputText("\n<b>Refinement chances</b>:");
        outputText("<ul>");
        if (chances[0] > 0) outputText("<li>Failure: "+floor(chances[0])+"%</li>");
        if (chances[1] > 0) outputText("<li>Substance: "+floor(chances[1])+"%</li>");
        if (chances[2] > 0) outputText("<li>Essence: "+floor(chances[2])+"%</li>");
        if (chances[3] > 0) outputText("<li>Residue: "+floor(chances[3])+"%</li>");
        if (chances[4] > 0) outputText("<li>Pigment: "+floor(chances[4])+"%</li>");
        outputText("</ul>");
        outputText("<b>Yield</b>: x"+alembicYield());
        outputText("\n\n");
        
        // [Extract!] [        ] [TakeItem] [Take Cat] [        ]
        // [ item1  ] [ item2  ] [ item3  ] [ item4  ] [ item5  ]
        // [ < prev ] [Inv/Pear] [ next > ] [        ] [ Back   ]
        menu();
        
        button(0).show("Extract!", doExtract)
                 .hint("Perform the extraction. " +
                         "The ingredient" + (alembicItemCount>1?"s":"") +" will be destroyed.")
                 .disableIf(alembicItem == null, "You need to put an ingredient into the alembic!");
        button(2).show("Take Ingred.", takeIngredient)
                 .hint("Put "+(alembicItem?alembicItem.longName:"the ingredient")+" back into inventory.\n\nHold Shift to take all.")
                 .disableIf(alembicItem == null);
        button(3).show("Take Catalyst", takeCatalyst)
                 .hint("Put "+(alembicCatalyst?alembicCatalyst.longName:"the alembic catalyst")+" back into inventory.")
                 .disableIf(alembicCatalyst == null);
        
        var storage:/*ItemSlotClass*/Array;
        if (usePearl) {
            storage = inventory.pearlStorageSlice();
        } else {
            storage = player.itemSlots.slice(0, player.itemSlotCount());
        }
        var i:int;
        var offset:int = inventoryPage*5;
        for (i = 0; i < 5; i++) {
            var slot:ItemSlotClass = storage[offset+i];
            if (!slot) continue;
            var isIngredient:Boolean = (slot.itype is Consumable) && (slot.itype as Consumable).isRefinable;
            var btn:CoCButton = button(5+i).showForItemSlot(slot, curry(putItem, slot, inventoryPage, usePearl));
            if (slot.itype is AlembicCatalyst) {
                if (alembicCatalyst != null) {
                    btn.disable("Only one catalyst is allowed!")
                }
            } else if (isIngredient) {
                if (alembicItem != null && alembicItem != slot.itype) {
                    btn.disable("You cannot mix ingredients!");
                } else if (alembicItemCount >= alembicCapacity()) {
                    btn.disable("You cannot refine more ingredients at once!");
                }
            } else {
                btn.disable("This item cannot be refined and is not a catalyst.");
            }
        }
        button(10).show("Prev", curry(extractionMenu, inventoryPage-1, usePearl))
                  .icon("Left")
                  .disableIf(inventoryPage == 0);
        button(11).show("Inv/Pearl", curry(extractionMenu, 0, !usePearl))
        
        button(12).show("Next", curry(extractionMenu, inventoryPage+1, usePearl))
                  .icon("Right")
                  .disableIf(inventoryPage >= Math.ceil(storage.length/5)-1);
        
        button(14).show("Back", SceneLib.crafting.craftingMain)
                  .icon("Back")
                  .disableIf(alembicItem != null, "Empty the alembic first!")
    }
    private function doExtract():void {
        clearOutput();
        outputText("You dissolve the "+alembicItem.longNameBase+" in the mixture and start the fire. You calmly watch the fumes raise and condense...\n\n");
        
        var chances:/*Number*/Array = calcChances();
        // AlchemicComponent -> quantity
        var results:Dictionary = new Dictionary();
        var failures:int = 0;
        var successes:int = 0;
        var ac:AlchemyComponent;
        for (var i:int = 0; i < alembicYield()*alembicItemCount; i++) {
            ac = alembicItem.refine(chances);
            if (ac) {
                successes++;
                if (ac in results) results[ac]++;
                else results[ac] = 1;
            } else {
                failures++;
            }
        }
        if (successes == 0) {
            outputText("Unfortunately, the refining process resulted in a <b>complete failure</b>!\n");
            outputText("You've 'refined' "+
                    (alembicItemCount > 1
                            ? alembicItemCount+" x "+alembicItem.longNameBase
                            : alembicItem.longName) +
                    " into "+numberOfThings(failures,"blob","blobs")+" of stinky goo...");
        } else {
            if (failures == 0) {
                outputText("The refining process was a <b>complete success</b>!\n");
            }
            outputText("You've refined "+alembicItemCount+" x "+alembicItem.longNameBase+" into");
            var list:Array = objectEntries(results);
            if (list.length == 1) {
                ac = list[0][0];
                outputText(" "+numberOfThings(list[0][1], ac.name()))
                SceneLib.crafting.addAlchemyComponent(ac, list[0][1]);
            } else {
                outputText(":<ul>");
                for (i = 0; i < list.length; i++) {
                    ac = list[i][0];
                    outputText("<li>"+numberOfThings(list[i][1], ac.name())+"</li>")
                    SceneLib.crafting.addAlchemyComponent(ac, list[i][1]);
                }
                outputText("</ul>");
            }
            if (failures > 0) {
                if (list.length == 1) outputText(" "); else outputText("...");
                outputText("and "+numberOfThings(failures,"blob","blobs")+" of stinky goo");
            }
            if (list.length == 1) outputText(".");
        }
        
        // TODO @aimozg passage of time?
        alembicItem = null;
        alembicItemCount = 0;
        doNext(extractionMenu);
    }
    private function putItem(slot:ItemSlotClass, inventoryPage:int, usePearl:Boolean):void {
        if (slot.itype is AlembicCatalyst) {
            alembicCatalyst = slot.itype as AlembicCatalyst;
            slot.removeOneItem();
        } else if (slot.itype is Consumable) {
            alembicItem = slot.itype as Consumable;
            var n:int = shiftKeyDown ? Math.min(slot.quantity, alembicCapacity()-alembicItemCount) : 1;
            slot.removeMany(n);
            alembicItemCount += n;
        }
        extractionMenu(inventoryPage, usePearl);
    }
    private function takeIngredient():void {
        var n:int = shiftKeyDown ? alembicItemCount : 1;
        var menuFn:Function = extractionMenu;
        while (n-->0 && alembicItemCount > 0) {
            alembicItemCount--;
            if (inventory.tryAddItemToPlayer(alembicItem) == 0) {
                inventory.takeItem(alembicItem, menuFn);
                menuFn = null;
                break;
            }
        }
        if (alembicItemCount == 0) alembicItem = null;
        if (menuFn != null) menuFn();
    }
    private function takeCatalyst():void {
        if (inventory.tryAddItemToPlayer(alembicCatalyst) == 0) {
            inventory.takeItem(alembicCatalyst, extractionMenu);
            alembicCatalyst = null;
        } else {
            alembicCatalyst = null;
            extractionMenu();
        }
    }
    
}
}
