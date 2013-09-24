StringsGenerator
================

## Example

In source code

    static inline NSString *BBResourseLocalizedStringAlertViewTitleError() {
        return BBLocalizedString(@"ALERTVIEW_TITLE_ERROR", @"Error");
    }
    
    static inline NSString *BBResourseLocalizedStringAlertViewTitleHint() {
        return BBLocalizedString(@"ALERTVIEW_TITLE_Hint", @"Hint");
    }

This will generate base strings like this

    "ALERTVIEW_TITLE_ERROR" = "Error";
    "ALERTVIEW_TITLE_Hint" = "Hint";
    
And the target strings file will be prepared for translation.

    "ALERTVIEW_TITLE_ERROR" = ""; // Error
    "ALERTVIEW_TITLE_Hint" = ""; // Hint
    
If the target strings file exist. It will be automatic merged.

    "LOGIN_BUTTON_FINISH" = "完成";
    "LOGIN_BUTTON_FORGET_PASSWORD" = "忘记密码?";

    /*New*/
    "ALERTVIEW_TITLE_ERROR" = ""; // Error
    "ALERTVIEW_TITLE_Hint" = ""; // Hint

    /*Deprecated*/
    "NEW_TRANSACTION_TITLE_PLACEHOLDER" = "标题 (可选)";

##Usage

**Warning! Backup all your strings file.**

Firsr you need add a macro in .pch file in your project.

    #define BBLocalizedString(key, val) [[NSBundle mainBundle] localizedStringForKey:(key) value:(val) table:@"BBLocalizedString"]
    
You can change BBLocalizedString as you like, but remember to change "functionName" config.

Because this is a very early alpha version. The config is hardcoding in source. Please open config.h to set target project path.

    NSString *functionName = @"BBLocalizedString";
    NSString *sourcePath = @"/Users/blankwonder/Workspaces/BuddyBook/BuddyBook"; //All your source code should be here
    NSString *baseStringsFilePath = @"/Users/blankwonder/Workspaces/BuddyBook/BuddyBook/en.lproj/BBLocalizedString.strings"; //Warning! This file will be completely overwritten. Backup it first.
    NSString *translatedStringsFilePath = @"/Users/blankwonder/Workspaces/BuddyBook/BuddyBook/zh-Hans.lproj/BBLocalizedString.strings"; // This strings file will be merged. Backup it too.
    
    
## Known issue

Parenthesis ")" in BBLocalizedString will break source code scanning. Such as

    BBLocalizedString(@"API_ERROR_JSON_PARSER_ERROR", @"Server error (illegal response data). Please try again later.")
    
This line will not be detected.