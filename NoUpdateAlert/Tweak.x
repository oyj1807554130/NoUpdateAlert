#import <UIKit/UIKit.h>

static BOOL hasUpdateText(NSString *text) {
    if (!text) return NO;
    return [text containsString:@"更新"] ||
           [text containsString:@"新版本"] ||
           [text containsString:@"升级"] ||
           [text containsString:@"温馨提示"] ||
           [text containsString:@"更新提示"] ||
           [text containsString:@"发现更新"] ||
           [text containsString:@"去更新"] ||
           [text containsString:@"再更"] ||
           [text containsString:@"更新日志"] ||
           [text containsString:@"点击查看更新"];
}

static BOOL viewHasUpdateText(UIView *view) {
    if (!view) return NO;
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        if (hasUpdateText(label.text)) return YES;
        if (label.attributedText) {
            NSString *attrStr = [label.attributedText string];
            if (hasUpdateText(attrStr)) return YES;
        }
    }
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *btn = (UIButton *)view;
        if (hasUpdateText([btn titleForState:UIControlStateNormal])) return YES;
    }
    for (UIView *sub in view.subviews) {
        if (viewHasUpdateText(sub)) return YES;
    }
    return NO;
}

%hook UIViewController

- (void)presentViewController:(UIViewController *)vc animated:(BOOL)a completion:(void (^)(void))c {
    // 1. UIAlertController with update text
    if ([vc isKindOfClass:[UIAlertController class]]) {
        UIAlertController *ac = (UIAlertController *)vc;
        if (hasUpdateText(ac.title) || hasUpdateText(ac.message)) {
            if (c) c();
            return;
        }
    }

    // 2. Check class name for Update/Renew/Spark
    NSString *cls = NSStringFromClass([vc class]);
    if ([cls containsString:@"Update"] || [cls containsString:@"Renew"] ||
        [cls containsString:@"Spark"]  || [cls containsString:@"Upgrade"]) {
        if (c) c();
        return;
    }

    // 3. Check view hierarchy for update text labels
    @try {
        UIView *v = vc.view; // triggers viewDidLoad
        if (v && viewHasUpdateText(v)) {
            if (c) c();
            return;
        }
    } @catch (NSException *e) {}

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
