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
    UIPanGestureRecognizer* _panRecognizer;
    CGPoint _panStart;
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
    
    // setup gesture recognizer
    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [self addGestureRecognizer:_panRecognizer];
    
    // set defaults
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
    
    [self setNeedsDisplay];
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
    float angle = 2.0 * M_PI / (float)_icons.count * selectedIndex;
    
    // inform delegate
    if (_delegate && [_delegate respondsToSelector:@selector(wheel:didEndUpdating:)]) {
        
        int relativeMove = selectedIndex - _selectedIndex;
        NSLog(@"relative movement: %i",relativeMove);
        [_delegate wheel:self didEndUpdating:relativeMove];
    }
    
    if(!animate){
        self.layer.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
        _selectedIndex = selectedIndex;
        _panRecognizer.enabled = TRUE;
    }else{
    
        // animate view
        [UIView animateWithDuration:_singleStepAnimationDuration*MAX(1.0,indexDistance)
                              delay:0.
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.layer.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
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
           (normalizedDistance+_selectedIndex > ((float)_icons.count-1) ||
            normalizedDistance+_selectedIndex < 0.))
            return;
        
        // rotate maximum one item
        if (_stepByStepRotation &&
            (normalizedDistance > 1.0 || normalizedDistance < -1.0)) return;

        
        float angle = ((float)_selectedIndex + normalizedDistance) * anglePerItem;
        
        self.layer.transform = CATransform3DMakeRotation(angle, 0, 0, 1);

        // inform delegate
        if (_delegate && [_delegate respondsToSelector:@selector(wheel:didUpdateToIndex:)]) {
            [_delegate wheel:self didUpdateToIndex:normalizedDistance];
        }
        
    }else if(_panRecognizer.state == UIGestureRecognizerStateCancelled ||
             _panRecognizer.state == UIGestureRecognizerStateEnded ||
             _panRecognizer.state == UIGestureRecognizerStateFailed) {
        
        // snap to final position
        if (normalizedDistance > 0.5) {
            self.selectedIndex++;
        }else if(normalizedDistance < -0.5) {
            self.selectedIndex--;
        }else{
            self.selectedIndex = _selectedIndex;
        }
    }
}

#pragma mark - DRAWING

- (void)drawRect:(CGRect)rect
{
    
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
    if(!_icons) return;
    
    float numIcons = (float)_icons.count;
    CGPoint center = CGPointMake(CGRectGetMidX(outerRect), CGRectGetMidY(outerRect));
    float radius = outerRect.size.width*0.5 - _iconInset;
    float angleSize = 2.0*M_PI / numIcons;
    
    
    [_icons enumerateObjectsWithOptions:NSEnumerationConcurrent
                             usingBlock:^(id object, NSUInteger index, BOOL *stop) {

        if([object isKindOfClass:[NSNull class]]) return;   // don't draw any icon for this case
        
        if(![object isKindOfClass:[NSString class]])
            [NSException raise:@"Invalid icon data."
                        format:@"The provided icon path should be of type NSString but was of type '%@'",[object class]];
        
        // load icon
        UIImage* icon;
        if ([(NSString*)object isAbsolutePath] && [[NSFileManager defaultManager] fileExistsAtPath:object]) {
            icon = [[UIImage alloc] initWithContentsOfFile:object];
        }else{
            icon = [UIImage imageNamed:object];
        }
        
        if(!icon)
            [NSException raise:@"Invalid icon name or path."
                        format:@"Could not load an icon file at '%@'",object];
        
        CGPoint iconPosition = CGPointMake(radius * cos(((float)index)/numIcons * M_2_PI - M_PI_2) + center.x,
                                           radius * sin(((float)index)/numIcons * M_2_PI - M_PI_2) + center.y);
        
        iconPosition = CGPointMake(0,   - radius);
                
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
