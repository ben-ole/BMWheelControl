//
//  BMWheelControl.m
//  PINMAPP
//
//  Created by Benjamin Müller on 20.04.13.
//  Copyright (c) 2013 Benjamin Müller. All rights reserved.
//

#import "BMWheelControl.h"
#import <QuartzCore/QuartzCore.h>

@implementation BMWheelControl{
    NSMutableArray* _iconRepresentations;
    NSMutableArray* _iconDisabledRepresentations;
    NSMutableArray* _iconStates;
    UIPanGestureRecognizer* _panRecognizer;
    CGPoint _panStart;
    Boolean _iconsLoaded;
    UIView* _boundingView;
    float _currentAngle;
}

#pragma mark - INIT

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    if ((self = [super initWithCoder:aDecoder])) {
        [self setup];
    }
    
    return self;
}

-(id)init{
    // default size 100x100
    if ((self = [super initWithFrame:CGRectMake(0, 0, 100, 100)])) {
        [self setup];
    }
    return self;
}


-(void)setup{
    _boundingView = nil;
    
    // setup gesture recognizer
    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [self addGestureRecognizer:_panRecognizer];
    
    // set defaults
    _iconsLoaded = NO;
    
    self.backgroundColor = [UIColor clearColor];
    self.borderColor = [UIColor blackColor];
    self.circleColor = [UIColor greenColor];
    self.borderThickness = 5;
    
    self.shadowOffset = CGSizeMake(0, 0);
    self.shadowBlur = 10;
    self.shadowColor = [UIColor colorWithWhite:0. alpha:0.8];

    self.iconBlendMode = kCGBlendModeNormal;
    self.clipsToBounds = FALSE;
    self.iconInset = 30;
    
    self.singleStepAnimationDuration = 0.5;
    self.rotationEnabled = TRUE;
    _selectedIndex = 0;
    self.panDistancePerItem = 100.;
    
    self.rotationEnabled = TRUE;
    self.stepByStepRotation = TRUE;
    self.cyclingEnabled = TRUE;
}

#pragma mark - PROPERTIES
-(void)setBounds:(CGRect)bounds{
    [super setBounds:bounds];
    
    [self setNeedsDisplay];
}

-(void)setBorderThickness:(float)borderThickness{
    _borderThickness = borderThickness;
    
    [self setNeedsDisplay];
}

-(void)setCircleColor:(UIColor *)circleColor{
    _circleColor = circleColor;
    
    [self setNeedsDisplay];
}

-(void)setBorderColor:(UIColor *)borderColor{
    _borderColor = borderColor;
    
    [self setNeedsDisplay];
}

-(void)setShadowBlur:(float)shadowBlur{
    _shadowBlur = shadowBlur;
    
    [self setNeedsDisplay];
}

-(void)setShadowColor:(UIColor *)shadowColor{
    _shadowColor = shadowColor;
    
    [self setNeedsDisplay];
}

-(void)setShadowOffset:(CGSize)shadowOffset{
    _shadowOffset = shadowOffset;
    
    [self setNeedsDisplay];
}

