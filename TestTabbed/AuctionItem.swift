//
//  AuctionItem.swift
//  TestTabbed
//
//  Created by David Evans on 7/16/17.
//  Copyright © 2017 David Evans. All rights reserved.
//

import Foundation

class AuctionItem {
    var name: String = ""
    var bid: Int = 0
    var endDate: Date = Date()
    var firstComeFirstServe: Bool = false
    var id: String = ""
    var bidder: String = ""
    var minBid: Int = 0
    var image: String = ""
    var numberOfBids: Int = 0
    var bidderKey: String = ""
    
    // default constructor
    init() {}
    
    // from disctionary
    init(from: NSDictionary) {
        
        name = from["name"] as? String ?? ""
        if let bidStrVal = from["minBid"] as? String {
            minBid = Int(bidStrVal)!
        } else {
            minBid = from["minBid"] as? NSInteger ?? 0
        }
        
        firstComeFirstServe = from["firstComeFirstServe"] as? Bool ?? false

        let endOfAuction = from["endDate"] as? String ?? ""
        if (endOfAuction != "") {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd\'T\'HH:mm:ss.SSSZ"
            endDate = formatter.date(from: endOfAuction)!
        } else {
            endDate = Date()
        }
        image = from["img"] as? String ?? ""
        bid = from["bid"] as? NSInteger ?? 0
        bidder = from["bidder"] as? String ?? ""
        bidderKey = from["bidderKey"] as? String ?? ""
        id = from["id"] as? String ?? ""
        numberOfBids = from["numberOfBids"] as? NSInteger ?? 0
    }
    
    func hasExpired() -> Bool {
        let calendar = NSCalendar.current
        let diff = calendar.dateComponents([.year, .month, .day, .hour, .minute],from:Date(),to:endDate)
        if (diff.minute! < 0 || diff.hour! < 0) { // expired
            return true
        }
        
        if (firstComeFirstServe && bidder != "") {
            return true;
        }
        
        return false
    }
    
    
    
    
    
}
