//
//  BMWheelControl.h
//  PINMAPP
//
//  Created by Benjamin Müller on 20.04.13.
//  Copyright (c) 2013 Benjamin Müller. All rights reserved.
//

#import <UIKit/UIKit.h>

#define WAIT_FOR_ICONS 1

typedef enum {
    BMWHEEL_ICON_STATE_NORMAL = 1,
    BMWHEEL_ICON_STATE_DISABLED = 2,
    BMWHEEL_ICON_STATE_HIDDEN = 3
} BMWHEEL_ICON_STATE;


@protocol BMWheelDelegate;


@interface BMWheelControl : UIView

/** @name General Appearance */

/**
 * Wheel border size.
 */
@property (assign,nonatomic) float borderThickness;

/**
 * Wheel border color.
 */
@property (retain,nonatomic) UIColor* borderColor;

/**
 * Fill color of the wheel.
 */
@property (retain,nonatomic) UIColor* circleColor;


/** @name Shadow Attributes */

/**
 * Shadow of the outer circle.
 */
@property (assign,nonatomic) CGSize shadowOffset;

/**
 * Shadow of the outer circle. Pass *NULL* to disable shadowing.
 */
@property (retain,nonatomic) UIColor* shadowColor;

/**
 * Shadow of the outer circle.
 */
@property (assign,nonatomic) float  shadowBlur;


/** @name Icons Appearance and Position */

/**
 * This blendMode will be applied to all icons displayed on the wheel
 */
@property (assign,nonatomic) CGBlendMode iconBlendMode;

/**
 * Use iconInset to define the distance between the outer circle bounds and the icon center position.
 */
@property (assign,nonatomic) float  iconInset;


/** @name Datasource */

/**
 * Use this property to set the icons appearing on the wheel. The number of objects in the array defines the angles implicitly.
 * All objects in the array should be either of type *NSString* or *NSNull*. While the former defines the *name or path* of an icon to display, the latter is for dummy scenarios (think about one half filled with icons while keeping the other clean).
 */
@property (retain,nonatomic) NSArray* icons;

/** @name Interaction */

/**
 * You can provide a delegate to track user interaction with the wheel.
 */
@property (weak, nonatomic) IBOutlet id<BMWheelDelegate> delegate;

/**
 * By setting rotationEnbabled to TRUE, this wheel can be rotated by dragging.
 */
@property (assign,nonatomic) Boolean rotationEnabled;

/**
 * Use this property to specify the logical pixel distance on the x-axis a user has to pan to rotate to the next item.
 */
@property (assign,nonatomic) float panDistancePerItem;

/**
 * Index of the item (icon) being currently selected. Returns NSNotFound in case no icons are available.
 */
@property (assign,nonatomic) int selectedIndex;

/**
 * This property should be set to FALSE (default is TRUE) in case you don't want the wheel to be able to jump from the last value to the first or vice versa.
 */
@property (assign,nonatomic) Boolean cyclingEnabled;

/**
 * Set this property to TRUE (default ist TRUE) if you want the wheel to be rotated maximum one item per gesture.
 */
@property (assign,nonatomic) Boolean stepByStepRotation;

/** @name Animation Properties */

/**
 * Use this property to define the duration of the rotating animation being performed whenever selectedIndex changes. The value defines the time for a rotation implied by a selectedIndex change of 1.
 */
@property (assign,nonatomic) float singleStepAnimationDuration;


/**
 * rotate wheel to selected index
 @param animate whether rotation should be animated or not
 */
-(void)setSelectedIndex:(int)selectedIndex animated:(Boolean)animate;

@end

///////////////////////////////////////////////////////////
//////////////////// DELEGATE PROTOCOL ////////////////////
///////////////////////////////////////////////////////////

@protocol BMWheelDelegate <NSObject>

@optional

/**
 * This method is called whenever the user starts dragging the wheel.
 */
-(void)wheel:(BMWheelControl*)sender didStartRotationWithCurrentIndex:(int)oldIdx;

/**
 * This delegate method will be called with every touch update and informs about the rotation state. 
 * @param normalizedIndex is a float value reflecting the current index plus (or minus) the normalized distance to the next/previous index. E.g. 1.5 means the wheel rotation is half and half between index 1 and 2.
 */
-(void)wheel:(BMWheelControl*)sender didUpdateToIndex:(float)normalizedIndex;

/**
 * This method is called whenever the user resigns dragging and informs about the selected (int) index the wheel is going to animate to.
 * This method gets also called when the selected index changed programmatically.
 */
-(void)wheel:(BMWheelControl*)sender didEndUpdating:(int)newIndex;


-(BOOL)wheel:(BMWheelControl *)sender willRotateToIndex:(float)newIndex;

/**
 here you have a chance to hide icons. this method is invoced on every diedEndUpdating:. The wheel will automatically resign rotation to a hidden item.
 */
-(BMWHEEL_ICON_STATE)wheel:(BMWheelControl *)sender showIconWithIndex:(int)index;

@end