-(void)setIcons:(NSArray *)icons{
    _icons = icons;
    _iconRepresentations = nil;
    _iconDisabledRepresentations = nil;
    _iconsLoaded = NO;
    _iconStates = nil;
    
    // load icons in background
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        _iconStates = [[NSMutableArray alloc] init];
        _iconRepresentations = [NSMutableArray arrayWithArray:_icons];
        _iconDisabledRepresentations = [NSMutableArray arrayWithArray:_icons];
        
        int i=-1;
        for (id ico in _icons) {
            
            i++;
            
            // enable all icons by default
            [_iconStates addObject:@(BMWHEEL_ICON_STATE_NORMAL)];
            
            if([ico isKindOfClass:[NSNull class]]) continue;   // don't draw any icon for this case
            
            if (_delegate && [_delegate respondsToSelector:@selector(wheel:showIconWithIndex:)]) {
                _iconStates[i] = @([_delegate wheel:self showIconWithIndex:i]);
            }
            
            id ico_normal = ico;
            
            if ([ico isKindOfClass:[NSArray class]]) {
                if ([(NSArray*)ico count] != 2 ||
                    ![(NSArray*)ico[0] isKindOfClass:[NSString class]] ||
                    ![(NSArray*)ico[1] isKindOfClass:[NSString class]]) {
                    
                    [NSException raise:@"Invalid icon data."
                                format:@"The provided icon should be either a path of type NSString or an Array with 2 items each one a path of type NSString, but was of type '%@'",[ico class]];
                }
                
                NSString* disabledIcon = (id)ico[1];
                // load disabled icon
                UIImage* iconRep;
                if ([disabledIcon isAbsolutePath] &&
                    [[NSFileManager defaultManager] fileExistsAtPath:disabledIcon]) {
                    iconRep = [[UIImage alloc] initWithContentsOfFile:disabledIcon];
                }else{
                    iconRep = [UIImage imageNamed:disabledIcon];
                }
                
                if(!iconRep)
                    [NSException raise:@"Invalid icon name or path."
                                format:@"Could not load an icon file at '%@'",disabledIcon];
                
                [_iconDisabledRepresentations replaceObjectAtIndex:i withObject:iconRep];
                
                ico_normal = ico[0]; // go on
            }else{
                [_iconDisabledRepresentations replaceObjectAtIndex:i withObject:[NSNull null]];
            }
            
            if(![ico_normal isKindOfClass:[NSString class]])
                [NSException raise:@"Invalid icon data."
                            format:@"The provided icon path should be of type NSString but was of type '%@'",[ico_normal class]];
            
            // load icon
            UIImage* iconRep;
            if ([(NSString*)ico_normal isAbsolutePath] &&
                [[NSFileManager defaultManager] fileExistsAtPath:ico_normal]) {
                iconRep = [[UIImage alloc] initWithContentsOfFile:ico_normal];
            }else{
                iconRep = [UIImage imageNamed:ico_normal];
            }
            
            if(!iconRep)
                [NSException raise:@"Invalid icon name or path."
                            format:@"Could not load an icon file at '%@'",ico_normal];
            
            [_iconRepresentations replaceObjectAtIndex:i withObject:iconRep];
        }
        
        _iconsLoaded = YES;
    
        dispatch_async(dispatch_get_main_queue(), ^{

            [self setNeedsDisplay];
        });
    });
}



-(void)setIconInset:(float)iconInset{
    _iconInset = iconInset;
    
    [self setNeedsDisplay];
}

-(void)setIconBlendMode:(CGBlendMode)iconBlendMode{
    _iconBlendMode = iconBlendMode;
    
    [self setNeedsDisplay];
}

-(void)setSelectedIndex:(int)selectedIndex{
    
    [self setSelectedIndex:selectedIndex animated:TRUE];
}

-(void)setSelectedIndex:(int)selectedIndex animated:(Boolean)animate{
    
    // if we have no items(icons) - no selection is possible
    if (!_icons || _icons.count == 0) {
        _selectedIndex = -1;
        return;
    }
    
    // keep index in bounds (cycled)
    if (selectedIndex < 0) {
        if(!_cyclingEnabled) return;
        
        selectedIndex = (int)_icons.count - 1;
    }
    
    if (selectedIndex >= _icons.count) {
        if(!_cyclingEnabled) return;
        
        selectedIndex = 0;
    }
    
    // disable user interaction during animation
    _panRecognizer.enabled = FALSE;
    
    float indexDistance = (float) abs(_selectedIndex - selectedIndex);
    
    // update view
    float angle = - 2.0 * M_PI / (float)_icons.count * selectedIndex;
 
    // update index
    _selectedIndex = selectedIndex;
    
    // inform delegate
    if (_delegate && [_delegate respondsToSelector:@selector(wheel:didEndUpdating:)]) {
        
        [_delegate wheel:self didEndUpdating:selectedIndex];
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(wheel:showIconWithIndex:)]) {
        for (int i=0; i<self.icons.count; i++) {
            if ([_icons[i] isKindOfClass:[NSNull class]]) continue;
            
            _iconStates[i] = @([_delegate wheel:self showIconWithIndex:i]);
        }
    }
    
    // update disabled states
    for (int i=0;i < _iconStates.count; i++) {
        BMWHEEL_ICON_STATE ico_state = [_iconStates[i] integerValue];
        
        if (_selectedIndex == i)
            _iconStates[i] = @(BMWHEEL_ICON_STATE_NORMAL);
        else if(ico_state != BMWHEEL_ICON_STATE_HIDDEN)
            _iconStates[i] = @(BMWHEEL_ICON_STATE_DISABLED);
    }
    [self setNeedsDisplay];    
    
