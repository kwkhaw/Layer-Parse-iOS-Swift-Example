import UIKit

class ViewController: UIViewController, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate {
    var layerClient: LYRClient!
    var logInViewController: PFLogInViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (PFUser.currentUser() != nil) {
            self.loginLayer()
            return
        }
        
        // No user logged in
        let signupButtonBackgroundImage: UIImage = getImageWithColor(ATLBlueColor(), size: CGSize(width: 10.0, height: 10.0))
        
        // Create the log in view controller
        self.logInViewController = PFLogInViewController()
        
        self.logInViewController.logInView!.passwordForgottenButton!.setTitleColor(ATLBlueColor(), forState: UIControlState.Normal)
        self.logInViewController.logInView!.signUpButton!.setBackgroundImage(signupButtonBackgroundImage, forState: UIControlState.Normal)
        self.logInViewController.logInView!.signUpButton!.backgroundColor = ATLBlueColor()
        self.logInViewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.logInViewController.fields = (PFLogInFields.UsernameAndPassword |
                                           PFLogInFields.LogInButton |
                                           PFLogInFields.SignUpButton |
                                           PFLogInFields.PasswordForgotten)
        self.logInViewController.delegate = self
        let logoImageView: UIImageView = UIImageView(image: UIImage(named:"LayerParseLogin"))
        logoImageView.contentMode = UIViewContentMode.ScaleAspectFit
        self.logInViewController.logInView!.logo = logoImageView;
        
        // Create the sign up view controller
        let signUpViewController: PFSignUpViewController = PFSignUpViewController()
        signUpViewController.signUpView!.signUpButton!.setBackgroundImage(signupButtonBackgroundImage, forState: UIControlState.Normal)
        self.logInViewController.signUpController = signUpViewController
        signUpViewController.delegate = self
        let signupImageView: UIImageView = UIImageView(image: UIImage(named:"LayerParseLogin"))
        signupImageView.contentMode = UIViewContentMode.ScaleAspectFit
        signUpViewController.signUpView!.logo = signupImageView

