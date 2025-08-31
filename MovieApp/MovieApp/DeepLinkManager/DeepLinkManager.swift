//
//  DeepLinkManager.swift
//  MovieApp
//
//  Created by Sayed on 26/08/25.
//

import Foundation
import UIKit

class DeepLinkManager {
    static let shared = DeepLinkManager()

    private init() {}

    func handle(url: URL, window: UIWindow) {
        if url.scheme == "myapp", url.host == "movie",
           let movieIdString = url.pathComponents.last,
           let movieId = Int(movieIdString) {
            Router.shared.showMovieDetails(movieId: movieId, in: window)
        } else {
            Router.shared.showHome(in: window)
        }
    }
}
