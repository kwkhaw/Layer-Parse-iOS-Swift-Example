import UIKit

class ParticipantTableViewController: ATLParticipantTableViewController {

    // MARK - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let title = NSLocalizedString("Cancel",  comment: "")
        let cancelItem: UIBarButtonItem = UIBarButtonItem(title: title, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("handleCancelTap"))
        self.navigationItem.leftBarButtonItem = cancelItem
    }

    // MARK - Actions

    func handleCancelTap() {
        self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
    }
}
