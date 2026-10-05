#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static IMP orig_presentVC = NULL;

static BOOL hasUpdateText(NSString *text) {
    if (!text || text.length == 0) return NO;
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
    }
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *btn = (UIButton *)view;
        if (hasUpdateText([btn titleForState:UIControlStateNormal])) return YES;
        if (hasUpdateText([btn titleForState:UIControlStateHighlighted])) return YES;
    }
    for (UIView *sub in view.subviews) {
        if (viewHasUpdateText(sub)) return YES;
    }
    return NO;
}

static void replaced_presentVC(UIViewController *self, SEL _cmd,
    UIViewController *vc, BOOL animated, void (^completion)(void)) {

    // 1. UIAlertController with update keywords
    if ([vc isKindOfClass:[UIAlertController class]]) {
        UIAlertController *ac = (UIAlertController *)vc;
        if (hasUpdateText(ac.title) || hasUpdateText(ac.message)) {
            if (completion) completion();
            return;
        }
    }

    // 2. Class name contains Update/Renew/Spark
    NSString *cls = NSStringFromClass([vc class]);
    if ([cls containsString:@"Update"] || [cls containsString:@"Renew"] ||
        [cls containsString:@"Spark"]  || [cls containsString:@"Upgrade"]) {
        if (completion) completion();
        return;
    }

    // 3. View hierarchy contains update text
    @try {
        UIView *v = vc.view;
        if (v && viewHasUpdateText(v)) {
            if (completion) completion();
            return;
        }
    } @catch (NSException *e) {}

    // Call original
    ((void(*)(id,SEL,id,BOOL,void(^)(void)))orig_presentVC)(self, _cmd, vc, animated, completion);
}

__attribute__((constructor))
static void NoUpdateAlertInit() {
    @autoreleasepool {
        // Hook presentViewController:animated:completion:
        Class vcClass = objc_getClass("UIViewController");
        if (vcClass) {
            Method m = class_getInstanceMethod(vcClass,
                sel_registerName("presentViewController:animated:completion:"));
            if (m) {
                orig_presentVC = method_setImplementation(m, (IMP)replaced_presentVC);
            }
        }

        // Disable update checks via NSUserDefaults
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setBool:NO forKey:@"sjj_spark_renew_enabled"];
        [ud setBool:NO forKey:@"sjj_remote_beta_update_reminder_enabled"];
        [ud removeObjectForKey:@"sjj_downloaded_update_package_metadata_v1"];
        [ud removeObjectForKey:@"sjj_update_packages"];
        [ud synchronize];
    }
}
