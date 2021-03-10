//
// Copyright (c) 2019 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Adyen
import Foundation
import PassKit

internal struct PaymentsData {
    static var amount : Payment.Amount = Payment.Amount(value: 0, currencyCode: "EUR")
    static var reference  : String = "Test Order Reference - iOS UIHost"
    static var countryCode : String = "FR"
    static var shopperLocale : String = "fr_FR"
    static var returnUrl: String = "ui-host://"
    static var shopperReference: String = ""
    static var shopperEmail: String = ""
    static var merchantAccount : String = ""
    static var additionalData : [String : Any] = ["allow3DS2": true,"executeThreeD":true]
}

internal struct PaymentsRequest: Request {
    
    internal typealias ResponseType = PaymentsResponse
    
    internal let path = "payments"
    
    internal let data: PaymentComponentData
    
    //internal let paymentData : NSDictionary
    
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let amount: [String: Any] = [
            "currency": PaymentsData.amount.currencyCode,
            "value": PaymentsData.amount.value
        ]
        
        try container.encode(data.paymentMethod.encodable, forKey: .details)
        try container.encode(data.storePaymentMethod, forKey: .storePaymentMethod)
        try container.encode("iOS", forKey: .channel)
        try container.encode(amount, forKey: .amount)
        try container.encode(PaymentsData.reference, forKey: .reference)
        try container.encode(PaymentsData.countryCode, forKey: .countryCode)
        try container.encode(PaymentsData.returnUrl, forKey: .returnUrl)
        try container.encode(PaymentsData.shopperReference, forKey: .shopperReference)
        try container.encode(PaymentsData.shopperEmail, forKey: .shopperEmail)
        try container.encode(PaymentsData.shopperLocale, forKey: .shopperLocale)
        try container.encode(PaymentsData.additionalData, forKey: .additionalData)
    }
    
    private enum CodingKeys: String, CodingKey {
        case details = "paymentMethod"
        case storePaymentMethod
        case amount
        case reference
        case channel
        case countryCode
        case returnUrl
        case shopperReference
        case shopperEmail
        case shopperLocale
        case additionalData
        case merchantAccount
    }
    
}

internal struct PaymentsResponse: Response {
    
    internal let resultCode: ResultCode?
    
    internal let action: Action?
    
    internal let pspReference : String?
    internal let additionalData : [String:Any]?
    internal let merchantReference: String?
    internal let refusalReasonCode: String?
    internal let refusalReason: String?
    internal let errorCode:String?
    internal let type:String?
    internal let errorMessage:String?
    internal var error_code:String?
    internal let message:String?
    internal var validationError : ValidationError?
    internal var customError : CustomError?

    internal struct ValidationError : Error {
        let type : String?
        let errorCode: String?
        let errorMessage: String?
        init(type: String?=nil,errorCode: String?=nil, errorMessage: String?=nil) {
            self.type = type
            self.errorCode = errorCode
            self.errorMessage = errorMessage
        }
    }
    
    internal struct CustomError : Error {
        let errorCode: String?
        let message: String?
        let additionalData: [String:Any]?
        init(errorCode: String?=nil, message: String?=nil, additionalData: [String:Any]?=nil) {
            self.errorCode = errorCode
            self.message = message
            self.additionalData = additionalData
        }
    }
    
    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.resultCode = try container.decodeIfPresent(ResultCode.self, forKey: .resultCode)
        self.action = try container.decodeIfPresent(Action.self, forKey: .action)
        self.pspReference = try container.decodeIfPresent(String.self,forKey: .pspReference)
        self.additionalData = try container.decodeIfPresent([String: Any].self,forKey: .additionalData)
        self.merchantReference = try container.decodeIfPresent(String.self, forKey: .merchantReference)
        self.refusalReasonCode = try container.decodeIfPresent(String.self, forKey: .refusalReasonCode)
        self.refusalReason = try container.decodeIfPresent(String.self, forKey: .refusalReason)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.errorCode = try container.decodeIfPresent(String.self, forKey: .errorCode)
        self.errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.error_code = self.decode_error_code(self.refusalReasonCode)
        if(self.type != nil){
            self.validationError = ValidationError(type:self.type,errorCode:self.errorCode,errorMessage:self.errorMessage)
        }
        if (self.type == nil && self.errorCode != nil && self.message != nil){
            self.customError = CustomError(errorCode: self.errorCode, message: self.message, additionalData: self.additionalData)
        }
    }
    
    internal func decode_error_code(_ refusalCode : String?) -> String?{
        if(refusalCode != nil){
            switch refusalCode {
                case "0" : return "ERROR_GENERAL"
                case "2" : return "ERROR_TRANSACTION_REFUSED"
                case "3" : return "ERROR_REFERRAL"
                case "4" : return "ERROR_ACQUIRER"
                case  "5" : return "ERROR_BLOCKED_CARD"
                case  "6" : return "ERROR_EXPIRED_CARD"
                case  "7" : return "ERROR_INVALID_AMOUNT"
                case  "8" : return "ERROR_INVALID_CARDNUMBER"
                case  "9" : return "ERROR_ISSUER_UNAVAILABLE"
                case  "10" : return "ERROR_BANK_NOT_SUPPORTED"
                case  "11" : return "ERROR_3DSECURE_AUTH_FAILED"
                case  "12" : return "ERROR_NO_ENOUGH_BALANCE"
                case  "14" : return "ERROR_FRAUD_DETECTED"
                case "15" : return "ERROR_CANCELLED"
                case "16" : return "ERROR_CANCELLED"
                case "17" : return "ERROR_INVALID_PIN"
                case "18" : return "ERROR_PIN_RETRY_EXCEEDED"
                case "19" : return "ERROR_UNABLE_VALIDATE_PIN"
                case "20" : return "ERROR_FRAUD_DETECTED"
                case "21" : return "ERROR_SUBMMISSION_ADYEN"
                case "23" : return "ERROR_TRANSACTION_REFUSED"
                case "24" : return "ERROR_CVC_DECLINED"
                case "25" : return "ERROR_RESTRICTED_CARD"
                case "27" : return "ERROR_DO_NOT_HONOR"
                case "28" : return "ERROR_WDRW_AMOUNT_EXCEEDED"
                case "29" : return "ERROR_WDRW_COUNT_EXCEEDED"
                case "31" : return "ERROR_FRAUD_DETECTED"
                case "32" : return "ERROR_AVS_DECLINED"
                case "33" : return "ERROR_CARD_ONLINE_PIN"
                case "34" : return "ERROR_NO_ACCT_ATCHD_CARD"
                case "35" : return "ERROR_NO_ACCT_ATCHD_CARD"
                case "36" : return "ERROR_MOBILE_PIN"
                case "37" : return "ERROR_CONTACTLESS_FALLBACK"
                case "38" : return "ERROR_AUTH_REQUIRED"
                default : return "ERROR_UNKNOWN"
            }
        }
        return nil
    }
    
    private enum CodingKeys: String, CodingKey {
        case resultCode
        case action
        case pspReference
        case additionalData
        case merchantReference
        case refusalReasonCode
        case refusalReason
        case type
        case errorMessage
        case errorCode
        case message
    }
    
}

internal extension PaymentsResponse {
    
    // swiftlint:disable:next explicit_acl
    enum ResultCode: String, Decodable {
        case authorised = "Authorised"
        case refused = "Refused"
        case pending = "Pending"
        case cancelled = "Cancelled"
        case error = "Error"
        case received = "Received"
        case redirectShopper = "RedirectShopper"
        case identifyShopper = "IdentifyShopper"
        case challengeShopper = "ChallengeShopper"
    }
    
    
    
}
