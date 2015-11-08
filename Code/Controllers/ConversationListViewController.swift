import UIKit
import Atlas
import Parse

class ConversationListViewController: ATLConversationListViewController, ATLConversationListViewControllerDelegate, ATLConversationListViewControllerDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataSource = self
        self.delegate = self
        
        self.navigationController!.navigationBar.tintColor = ATLBlueColor()
        
        let title = NSLocalizedString("Logout", comment: "")
        let logoutItem = UIBarButtonItem(title: title, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("logoutButtonTapped:"))
        self.navigationItem.setLeftBarButtonItem(logoutItem, animated: false)

        let composeItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Compose, target: self, action: Selector("composeButtonTapped:"))
        self.navigationItem.setRightBarButtonItem(composeItem, animated: false)
    }

    // MARK - ATLConversationListViewControllerDelegate Methods

    func conversationListViewController(conversationListViewController: ATLConversationListViewController, didSelectConversation conversation:LYRConversation) {
        self.presentControllerWithConversation(conversation)
    }

    func conversationListViewController(conversationListViewController: ATLConversationListViewController, didDeleteConversation conversation: LYRConversation, deletionMode: LYRDeletionMode) {
        print("Conversation deleted")
    }

    func conversationListViewController(conversationListViewController: ATLConversationListViewController, didFailDeletingConversation conversation: LYRConversation, deletionMode: LYRDeletionMode, error: NSError?) {
        print("Failed to delete conversation with error: \(error)")
    }

    func conversationListViewController(conversationListViewController: ATLConversationListViewController, didSearchForText searchText: String, completion: ((Set<NSObject>!) -> Void)?) {
        UserManager.sharedManager.queryForUserWithName(searchText) { (participants: NSArray?, error: NSError?) in
            if error == nil {
                if let callback = completion {
                    callback(NSSet(array: participants as! [AnyObject]) as Set<NSObject>)
                }
            } else {
                if let callback = completion {
                    callback(nil)
                }
                print("Error searching for Users by name: \(error)")
            }
        }
    }

    func conversationListViewController(conversationListViewController: ATLConversationListViewController!, avatarItemForConversation conversation: LYRConversation!) -> ATLAvatarItem! {
        if conversation.lastMessage == nil {
            return nil
        }
        let userID: String = conversation.lastMessage.sender.userID
        if userID == PFUser.currentUser()!.objectId {
            return PFUser.currentUser()
        }
        let user: PFUser? = UserManager.sharedManager.cachedUserForUserID(userID)
        if user == nil {
            UserManager.sharedManager.queryAndCacheUsersWithIDs([userID], completion: { (participants, error) in
                if participants != nil && error == nil {
                    self.reloadCellForConversation(conversation)
                } else {
                    print("Error querying for users: \(error)")
                }
            })
        }
        return user;
    }
    
    // MARK - ATLConversationListViewControllerDataSource Methods

    func conversationListViewController(conversationListViewController: ATLConversationListViewController, titleForConversation conversation: LYRConversation) -> String {
        if conversation.metadata["title"] != nil {
            return conversation.metadata["title"] as! String
        } else {
            let listOfParticipant = Array(conversation.participants)
            let unresolvedParticipants: NSArray = UserManager.sharedManager.unCachedUserIDsFromParticipants(listOfParticipant)
            let resolvedNames: NSArray = UserManager.sharedManager.resolvedNamesFromParticipants(listOfParticipant)
            
            if (unresolvedParticipants.count > 0) {
                UserManager.sharedManager.queryAndCacheUsersWithIDs(unresolvedParticipants as! [String]) { (participants: NSArray?, error: NSError?) in
                    if (error == nil) {
                        if (participants?.count > 0) {
                            self.reloadCellForConversation(conversation)
                        }
                    } else {
                        print("Error querying for Users: \(error)")
                    }
                }
            }
            
            if (resolvedNames.count > 0 && unresolvedParticipants.count > 0) {
                let resolved = resolvedNames.componentsJoinedByString(", ")
                return "\(resolved) and \(unresolvedParticipants.count) others"
            } else if (resolvedNames.count > 0 && unresolvedParticipants.count == 0) {
                return resolvedNames.componentsJoinedByString(", ")
            } else {
                return "Conversation with \(conversation.participants.count) users..."
            }
        }
    }

    
    // MARK:- Conversation Selection From Push Notification
    
    func presentConversation(conversation: LYRConversation) {
        self.presentControllerWithConversation(conversation)
    }
    
    // MARK:- Conversation Selection
    
    // The following method handles presenting the correct `ConversationViewController`, regardeless of the current state of the navigation stack.
    func presentControllerWithConversation(conversation: LYRConversation) {
        let shouldShowAddressBar: Bool  = conversation.participants.count > 2 || conversation.participants.count == 0
        let conversationViewController: ConversationViewController = ConversationViewController(layerClient: self.layerClient)
        conversationViewController.displaysAddressBar = shouldShowAddressBar
        conversationViewController.conversation = conversation
    
        if self.navigationController!.topViewController == self {
            self.navigationController!.pushViewController(conversationViewController, animated: true)
        } else {
            var viewControllers = self.navigationController!.viewControllers
            let listViewControllerIndex: Int = self.navigationController!.viewControllers.indexOf(self)!
            viewControllers[listViewControllerIndex + 1 ..< viewControllers.count] = [conversationViewController]
            self.navigationController!.setViewControllers(viewControllers, animated: true)
        }
    }
    
    
    // MARK - Actions

    func composeButtonTapped(sender: AnyObject) {
        let controller = ConversationViewController(layerClient: self.layerClient)
        controller.displaysAddressBar = true
        self.navigationController!.pushViewController(controller, animated: true)
    }

    func logoutButtonTapped(sender: AnyObject) {
        print("logOutButtonTapAction")
        
        self.layerClient.deauthenticateWithCompletion { (success: Bool, error: NSError?) in
            if error == nil {
                PFUser.logOut()
                self.navigationController!.popToRootViewControllerAnimated(true)
            } else {
                print("Failed to deauthenticate: \(error)")
            }
        }
    }
}
