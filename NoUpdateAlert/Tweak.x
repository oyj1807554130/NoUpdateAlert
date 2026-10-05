#import <UIKit/UIKit.h>

%hook UIViewController
- (void)presentViewController:(UIViewController *)vc animated:(BOOL)a completion:(void (^)(void))c {
    if ([vc isKindOfClass:[UIAlertController class]]) {
        UIAlertController *ac = (UIAlertController *)vc;
        NSString *t = ac.title ?: @"";
        NSString *m = ac.message ?: @"";
        if ([t containsString:@"更新"] || [t containsString:@"温馨提示"] ||
            [m containsString:@"更新"] || [m containsString:@"新版本"] ||
            [m containsString:@"更新包含"] || [m containsString:@"再更"] ||
            [m containsString:@"升级"] || [m containsString:@"提醒"]) {
            if (c) c();
            return;
        }
    }
    %orig;
}
%end

%ctor {
    @autoreleasepool {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setBool:NO forKey:@"sjj_spark_renew_enabled"];
        [ud setBool:NO forKey:@"sjj_remote_beta_update_reminder_enabled"];
        [ud removeObjectForKey:@"sjj_downloaded_update_package_metadata_v1"];
        [ud removeObjectForKey:@"sjj_update_packages"];
        [ud synchronize];
    }
}
