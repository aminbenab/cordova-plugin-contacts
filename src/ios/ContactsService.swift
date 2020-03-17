import Contacts
import Foundation

struct ContactModelIOS: Codable {
    var iosType: Bool = true
    var contactModels: [ContactModel]
}

struct ContactModel: Identifiable, Codable {
    var id: Int
    var fullName: String
    var nickName: String
    var phoneNumbers: [String]
    var avatarIconString: String
}

@objc(ContactsService)
class ContactsService : CDVPlugin {
    @objc(search:)
    func search(command: CDVInvokedUrlCommand) -> String {
        let store = CNContactStore()
        let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactMiddleNameKey, CNContactPhoneNumbersKey, CNContactNicknameKey, CNContactThumbnailImageDataKey]
        var fetchedData: [ContactModel] = []
        var i = 0
        var pluginResult: CDVPluginResult
        
        do {
            try store.enumerateContacts(with: CNContactFetchRequest.init(keysToFetch: keysToFetch as [CNKeyDescriptor]), usingBlock: { (contact, cursor) -> Void in
                 var names: [String] = []
                 
                 if !contact.givenName.isEmpty {
                     names.append("\(contact.givenName.unicodeScalars)")
                 }
                 
                 if !contact.middleName.isEmpty {
                     names.append("\(contact.middleName.unicodeScalars)")
                 }
                 
                 if !contact.familyName.isEmpty {
                     names.append("\(contact.familyName.unicodeScalars)")
                 }

                 let fullName = names.joined(separator: " ")
                 
                 var phoneNumbers: [String] = []
                 if !contact.phoneNumbers.isEmpty {
                     contact.phoneNumbers.forEach({
                         phoneNumbers.append($0.value.stringValue)
                     })
                 }
                
                var avatarIconString = ""
                if !(contact.thumbnailImageData?.isEmpty ?? true) {
                                  avatarIconString = contact.thumbnailImageData?.base64EncodedString() ?? ""
                              }
                 
                 let contactModel = ContactModel(id: i, fullName: fullName, nickName: "\(contact.nickname.unicodeScalars)", phoneNumbers: phoneNumbers, avatarIconString: avatarIconString)
                 let jsonData = try! JSONEncoder().encode(contactModel)
                 let jsonString = String(data: jsonData, encoding: .utf8)!
                 
                 fetchedData.append(contactModel)

                i += 1
            } )
        } catch {
            print("something wrong happened")
            pluginResult = CDVPluginResult(
              status: CDVCommandStatus_ERROR
            )
        }
        
        let contactModelIOS = ContactModelIOS(contactModels: fetchedData)
        let jsonData = try! JSONEncoder().encode(contactModelIOS)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        pluginResult = CDVPluginResult(
          status: CDVCommandStatus_OK,
          messageAs: jsonString
        )
        
        self.commandDelegate!.send(
          pluginResult,
          callbackId: command.callbackId
        )
        
        return jsonString
    }
}
