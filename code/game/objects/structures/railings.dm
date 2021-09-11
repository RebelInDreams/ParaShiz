/obj/structure/railing
	name = "railing"
	desc = "Basic railing meant to protect idiots like you from falling."
	icon = 'icons/obj/fence.dmi'
	icon_state = "railing"
	density = TRUE
	anchored = TRUE
	pass_flags = LETPASSTHROW
	climbable = TRUE
	layer = ABOVE_MOB_LAYER
	var/currently_climbed = FALSE

/obj/structure/railing/corner //aesthetic corner sharp edges hurt oof ouch
	icon_state = "railing_corner"
	density = FALSE
	climbable = FALSE

/obj/structure/railing/Initialize()
	. = ..()

/obj/structure/railing/attackby(obj/item/I, mob/living/user, params)
	..()
	add_fingerprint(user)

/obj/structure/railing/welder_act(mob/living/user, obj/item/I)
	if(user.intent == INTENT_HELP)
		if(obj_integrity < max_integrity)
			if(!I.tool_start_check(user, amount = 0))
				return
			to_chat(user, "<span class='notice'>You begin repairing [src]...</span>")
			if(I.use_tool(src, user, 40, volume = 50))
				obj_integrity = max_integrity
				to_chat(user, "<span class='notice'>You repair [src].</span>")
			return

		to_chat(user, "<span class='warning'>[src] is already in good condition!</span>")
		return

/obj/structure/railing/wirecutter_act(mob/living/user, obj/item/I)
	. = ..()
	if(!anchored)
		to_chat(user, "<span class='warning'>You cut apart the railing.</span>")
		I.play_tool_sound(src, 100)
		deconstruct()
		return TRUE

/obj/structure/railing/deconstruct(disassembled)
	if(!(flags & NODECONSTRUCT))
		var/obj/item/stack/rods/rod = new /obj/item/stack/rods(drop_location(), 3)
		transfer_fingerprints_to(rod)
	return ..()

///Implements behaviour that makes it possible to unanchor the railing.
/obj/structure/railing/wrench_act(mob/living/user, obj/item/I)
	. = ..()
	if(flags & NODECONSTRUCT)
		return
	to_chat(user, "<span class='notice'>You begin to [anchored ? "unfasten the railing from":"fasten the railing to"] the floor...</span>")
	if(I.use_tool(src, user, volume = 75, extra_checks = CALLBACK(src, .proc/check_anchored, anchored)))
		if(!anchored)
			anchored = TRUE
		else
			anchored = FALSE
		to_chat(user, "<span class='notice'>You [anchored ? "fasten the railing to":"unfasten the railing from"] the floor.</span>")
	return TRUE

/obj/structure/railing/CanPass(atom/movable/mover, turf/target)
	if(istype(mover) && mover.checkpass(PASSFENCE))
		return TRUE
	if(istype(mover, /obj/item/projectile))
		return TRUE
	if(ismob(mover))
		var/mob/M = mover
		if(M.flying)
			return TRUE
	if(mover.throwing)
		return TRUE
	if(get_dir(loc, target) != dir)
		return density
	return FALSE

/obj/structure/railing/corner/CanPass()
	return TRUE

/obj/structure/railing/corner/CheckExit()
	return TRUE

/obj/structure/railing/CheckExit(atom/movable/O, target)
	var/mob/living/M = O
	if(istype(O) && O.checkpass(PASSFENCE))
		return TRUE
	if(istype(O, /obj/item/projectile))
		return TRUE
	if(ismob(O))
		if(M.flying | M.floating)
			return TRUE
	if(O.throwing)
		return TRUE
	if(O.move_force >= MOVE_FORCE_EXTREMELY_STRONG)
		return TRUE
	if(currently_climbed)
		if(get_turf(M) == get_turf(src))
			var/turf/T = target
			if(T.density)
				return FALSE
			for(var/atom/A in T)
				if(A.density)
					return FALSE
			currently_climbed = FALSE
			return TRUE
	if(get_dir(O.loc, target) == dir)
		return FALSE
	return TRUE

/obj/structure/railing/do_climb(mob/living/user)
	. = ..()
	if(!climbable)
		return
	if(get_turf(user) == get_turf(src))
		currently_climbed = TRUE

/obj/structure/railing/proc/can_be_rotated(mob/user)
	if(anchored)
		to_chat(user, "<span class='warning'>[src] cannot be rotated while it is fastened to the floor!</span>")
		return FALSE

	var/target_dir = turn(dir, -90)

	if(!valid_window_location(loc, target_dir)) //Expanded to include rails, as well!
		to_chat(user, "<span class='warning'>[src] cannot be rotated in that direction!</span>")
		return FALSE
	return TRUE

/obj/structure/railing/proc/check_anchored(checked_anchored)
	if(anchored == checked_anchored)
		return TRUE

/obj/structure/railing/proc/after_rotation(mob/user)
	add_fingerprint(user)

/obj/structure/railing/AltClick(mob/user)
	if(user.incapacitated())
		to_chat(user, "<span class='warning'>You can't do that right now!</span>")
		return
	if(!Adjacent(user))
		return
	if(can_be_rotated(user))
		setDir(turn(dir, 90))
