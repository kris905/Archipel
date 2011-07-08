/*
 * TNVirtualMachineCloneController.j
 *
 * Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

@import <Foundation/Foundation.j>
@import <AppKit/CPView.j>
@import <AppKit/CPButton.j>
@import <AppKit/CPTextField.j>

@import <TNKit/TNAttachedWindow.j>

var TNArchipelTypeHypervisorControl             = @"archipel:hypervisor:control",
    TNArchipelTypeHypervisorControlClone        = @"clone";


/*! @ingroup hypervisorvmcreation
    This object allow to clone an existing virtual machine
*/
@implementation TNVirtualMachineCloneController : CPObject
{
    @outlet CPButton        buttonClone;
    @outlet CPTextField     fieldCloneVirtualMachineName;
    @outlet CPView          mainContentView;

    id                      _delegate   @accessors(property=delegate);

    TNAttachedWindow        _mainWindow;
}


#pragma mark -
#pragma mark Initialization

- (void)awakeFromCib
{
    _mainWindow = [[TNAttachedWindow alloc] initWithContentRect:CPRectMake(0.0, 0.0, [mainContentView frameSize].width, [mainContentView frameSize].height) styleMask:CPClosableWindowMask | TNAttachedWhiteWindowMask];
    [_mainWindow setContentView:mainContentView];
    [_mainWindow setDefaultButton:buttonClone];
}


#pragma mark -
#pragma mark Action

/*! open the window
    @param aSender the sender
*/
- (IBAction)openWindow:(id)aSender
{
    [fieldCloneVirtualMachineName setStringValue:@""];
    [_mainWindow makeFirstResponder:fieldCloneVirtualMachineName];
    [_mainWindow positionRelativeToView:aSender];
}

/*! close the window
    @param aSender the sender
*/
- (IBAction)closeWindow:(id)aSender
{
    [_mainWindow close];
}

/*! clone a virtual machine
    @param sender the sender of the action
*/
- (IBAction)cloneVirtualMachine:(id)aSender
{
    [_mainWindow close];
    [self cloneVirtualMachine];
}


#pragma mark -
#pragma mark XMPP Controls

/*! clone a virtual machine.
*/
- (void)cloneVirtualMachine
{
    var tableVirtualMachines    = [_delegate tableVirtualMachines],
        vm                      = [[tableVirtualMachines dataSource] objectAtIndex:[tableVirtualMachines selectedRow]],
        stanza                  = [TNStropheStanza iqWithType:@"set"];

    [tableVirtualMachines deselectAll];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorControl}];

    if ([fieldCloneVirtualMachineName stringValue] && [fieldCloneVirtualMachineName stringValue] != @"")
    {
        [stanza addChildWithName:@"archipel" andAttributes:{
            "action": TNArchipelTypeHypervisorControlClone,
            "jid": [[vm JID] bare],
            "name": [fieldCloneVirtualMachineName stringValue]}];
    }
    else
    {
        [stanza addChildWithName:@"archipel" andAttributes:{
            "action": TNArchipelTypeHypervisorControlClone,
            "jid": [[vm JID] bare]}];
    }

    [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didCloneVirtualMachine:) ofObject:self];
}

/*! compute the answer of the hypervisor about its cloning a VM
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didCloneVirtualMachine:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        CPLog.info(@"sucessfully cloning a virtual machine");

        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Virtual Machine", @"Virtual Machine")
                                                         message:CPBundleLocalizedString(@"Virtual machine has been cloned", @"Virtual machine has been cloned")];
    }
    else
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNVirtualMachineCloneController], comment);
}