//
//  Router.swift
//  MovieApp
//
//  Created by Sayed on 26/08/25.
//

import Foundation
import UIKit
final class Router {
    static let shared = Router()

    private init() {}

    func showHome(in window: UIWindow) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navController = storyboard.instantiateInitialViewController() as? UINavigationController
        window.rootViewController = navController
    }

    func showMovieDetails(movieId: Int, in window: UIWindow) {
        let navController = UINavigationController()
        let homeVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HomeViewController")
        let detailsVC = MovieDetailsViewController(nibName: "MovieDetailsViewController", bundle: nil)
        detailsVC.selectedMovieId = movieId
        navController.viewControllers = [homeVC, detailsVC]
        window.rootViewController = navController
    }
}
