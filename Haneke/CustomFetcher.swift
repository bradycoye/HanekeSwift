//
//  CustomFetcher.swift
//  Pods
//
//  Created by Brady Coye on 5/22/15.
//
//
import Alamofire
import Foundation
import UIKit

public class CustomFetcher<T : DataConvertible> : Fetcher<T> {
    
    let URL : NSURL
    let request : Alamofire.Request
    
    public init(URL : NSURL) {
        self.URL = URL
        self.request = Alamofire.request(Method.GET, self.URL)
        let key =  URL.absoluteString!
        super.init(key: key)
    }
    
    var cancelled = false
    
    // MARK: Fetcher
    
    public override func fetch(failure fail : ((NSError?) -> ()), success succeed : (T.Result) -> ()) {
        self.cancelled = false
        request.response { [weak self] request, response, data, error in
            if let strongSelf = self {
                var data = data as? NSData
                strongSelf.onReceiveData(data, response: response, error: error, failure: fail, success: succeed)
            }
        }
    }
    
    public override func cancelFetch() {
        self.request.cancel()
        self.cancelled = true
    }
    
    // MARK: Private
    
    private func onReceiveData(data : NSData!, response : NSURLResponse!, error : NSError!, failure fail : ((NSError?) -> ()), success succeed : (T.Result) -> ()) {
        
        if cancelled { return }
        
        let URL = self.URL
        
        if let error = error {
            Log.debug("Request \(URL.absoluteString!) failed", error)
            dispatch_async(dispatch_get_main_queue(), { fail(error) })
            return
        }
        
        let value : T.Result? = T.convertFromData(data)
        if value == nil {
            let localizedFormat = NSLocalizedString("Failed to convert value from data at URL %@", comment: "Error description")
            let description = String(format:localizedFormat, URL.absoluteString!)
            self.failWithCode(description, error: error, failure: fail)
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) { succeed(value!) }
        
    }
    
    private func failWithCode(localizedDescription : String, error: NSError, failure fail : ((NSError?) -> ())) {
        Log.debug(localizedDescription, error)
        dispatch_async(dispatch_get_main_queue()) { fail(error) }
    }
}

