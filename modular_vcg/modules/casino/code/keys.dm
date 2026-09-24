/obj/item/vamp/keys/proc/opens_door_in(area/target_area)
	for(var/obj/structure/vampdoor/door in target_area)
		if(door.lock_id in accesslocks)
			return TRUE
	return FALSE

/proc/area_has_locked_door(area/target_area)
	for(var/obj/structure/vampdoor/door in target_area)
		if(door.lock_id && door.lock_id != LOCKACCESS_ALL)
			return TRUE
	return FALSE