//    if(!animate){
        self.layer.transform = CATransform3DMakeRotation(angle, 0, 0, 1.0);
        _panRecognizer.enabled = TRUE;
//    }else{
//    
//        // animate view
//        
//        [UIView animateWithDuration:_singleStepAnimationDuration*MAX(1.0,indexDistance)
//                              delay:0.
//                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent
//                         animations:^{
//                             self.layer.transform = CATransform3DMakeRotation(angle-_currentAngle, 0, 0, 1.0);
//                         } completion:^(BOOL finished) {
//                             
//                             _panRecognizer.enabled = TRUE;
//                             
//                         }];
//    }
}

#pragma mark - TOUCH HANDLER
-(void)didPan:(UIPanGestureRecognizer*)recognizer{
    
    // let's rely on x axis movement only for the moment
    
    // cancel, if rotation is disabled or no items available
    if(!_rotationEnabled || !_icons || !_icons.count > 0) return;
    
    // get the touch location normalized to the window (self has transformation applied)
    CGPoint nTouchLocation = [recognizer locationInView:nil];
    
    // respect device orientation
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        
        if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight) {
            nTouchLocation = CGPointMake(nTouchLocation.y, nTouchLocation.x);
        }else{
            nTouchLocation = CGPointMake(self.window.frame.size.width - nTouchLocation.y, nTouchLocation.x);
        }
    }
    
    float distance = nTouchLocation.x - _panStart.x;
//    float distanceY = nTouchLocation.y - _panStart.y;
    float anglePerItem = 2.0 * M_PI / (float)_icons.count;
    float normalizedDistance = distance / _panDistancePerItem;
    
    if (_panRecognizer.state == UIGestureRecognizerStateBegan) {
        _panStart = nTouchLocation;
        
        // inform delegate
        if (_delegate && [_delegate respondsToSelector:@selector(wheel:didStartRotationWithCurrentIndex:)]) {
            [_delegate wheel:self didStartRotationWithCurrentIndex:self.selectedIndex];
        }
     
        return;
    }
    
    // check if wheel is allowed to rotate to next item
    if (_delegate && [_delegate respondsToSelector:@selector(wheel:willRotateToIndex:)] &&
        ![_delegate wheel:self willRotateToIndex:(float)_selectedIndex-normalizedDistance]) {
        return;
    }
    
    if(_panRecognizer.state == UIGestureRecognizerStateChanged) {
        
        // ensure to stay in bounds when cycling is disabled
        if(!_cyclingEnabled &&
           (-normalizedDistance+_selectedIndex > ((float)_icons.count-1) ||
            -normalizedDistance+_selectedIndex < 0.))
            return;
        
        // rotate maximum one item
        if (_stepByStepRotation &&
            (normalizedDistance > 1.0 || normalizedDistance < -1.0)) return;

        
        float angle = (- (float)_selectedIndex + normalizedDistance) * anglePerItem;

        self.layer.transform = CATransform3DMakeRotation(angle, 0, 0, 1.0);
        _currentAngle = angle;

        // inform delegate
        if (_delegate && [_delegate respondsToSelector:@selector(wheel:didUpdateToIndex:)]) {
            [_delegate wheel:self didUpdateToIndex:normalizedDistance];
        }
        
    }else if(_panRecognizer.state == UIGestureRecognizerStateCancelled ||
             _panRecognizer.state == UIGestureRecognizerStateEnded ||
             _panRecognizer.state == UIGestureRecognizerStateFailed) {
        
        // snap to final position
        if (normalizedDistance > 0.5) {
            self.selectedIndex--;
        }else if(normalizedDistance < -0.5) {
            self.selectedIndex++;
        }else{
            self.selectedIndex = _selectedIndex;
        }
    }
}

