//
//  ChessAppDelegate.h
//  Chess
//
//  Created by Paul Baumstarck on 12/9/11.
//

#import <UIKit/UIKit.h>

@class ChessViewController;

@interface ChessAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    ChessViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ChessViewController *viewController;

@end

