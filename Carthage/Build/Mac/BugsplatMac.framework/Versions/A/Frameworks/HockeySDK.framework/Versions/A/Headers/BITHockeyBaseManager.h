#import <Foundation/Foundation.h>

/**
 The internal superclass for all component managers
 
 */

@interface BITHockeyBaseManager : NSObject

///-----------------------------------------------------------------------------
/// @name Modules
///-----------------------------------------------------------------------------


/**
 Defines the server URL to send data to or request data from
 
 By default this is set to the HockeyApp servers and there rarely should be a
 need to modify that.
 */
@property (nonatomic, copy) NSString *serverURL;

/**
 *  Flag to enable/disable storing user settings in keychain
 */
@property (nonatomic, assign) BOOL persistUserInfo;

@end
