#import <Foundation/Foundation.h>
#import "BITCrashManagerDelegate.h"

#import "BITHockeyUserData.h"

@class BITHockeyManager;
@class BITHockeyBaseManager;

/**
 The `BITHockeyManagerDelegate` formal protocol defines methods further configuring
 the behaviour of `BITHockeyManager`, as well as the delegate of the modules it manages.
 */

@protocol BITHockeyManagerDelegate <NSObject, BITCrashManagerDelegate>

@optional


///-----------------------------------------------------------------------------
/// @name Additional meta data
///-----------------------------------------------------------------------------


/** Return the userid that should used in the SDK components
 
 Right now this is used by the `BITCrashMananger` to attach to a crash report and `BITFeedbackManager`.
 
 You can find out the component requesting the user name like this:
    - (NSString *)userNameForHockeyManager:(BITHockeyManager *)hockeyManager componentManager:(BITCrashManager *)componentManager {
       if (componentManager == crashManager) {
         return UserNameForFeedback;
       } else {
         return nil;
       }
    }
 
 
 
 @param hockeyManager The `BITHockeyManager` HockeyManager instance invoking this delegate
 @param componentManager The `BITCrashManager` component instance invoking this delegate
 @see [BITHockeyManager setUserID:]
 @see userNameForHockeyManager:componentManager:
 @see userEmailForHockeyManager:componentManager:
 */
- (NSString *)userIDForHockeyManager:(BITHockeyManager *)hockeyManager componentManager:(BITHockeyBaseManager *)componentManager;


/** Return the user name that should used in the SDK components
 
 Right now this is used by the `BITCrashMananger` to attach to a crash report and `BITFeedbackManager`.
 
 You can find out the component requesting the user name like this:
    - (NSString *)userNameForHockeyManager:(BITHockeyManager *)hockeyManager componentManager:(BITCrashManager *)componentManager {
        if (componentManager == crashManager) {
         return UserNameForFeedback;
        } else {
         return nil;
        }
    }
 
 
 @param hockeyManager The `BITHockeyManager` HockeyManager instance invoking this delegate
 @param componentManager The `BITCrashManager` component instance invoking this delegate
 @see [BITHockeyManager setUserName:]
 @see userIDForHockeyManager:componentManager:
 @see userEmailForHockeyManager:componentManager:
 */
- (NSString *)userNameForHockeyManager:(BITHockeyManager *)hockeyManager componentManager:(BITHockeyBaseManager *)componentManager;


/** Return the users email address that should used in the SDK components
 
 Right now this is used by the `BITCrashMananger` to attach to a crash report and `BITFeedbackManager`.
 
 You can find out the component requesting the user name like this:
    - (NSString *)userNameForHockeyManager:(BITHockeyManager *)hockeyManager componentManager:(BITCrashManager *)componentManager {
        if (componentManager == hockeyManager.crashManager) {
         return UserNameForCrashReports;
        } else {
         return nil;
        }
    }
 
 
 @param hockeyManager The `BITHockeyManager` HockeyManager instance invoking this delegate
 @param componentManager The `BITCrashManager` component instance invoking this delegate
 @see [BITHockeyManager setUserEmail:]
 @see userIDForHockeyManager:componentManager:
 @see userNameForHockeyManager:componentManager:
 */
- (NSString *)userEmailForHockeyManager:(BITHockeyManager *)hockeyManager componentManager:(BITHockeyBaseManager *)componentManager;


/** Called after user manually submits meta data when prompted, for a crash report or Feedback form.
 Delegate should evaluate userProvidedData to determine if userID, userName and userEmail should be persisted.
 If user choose "always send" this delegate will not be called again.

 @param userProvidedData The BITHockeyUserData filled in with any user provided data: possibly userID, userName, userEmail, userProvidedText.
 @param hockeyManager The `BITHockeyManager` HockeyManager instance invoking this delegate
 @param componentManager The `BITHockeyBaseManager` component instance invoking this delegate, can be `BITCrashManager` or `BITFeedbackManager`
 */
- (void)userProvidedData:(BITHockeyUserData *)userProvidedData hockeyManager:(BITHockeyManager *)hockeyManager componentManager:(BITHockeyBaseManager *)componentManager;

@end
