import Foundation

extension PFUser: ATLParticipant {

    public var firstName: String {
        return self.username!
    }

    public var lastName: String {
        return "Test"
    }

    public var fullName: String {
        return "\(self.firstName) \(self.lastName)"
    }

    public var participantIdentifier: String {
        return self.objectId!
    }

    public var avatarImageURL: NSURL? {
        return nil
    }

    public var avatarImage: UIImage? {
        return nil
    }

    public var avatarInitials: String {
        let initials = "\(getFirstCharacter(self.firstName))\(getFirstCharacter(self.lastName))"
        return initials.uppercaseString
    }
    
    private func getFirstCharacter(value: String) -> String {
        return (value as NSString).substringToIndex(1)
    }
}