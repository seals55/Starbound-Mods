=== TABULA RASA V2.0 ===

By:         LowestFormOfWit and SnoopJeDi

License:
This work is licensed under the Creative Commons Attribution 3.0 United States License. To view a copy of this license, visit http://creativecommons.org/licenses/by/3.0/us/ or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.

Basically, as long as you give us credit, link to the Creative Commons license, and indicate any changes (all of which can be done in a readme file), you can do whatever you want with this mod.


== DESCRIPTION ==

The Tabula Rasa is designed to be a unified crafting bench for mod content.
Modders can tag their recipes with "mod" to add it to the tablet, allowing players to access the additional content without player.config patches.  Modders can now also organize their content using additional tags and filter buttons in the crafting menu.

Note that the Tabula Rasa will display any associated recipes regardless of whether the blueprint is known, so it is a poor choice for progression-driven content where the modder wants recipes to 'unlock' as the player progresses.  You can, however, design your recipes so that the ability to craft is limited to certain tiers.  This mod instead focuses primarily on helping others share their creations.

We have tested this version of the mod with v. Furious Koala, although it should remain compatible with the game in future versions.

Thank you all for using the Tabula Rasa. We continue to be amazed at the warm reception of such a simple mod, and want to continue to provide a common point of mod integration and organization for mod developers, end-users, and anything in-between.


== INSTALLATION & USAGE ==

1. Extract "TabulaRasaV2.0.zip" into the main Starbound folder.
2. Verify that the "tabularasa2.0" folder is in the 'Starbound/mods' directory. If not, you may have extracted the archive to the wrong folder.
3. Once the folder has been placed correctly, launch Starbound. 
4. On any character, open the personal crafting menu (default 'c'), and craft the Tabula Rasa for a cost of 1 pixel. 
5. Place the tablet in the game world.  It can now be used to craft any recipes that include "mod" in their group list. 
	5a. If you have no recipes tagged "mod", nothing will show up here. We have included an additional example item that you can tag with "mod" to test for yourself!

== HOW TO USE THE TABULA RASA ==

1. Add the "mod" keyword to the recipe group list.   If you want to use a custom filter category in addition to "mod," add it as well (see more below)
1a. For example: to make the 'stonepickaxe' item, change this line in 'stonepickaxe.recipe':

		"groups" : [ "craftingtable", "tools", "all" ]
	To:
		"groups" : [ "mod", "craftingtable", "tools", "all" ]
		
2. That's it! You should see your recipe available in the Tabula Rasa.		

Items with the "mod" tag will still be craftable on other objects if the group keyword is set correctly, but may not show up in the interface if the blueprint for them is not known.  This is the key difference - the Tabula Rasa will show any item associated with it, regardless of whether the player knows the blueprint for it, which obviates the need for changes to player.config.  Of course, now with the __merge system (see http://community.playstarbound.com/index.php?threads/overriding-and-merging-config-files-in-mods.53775/), this problem can be gotten around in other methods.  However, we will continue to update Tabula Rasa to provide a way for mod authors to allow their mods to be organized on a unified interface.

The 'imperfectlygenericitem' item and recipe are included with the tablet to provide an additional example of use. 
To use this example, open "imperfectlygenericitem.recipe" found in the "recipes" folder of this mod. Add "mod" to the 'groups' line and voila!


== MAKING A CUSTOM FILTER BUTTON FOR TABULA RASA ==

1. Create a folder structure in your mod so it appears like this: "<YOURMODNAMEHERE>/objects/wired/tabularasa/".
2. Copy over the file "tabularasa.object.example" file from the "tabularasa2.0/Templates/" directory to this new directory you made above in step 1.
3. Rename this file "tabularasa.object". Verify that the file path is: "<YOURMODNAMEHERE>/objects/wired/tabularasa/tabularasa.object".
4. Open this "tabularasa.object" in Notepad++ or equivalent.
5. Go to this section of the file: 
	
			"baseImage" : "/path/to/mybutton.png",
			"baseImageChecked" : "/path/to/mybuttonchecked.png",
			"filter" : "mymodkeyword"
	
	5a. If you want to use a custom artwork for your filter button, copy the example button templates provided in the main "tabularasa2.0" directory, labelled "buttontemplateGREY.png" and "buttontemplateGOLD.png" to your mod directory. 
	5b. If you do not wish to make custom art for your button, simply remove the "baseImage" and "baseImageChecked" lines ENTIRELY, and Tabula Rasa will automatically load a generic button labelled "Mod Icon Missing" as a placeholder.
	5c. Fill in the empty space provided in each of these buttons with whatever you feel will identify your button, and save as a transparent.PNG file. Change the names, but make a distinction between the GREY border button and the GOLD border button. The images should be 60x18px to maintain a uniform appearance to the menu.  Don't exceed this or you will break other mod filters and your users will be sad!
	5d. Change the example filepath above for "baseImage" to the path to your GREY BORDER button you made in step 5c. 
	5e. Change the example filepath above for "baseImageChecked" to the path to your GOLD BORDER button you made in step 5c. 
	5f. Change the "filter" to a new, unique tag. This is the tag the button will search your recipes for to filter the Tabula Rasa.
	
6. Change however many recipe files you want to add to your new Custom Filter Button by adding your unique tag you chose in step 5f. to the recipe's "groups" list.
	6a. For example, if your recipe file looks like this:
	
			"groups" : [ "mod", "tools", "all" ]
Change it to this:
			"groups" : [ "mod", "mymodkeyword", "tools", "all" ]
			
7. That's it! Your custom filter button should show up on the right pane of Tabula Rasa labelled "MODS". If it does not, go back through these steps thoroughly and check your work again. 

The Tabula Rasa will automatically load any Custom Filter Buttons from any installed mods and organize them for you, so it always looks good!  
In V2.0, Tabula Rasa has a hard limit of 22 filter buttons that can be displayed in this way, and will notify you how many aren't being shown due to the excess. This hard cap may change in the future when the developers expose more of the UI system to modders.

== COMPATABILITY ==
  
If you would like Tabula Rasa to be -required- to run your mod (as opposed to optional), make sure your .modinfo file lists "tabularasa2.0" as a dependency.  
See "tabularasa2.0/Templates/" for the "derivativemod.modinfo.example" file for an example.
 
Version 2.0 represents a large change in both Starbound and Tabula Rasa, and as such, Tabula Rasa 2.0 is NOT backwards compatible with previous versions.

== CHANGELOG ==
2.0 (hotfix) - tabularasa.object now includes __merge, so dependencies are now NOT necessary
2.0 - Added custom filter buttons - Tabula Rasa switched to scripted object
1.5 - __merge integration, recipe changed to plain, 1 pixel.  Dependency versioning workaround implemented.  Tablet can no longer be crafted on itself.
1.4 - Stopgap update to make Tabula Rasa immediately available for Angry Koala
1.3 - Minor grammatical errors and frame errors fixed. Graphic updated. Imperfectly Generic Item made as an optional additional example. Duplicate Tabula Rasas crafted from a Tabula Rasa now cost 1 pixel instead of additonal torches.
1.2 - Re-upload of 1.1 due to technical problems. Identical to 1.1.
1.1 - Updated installation to use new mod system
1.0 - Initial version.
