/*
 * See Licensing and Copyright notice in naev.h
 */



#ifndef SHIP_H
#  define SHIP_H


#include "opengl.h"
#include "outfit.h"
#include "sound.h"


/* target gfx dimensions */
#define SHIP_TARGET_W   128 /**< Ship target graphic width. */
#define SHIP_TARGET_H   96 /**< Ship target graphic height. */


/**
 * @typedef ShipClass
 *
 * @brief Contains the different types of ships.
 *
 * @todo Not too happy with the current ship class system.  Too smiplistic.
 *
 * @sa ship_classFromString
 * @sa ship_class
 */
typedef enum ShipClass_ {
   SHIP_CLASS_NULL, /* Invalid ship class. */
   /* CIVILIAN */
   SHIP_CLASS_CIV_LIGHT, /**< Light civilian ship. */
   SHIP_CLASS_CIV_MEDIUM, /**< Medium civilian ship. */
   SHIP_CLASS_CIV_HEAVY, /**< Heavy civilian ship. */
   /* MILITARY */
   SHIP_CLASS_MIL_LIGHT, /**< Light military ship. */
   SHIP_CLASS_MIL_MEDIUM, /**< Medium military ship. */
   SHIP_CLASS_MIL_HEAVY, /**< Heavy military ship. */
   /* ROBOTIC */
   SHIP_CLASS_ROB_LIGHT,
   SHIP_CLASS_ROB_MEDIUM,
   SHIP_CLASS_ROB_HEAVY,
   /* HYBRID */
   SHIP_CLASS_HYB_LIGHT,
   SHIP_CLASS_HYB_MEDIUM,
   SHIP_CLASS_HYB_HEAVY
} ShipClass;


/**
 * @struct ShipOutfit
 *
 * @brief Little wrapper for outfits.
 */
typedef struct ShipOutfit_ {
   struct ShipOutfit_* next; /**< Linked list next. */
   Outfit* data; /**< Data itself. */
   int quantity; /**< Important difference. */
} ShipOutfit;


/**
 * @struct Ship
 *
 * @brief Represents a space ship.
 */
typedef struct Ship_ {

   char* name; /**< ship name */
   ShipClass class; /**< ship class */

   /* store stuff */
   int price; /**< cost to buy */
   int tech; /**< see space.h */
   char* fabricator; /**< company that makes it */
   char* description; /**< selling description */

   /* movement */
   double thrust; /**< Ship's thrust in "pixel/sec^2" */
   double turn; /**< Ship's turn in rad/s */
   double speed; /**< Ship's max speed in "pixel/sec" */

   /* graphics */
   glTexture *gfx_space; /**< Space sprite sheet. */
   glTexture *gfx_target; /**< Targetting window graphic. */

   /* GUI interface */
   char* gui; /**< Name of the GUI the ship uses by default. */

   /* sound */
   int sound; /**< Sound motor uses.  Unused atm. */

   /* characteristics */
   int crew; /**< Crew members. */
   int mass; /**< Mass in tons. */
   int fuel; /**< How many jumps by default. */

   /* health */
   double armour; /**< Maximum base armour in MJ. */
   double armour_regen; /**< Maximum armour regeneration in MJ/s. */
   double shield; /**< Maximum base shield in MJ. */
   double shield_regen; /**< Maximum shield regeneration in MJ/s. */
   double energy; /**< Maximum base energy in MJ. */
   double energy_regen; /**< Maximum energy regeneration in MJ/s. */

   /* capacity */
   int cap_cargo; /**< Cargo capacity if empty. */
   int cap_weapon;  /**< Weapon capacity with no outfits. */

   /* outfits */
   ShipOutfit* outfit; /**< Linked list of outfits. */

} Ship;


/*
 * load/quit
 */
int ships_load (void);
void ships_free (void);


/*
 * get
 */
Ship* ship_get( const char* name );
char** ship_getTech( int *n, const int* tech, const int techmax );
char* ship_class( Ship* s );
int ship_basePrice( Ship* s );


/*
 * toolkit
 */
void ship_view( char* shipname );


#endif /* SHIP_H */
