@interface PKMainWindowController : NSWindowController
@property (weak) IBOutlet NSTabView* tabView;
@end

@implementation PKMainWindowController

+ (PKMainWindowController*) sharedMainWindowController {
    static PKMainWindowController* sharedMainWindowController;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMainWindowController = [[PKMainWindowController alloc] init];
    });
    return sharedMainWindowController;
}

- (NSString*) windowNibName { return @"MainWindow"; }

- (void) showWindow:(id)sender {
    if (![[self window] isVisible])
        [[self window] center];
    
    [super showWindow:sender];
}

- (void)windowDidLoad {
    [[[self window] toolbar] setSelectedItemIdentifier:@"settings"];
}

- (NSArray*) toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
    return [[toolbar items] valueForKeyPath:@"itemIdentifier"];
}

- (IBAction) switchToTab:(NSToolbarItem*)sender {
    [self showTab:[sender itemIdentifier]];
}

- (void) showTab:(NSString*)tab {
    [self.tabView selectTabViewItemWithIdentifier:tab];
    NSTabViewItem* item = [self.tabView selectedTabViewItem];
    [[[item initialFirstResponder] window] makeFirstResponder:[item initialFirstResponder]];
}

- (void) showAtTab:(NSString*)tab {
    [self showWindow:self];
    [[[self window] toolbar] setSelectedItemIdentifier:tab];
    [self showTab:tab];
}

@end