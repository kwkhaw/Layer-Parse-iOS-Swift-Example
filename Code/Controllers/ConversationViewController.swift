import UIKit
import Atlas
import Parse

class ConversationViewController: ATLConversationViewController, ATLConversationViewControllerDataSource, ATLConversationViewControllerDelegate, ATLParticipantTableViewControllerDelegate {
    var dateFormatter: NSDateFormatter = NSDateFormatter()
    var usersArray: NSArray!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        print("addressBarController: \(self.addressBarController)")
        self.addressBarController?.delegate = self
        
        // Uncomment the following line if you want to show avatars in 1:1 conversations
        // self.shouldDisplayAvatarItemForOneOtherParticipant = true
        
        // Setup the dateformatter used by the dataSource.
        self.dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        self.dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle

        self.configureUI()
    }

    // MARK - UI Configuration methods

    func configureUI() {
        ATLOutgoingMessageCollectionViewCell.appearance().messageTextColor = UIColor.whiteColor()
    }

    // MARK - ATLConversationViewControllerDelegate methods

    func conversationViewController(viewController: ATLConversationViewController, didSendMessage message: LYRMessage) {
        print("Message sent!")
    }

    func conversationViewController(viewController: ATLConversationViewController, didFailSendingMessage message: LYRMessage, error: NSError?) {
        print("Message failed to sent with error: \(error)")
    }

    func conversationViewController(viewController: ATLConversationViewController, didSelectMessage message: LYRMessage) {
        print("Message selected")
    }

    // MARK - ATLConversationViewControllerDataSource methods

    func conversationViewController(conversationViewController: ATLConversationViewController, participantForIdentifier participantIdentifier: String) -> ATLParticipant? {
        if (participantIdentifier == PFUser.currentUser()?.objectId) {
            return PFUser.currentUser()
        }
        let user: PFUser? = UserManager.sharedManager.cachedUserForUserID(participantIdentifier)
        if (user == nil) {
            UserManager.sharedManager.queryAndCacheUsersWithIDs([participantIdentifier]) { (participants: NSArray?, error: NSError?) -> Void in
                if (participants?.count > 0 && error == nil) {
                    self.addressBarController?.reloadView()
                    // TODO: Need a good way to refresh all the messages for the refreshed participants...
                    self.reloadCellsForMessagesSentByParticipantWithIdentifier(participantIdentifier)
                } else {
                    print("Error querying for users: \(error)")
                }
            }
        }
        return user
    }

    func conversationViewController(conversationViewController: ATLConversationViewController, attributedStringForDisplayOfDate date: NSDate) -> NSAttributedString? {
        let attributes: NSDictionary = [ NSFontAttributeName : UIFont.systemFontOfSize(14), NSForegroundColorAttributeName : UIColor.grayColor() ]
        return NSAttributedString(string: self.dateFormatter.stringFromDate(date), attributes: attributes as? [String : AnyObject])
    }

    func conversationViewController(conversationViewController: ATLConversationViewController, attributedStringForDisplayOfRecipientStatus recipientStatus: [NSObject:AnyObject]) -> NSAttributedString? {
        if (recipientStatus.count == 0) {
            return nil
        }
        let mergedStatuses: NSMutableAttributedString = NSMutableAttributedString()

        let recipientStatusDict = recipientStatus as NSDictionary
        let allKeys = recipientStatusDict.allKeys as NSArray
        allKeys.enumerateObjectsUsingBlock { participant, _, _ in
            let participantAsString = participant as! String
            if (participantAsString == self.layerClient.authenticatedUserID) {
                return
            }

            let checkmark: String = "✔︎"
            var textColor: UIColor = UIColor.lightGrayColor()
            let status: LYRRecipientStatus! = LYRRecipientStatus(rawValue: Int(recipientStatusDict[participantAsString]!.unsignedIntegerValue))
            switch status! {
            case .Sent:
                textColor = UIColor.lightGrayColor()
            case .Delivered:
                textColor = UIColor.orangeColor()
            case .Read:
                textColor = UIColor.greenColor()
            default:
                textColor = UIColor.lightGrayColor()
            }
            let statusString: NSAttributedString = NSAttributedString(string: checkmark, attributes: [NSForegroundColorAttributeName: textColor])
            mergedStatuses.appendAttributedString(statusString)
        }
        return mergedStatuses;
    }

    // MARK - ATLAddressBarViewController Delegate methods methods

    override func addressBarViewController(addressBarViewController: ATLAddressBarViewController, didTapAddContactsButton addContactsButton: UIButton) {
        UserManager.sharedManager.queryForAllUsersWithCompletion { (users: NSArray?, error: NSError?) in
            if error == nil {
                guard let pfusers = users as? [PFUser] else {
                    print("Users is empty")
                    return
                }
                
                let participants = NSSet(array: pfusers) as Set<NSObject>
                let controller = ParticipantTableViewController(participants: participants, sortType: ATLParticipantPickerSortType.FirstName)
                controller.delegate = self
                
                let navigationController = UINavigationController(rootViewController: controller)
                self.navigationController!.presentViewController(navigationController, animated: true, completion: nil)
            } else {
                print("Error querying for All Users: \(error)")
            }
        }
    }

    override func addressBarViewController(addressBarViewController: ATLAddressBarViewController, searchForParticipantsMatchingText searchText: String, completion: (([AnyObject]) -> Void)?) {
        UserManager.sharedManager.queryForUserWithName(searchText) { (participants: NSArray?, error: NSError?) in
            if (error == nil) {
                if let callback = completion {
                    callback(participants! as [AnyObject])
                }
            } else {
                print("Error search for participants: \(error)")
            }
        }
    }

    // MARK - ATLParticipantTableViewController Delegate Methods

    func participantTableViewController(participantTableViewController: ATLParticipantTableViewController, didSelectParticipant participant: ATLParticipant) {
        print("participant: \(participant)")
        self.addressBarController.selectParticipant(participant)
        print("selectedParticipants: \(self.addressBarController.selectedParticipants)")
        self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
    }

    func participantTableViewController(participantTableViewController: ATLParticipantTableViewController, didSearchWithString searchText: String, completion: ((Set<NSObject>!) -> Void)?) {
        UserManager.sharedManager.queryForUserWithName(searchText) { (participants, error) in
            if (error == nil) {
                if let callback = completion {
                    callback(NSSet(array: participants as! [AnyObject]) as Set<NSObject>)
                }
            } else {
                print("Error search for participants: \(error)")
            }
        }
    }

}
