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
    UIPanGestureRecognizer* _panRecognizer;
    CGPoint _panStart;
    Boolean _iconsLoaded;
    UIView* _boundingView;
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
    _iconsLoaded = NO;
    
    // load icons in background
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        _iconRepresentations = [NSMutableArray arrayWithArray:_icons];
        
        int i=-1;
        for (id ico in _icons) {
            
            i++;
            
            if([ico isKindOfClass:[NSNull class]]) continue;   // don't draw any icon for this case
            
            if(![ico isKindOfClass:[NSString class]])
                [NSException raise:@"Invalid icon data."
                            format:@"The provided icon path should be of type NSString but was of type '%@'",[ico class]];
            
            // load icon
            UIImage* iconRep;
            if ([(NSString*)ico isAbsolutePath] && [[NSFileManager defaultManager] fileExistsAtPath:ico]) {
                iconRep = [[UIImage alloc] initWithContentsOfFile:ico];
            }else{
                iconRep = [UIImage imageNamed:ico];
            }
            
            if(!iconRep)
                [NSException raise:@"Invalid icon name or path."
                            format:@"Could not load an icon file at '%@'",ico];
            
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
        _selectedIndex = NSNotFound;
        return;
    }
    
    // keep index in bounds (cycled)
    if (selectedIndex < 0) {
        if(!_cyclingEnabled) return;
        
        selectedIndex = _icons.count - 1;
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
        
    // inform delegate
    if (_delegate && [_delegate respondsToSelector:@selector(wheel:didEndUpdating:)]) {
        
        [_delegate wheel:self didEndUpdating:selectedIndex];
    }
    
    if(!animate){
         self.transform = CGAffineTransformMakeRotation(angle);
        _selectedIndex = selectedIndex;
        _panRecognizer.enabled = TRUE;
    }else{
    
        // animate view
        [UIView animateWithDuration:_singleStepAnimationDuration*MAX(1.0,indexDistance)
                              delay:0.
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.transform = CGAffineTransformMakeRotation(angle);
                         } completion:^(BOOL finished) {
                             
                             _selectedIndex = selectedIndex;
                             _panRecognizer.enabled = TRUE;
                             
                         }];
    }
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

         self.transform = CGAffineTransformMakeRotation(angle);

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
    [self embedInContainer];

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
    if(!_icons || !_iconRepresentations) return;
    
    float numIcons = (float)_icons.count;
    CGPoint center = CGPointMake(CGRectGetMidX(outerRect), CGRectGetMidY(outerRect));
    float radius = outerRect.size.width*0.5 - _iconInset;
    float angleSize = 2.0*M_PI / numIcons;
    
    
    [_iconRepresentations enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
      
        if([object isKindOfClass:[NSNull class]]) return;   // don't draw any icon for this case
        
        UIImage* icon = object;
                                 
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

-(void)embedInContainer{
    
    if(_boundingView)
        return;
        
    _boundingView = [[UIView alloc] initWithFrame:self.frame];
    _boundingView.translatesAutoresizingMaskIntoConstraints = NO;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    _boundingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    _boundingView.backgroundColor = [UIColor clearColor];
    [_boundingView removeConstraints:_boundingView.constraints];
    
    // move all constraints of self to _boundingView by replacing self with _boundingView in all relevant constraints
    NSMutableArray* relativeConstraints = [[NSMutableArray alloc] init];
    
    NSMutableArray* sourceConstraints = [NSMutableArray arrayWithArray:self.superview.constraints] ;
    [sourceConstraints addObjectsFromArray:self.constraints];
    
    for (NSLayoutConstraint* constr in sourceConstraints) {
        NSLayoutConstraint* newConstr = nil;
        
        if (constr.firstItem == self) {
            
            newConstr = [NSLayoutConstraint constraintWithItem:_boundingView attribute:constr.firstAttribute
                                                                         relatedBy:constr.relation
                                                                            toItem:constr.secondItem attribute:constr.secondAttribute
                                                                        multiplier:constr.multiplier constant:constr.constant];
        }else if(constr.secondItem == self){
            newConstr = [NSLayoutConstraint constraintWithItem:constr.firstItem attribute:constr.firstAttribute
                                                                         relatedBy:constr.relation
                                                                            toItem:_boundingView attribute:constr.secondAttribute
                                                                        multiplier:constr.multiplier constant:constr.constant];
        }
        
        if (newConstr) [relativeConstraints addObject:newConstr];
    }
    
    UIView* parent = self.superview;
    [self removeFromSuperview];
    [_boundingView addSubview:self];
    [parent addSubview:_boundingView];
    
    [parent addConstraints:relativeConstraints];
    
    self.frame = _boundingView.bounds;
    [self removeConstraints:self.constraints];
    

    [_boundingView addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_boundingView attribute:NSLayoutAttributeCenterX multiplier:1. constant:0]];
    [_boundingView addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_boundingView attribute:NSLayoutAttributeCenterY multiplier:1. constant:0]];
    [_boundingView addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:0 toItem:nil attribute:0 multiplier:1 constant:self.bounds.size.width]];
    [_boundingView addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:0 toItem:nil attribute:0 multiplier:1 constant:self.bounds.size.height]];
    
    [_boundingView updateConstraintsIfNeeded];
}
@end