        self.presentViewController(self.logInViewController,  animated: true, completion:nil)
    }

    // MARK - PFLogInViewControllerDelegate

    // Sent to the delegate to determine whether the log in request should be submitted to the server.
    func logInViewController(logInController: PFLogInViewController, shouldBeginLogInWithUsername username:String, password: String) -> Bool {
        if (!username.isEmpty && !password.isEmpty) {
            return true // Begin login process
        }
        
        let title = NSLocalizedString("Missing Information", comment: "")
        let message = NSLocalizedString("Make sure you fill out all of the information!", comment: "")
        let cancelButtonTitle = NSLocalizedString("OK", comment: "")
        UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: cancelButtonTitle).show()
        
        return false // Interrupt login process
    }

    // Sent to the delegate when a PFUser is logged in.
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.loginLayer()
    }

    func logInViewController(logInController: PFLogInViewController, didFailToLogInWithError error: NSError?) {
        if let description = error?.localizedDescription {
            let cancelButtonTitle = NSLocalizedString("OK", comment: "")
            UIAlertView(title: description, message: nil, delegate: nil, cancelButtonTitle: cancelButtonTitle).show()
        }
        println("Failed to log in...")
    }

    // MARK: - PFSignUpViewControllerDelegate

    // Sent to the delegate to determine whether the sign up request should be submitted to the server.
    func signUpViewController(signUpController: PFSignUpViewController, shouldBeginSignUp info: [NSObject : AnyObject]) -> Bool {
        var informationComplete: Bool = true
        
        // loop through all of the submitted data
        for (key, val) in info {
            if let field = info[key] as? String {
                if field.isEmpty {
                    informationComplete = false
                    break
                }
            }
        }
        
        // Display an alert if a field wasn't completed
        if (!informationComplete) {
            let title = NSLocalizedString("Signup Failed", comment: "")
            let message = NSLocalizedString("All fields are required", comment: "")
            let cancelButtonTitle = NSLocalizedString("OK", comment: "")
            UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: cancelButtonTitle).show()
        }
        
        return informationComplete;
    }

    // Sent to the delegate when a PFUser is signed up.
    func signUpViewController(signUpController: PFSignUpViewController, didSignUpUser user: PFUser) {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.loginLayer()
    }

    func signUpViewController(signUpController: PFSignUpViewController, didFailToSignUpWithError error: NSError?) {
        println("Failed to sign up...")
    }

    // MARK - IBActions

    func logOutButtonTapAction(sender: AnyObject) {
        PFUser.logOut()
        self.layerClient.deauthenticateWithCompletion { success, error in
            if (!success) {
                println("Failed to deauthenticate: \(error)")
            } else {
                println("Previous user deauthenticated")
            }
        }
        
        self.presentViewController(self.logInViewController, animated: true, completion: nil)
    }

    // MARK - Layer Authentication Methods

    func loginLayer() {
        SVProgressHUD.show()
            
        // Connect to Layer
        // See "Quick Start - Connect" for more details
        // https://developer.layer.com/docs/quick-start/ios#connect
        self.layerClient.connectWithCompletion { success, error in
            if (!success) {
                println("Failed to connect to Layer: \(error)")
            } else {
                let userID: String = PFUser.currentUser()!.objectId!
                // Once connected, authenticate user.
                // Check Authenticate step for authenticateLayerWithUserID source
                self.authenticateLayerWithUserID(userID, completion: { success, error in
                    if (!success) {
                        println("Failed Authenticating Layer Client with error:\(error)")
                    } else {
                        println("Authenticated")
                        self.presentConversationListViewController()
                    }
                })
            }
        }
    }

    func authenticateLayerWithUserID(userID: NSString, completion: ((success: Bool , error: NSError!) -> Void)!) {
        // Check to see if the layerClient is already authenticated.
        if self.layerClient.authenticatedUserID != nil {
            // If the layerClient is authenticated with the requested userID, complete the authentication process.
            if self.layerClient.authenticatedUserID == userID {
                println("Layer Authenticated as User \(self.layerClient.authenticatedUserID)")
                if completion != nil {
                    completion(success: true, error: nil)
                }
                return
            } else {
                //If the authenticated userID is different, then deauthenticate the current client and re-authenticate with the new userID.
                self.layerClient.deauthenticateWithCompletion { (success: Bool, error: NSError!) in
                    if error != nil {
                        self.authenticationTokenWithUserId(userID, completion: { (success: Bool, error: NSError?) in
                            if (completion != nil) {
                                completion(success: success, error: error)
                            }
                        })
                    } else {
                        if completion != nil {
                            completion(success: true, error: error)
                        }
                    }
                }
            }
        } else {
            // If the layerClient isn't already authenticated, then authenticate.
            self.authenticationTokenWithUserId(userID, completion: { (success: Bool, error: NSError!) in
                if completion != nil {
                    completion(success: success, error: error)
                }
            })
        }
    }
    
    func authenticationTokenWithUserId(userID: NSString, completion:((success: Bool, error: NSError!) -> Void)!) {
        /*
        * 1. Request an authentication Nonce from Layer
        */
        self.layerClient.requestAuthenticationNonceWithCompletion { (nonce: String!, error: NSError!) in
            if (nonce.isEmpty) {
                if (completion != nil) {
                    completion(success: false, error: error)
                }
                return
            }
            
            /*
            * 2. Acquire identity Token from Layer Identity Service
            */
            PFCloud.callFunctionInBackground("generateToken", withParameters: ["nonce": nonce, "userID": userID]) { (object:AnyObject?, error: NSError?) -> Void in
                if error == nil {
                    let identityToken = object as! String
                    self.layerClient.authenticateWithIdentityToken(identityToken) { authenticatedUserID, error in
                        if (!authenticatedUserID.isEmpty) {
                            if (completion != nil) {
                                completion(success: true, error: nil)
                            }
                            println("Layer Authenticated as User: \(authenticatedUserID)")
                        } else {
                            completion(success: false, error: error)
                        }
                    }
                } else {
                    println("Parse Cloud function failed to be called to generate token with error: \(error)")
                }
            }
        }
    }

    // MARK - Present ATLPConversationListController

    func presentConversationListViewController() {
        SVProgressHUD.dismiss()
        
        let controller: ConversationListViewController = ConversationListViewController(layerClient: self.layerClient)
        self.navigationController!.pushViewController(controller, animated: true)
    }
    
    // MARK - Helper function
    func getImageWithColor(color: UIColor, size: CGSize) -> UIImage {
        var rect = CGRectMake(0, 0, size.width, size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        var image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