#pragma mark - DRAWING

- (void)drawRect:(CGRect)rect
{
    if (WAIT_FOR_ICONS && !_iconsLoaded)
        return;
    
    float size = [self outerCircleSize];
    float xOffset = (self.bounds.size.width - size) * 0.5;
    float yOffset = (self.bounds.size.height - size) * 0.5;
        
    CGRect outerRect = CGRectMake(xOffset, yOffset, size, size);
    
    // drawing
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextSetShouldAntialias(ctx, true);
    CGContextSetAllowsAntialiasing(ctx, true);
    
    CGContextSetShadowWithColor(ctx, _shadowOffset, _shadowBlur,_shadowColor.CGColor);
    
    // create outer circle
    CGContextAddEllipseInRect(ctx, outerRect);
    CGContextSetFillColorWithColor(ctx, [_borderColor CGColor]);
    CGContextFillPath(ctx);
    
    // disable further shadowing
    CGContextSetShadowWithColor(ctx, CGSizeZero, 0, NULL);
    
    // create inner circle
    CGContextAddEllipseInRect(ctx, CGRectInset(outerRect, _borderThickness, _borderThickness));
    CGContextSetFillColorWithColor(ctx, [_circleColor CGColor]);
    CGContextFillPath(ctx);
    
    // drawing icons
    if(!_icons || !_iconRepresentations || !_iconsLoaded) return;
    
    float numIcons = (float)_icons.count;
    CGPoint center = CGPointMake(CGRectGetMidX(outerRect), CGRectGetMidY(outerRect));
    float radius = outerRect.size.width*0.5 - _iconInset;
    float angleSize = 2.0*M_PI / numIcons;
    
    
    [_iconRepresentations enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
      
        if([object isKindOfClass:[NSNull class]]) return;   // don't draw any icon for this case
        
        if ([_iconStates[index] integerValue] == BMWHEEL_ICON_STATE_HIDDEN) return;  // don't draw hidden icons
        
        UIImage* icon = object;
        
        if ([_iconStates[index] integerValue] == BMWHEEL_ICON_STATE_DISABLED &&
            ![_iconDisabledRepresentations[index] isKindOfClass:[NSNull class]])
            icon = _iconDisabledRepresentations[index];
                                 
        CGPoint iconPosition = CGPointMake(radius * cos(((float)index)/numIcons * M_2_PI - M_PI_2) + center.x,
                                           radius * sin(((float)index)/numIcons * M_2_PI - M_PI_2) + center.y);
        
        iconPosition = CGPointMake(0, - radius);
                
        // center icon on iconPosition
        iconPosition = CGPointMake(iconPosition.x - icon.size.width*0.5,
                                   iconPosition.y - icon.size.height*0.5);

        // rotate context
        CGContextSaveGState(ctx);
        CGContextTranslateCTM(ctx, center.x, center.y);
        CGContextRotateCTM(ctx, angleSize * index);
        
        [icon drawAtPoint:iconPosition blendMode:_iconBlendMode alpha:1.0];
        CGContextRestoreGState(ctx);
    }];
    
    CGContextRestoreGState(ctx);
}

#pragma mark - HELPER
-(float)outerCircleSize{
    
    return MIN(self.bounds.size.width - _shadowBlur*2.,
               self.bounds.size.height - _shadowBlur*2.);
}

@end
